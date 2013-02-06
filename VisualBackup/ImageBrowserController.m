//
//  ImageBrowserController.m
//  VisualBackup
//
//  Created by Jevgeni Zelenkov on 12.24.12.
//  Copyright (c) 2012 Jevgeni Zelenkov. All rights reserved.
//

#import "ImageBrowserController.h"
#import "ImageBrowserItem.h"
#import <ApplicationServices/ApplicationServices.h>

@implementation ImageBrowserController

- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        picsDir = [NSHomeDirectory() stringByAppendingPathComponent:  @"Pictures/VisualBackup-Test"];
    }
    return self;
}

- (void)windowWillClose:(NSNotification *)notification {
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    TransformProcessType(&psn, kProcessTransformToUIElementApplication);
}

NSString *kInfoFileName = @"vbackup-data.txt";

- (void)awakeFromNib {
    _images = [[NSMutableArray alloc] init];
    _importedImages = [[NSMutableArray alloc] init];

    [_imageBrowser setAllowsReordering:YES];
    [_imageBrowser setAnimates:YES];
    [_imageBrowser setDraggingDestinationDelegate:self];
    [self reloadScreenshotsFromDefaultStore];

    _screenshotsTaker = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(screensaverButtonClicked:) userInfo:self repeats:YES];
}

- (void)loadRunningAppsInfoData {
    _runningApps = [NSMutableDictionary dictionaryWithCapacity:0];
    NSString *infoPath = [NSString stringWithFormat:@"%@/%@", picsDir, kInfoFileName];
    BOOL isFileExists = [[NSFileManager defaultManager] fileExistsAtPath:infoPath];
    if(isFileExists) {
        _runningApps = [NSKeyedUnarchiver unarchiveObjectWithFile:infoPath];
    }
}

- (void)reloadScreenshotsFromDefaultStore {
    NSArray *filepaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:picsDir error:nil];
    NSMutableArray *images = [NSMutableArray array];

    [_images removeAllObjects];

    for (id each in filepaths) {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@", picsDir, (NSString *)each];
        NSURL *url = [NSURL fileURLWithPath:fullPath];
        if(url != nil) {
            [images addObject:url];
        }
    }

    [self loadRunningAppsInfoData];

    /* launch import in an independent thread */
    [NSThread detachNewThreadSelector:@selector(addImagesWithPaths:) toTarget:self withObject:images];
}


- (NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)browser {
    return [_images count];
}

- (id)imageBrowser:(IKImageBrowserView *)aBrowser itemAtIndex:(NSUInteger)index {
    return [_images objectAtIndex:index];
}


- (void)updateDatasource {
    [_images addObjectsFromArray:_importedImages];
    [_importedImages removeAllObjects];
    [_imageBrowser reloadData];

    [_imageBrowser removeAllToolTips];
    for (int i=0; i<[_images count]; i++) {
        NSRect rect = [_imageBrowser itemFrameAtIndex:i];
        ImageBrowserItem *itemObj = [_images objectAtIndex:i];
        [_imageBrowser addToolTipRect:rect owner:self userData:(__bridge void *)(itemObj)];
    }
}

- (NSString*)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)data {
    ImageBrowserItem *itemObj = (__bridge ImageBrowserItem *)data;

    NSString *appsList = [[itemObj.runningApps valueForKey:@"description"] componentsJoinedByString:@"\n"];
    return appsList;
}

- (void)addAnImageWithPath:(NSString *)path creationDate:(NSDate *)createdAt andRunningApps:(NSArray *)apps {
    ImageBrowserItem *p;

    p = [[ImageBrowserItem alloc] init];
    p.path = path;
    p.createdAt = createdAt;
    p.runningApps = apps;

    [_importedImages addObject:p];
}

/* performed in an independant thread, parse all paths in "paths" and add these paths in our temporary array */
- (void)addImagesWithPaths:(NSArray *)urls {
    NSArray *imageTypes = [NSImage imageTypes];
    NSString *resType;
    NSDate *createdAt;

    for (id each in urls) {
        NSURL *url = each;
        [url getResourceValue:&resType forKey:NSURLTypeIdentifierKey error:nil];
        if([imageTypes containsObject:resType]) {
            NSArray *apps = [_runningApps objectForKey:[url path]];
            [url getResourceValue:&createdAt forKey:NSURLCreationDateKey error:nil];
            [self addAnImageWithPath:[url path] creationDate:createdAt andRunningApps:apps];
        }
    }

	/* update the datasource in the main thread */
    [self performSelectorOnMainThread:@selector(updateDatasource) withObject:nil waitUntilDone:YES];
}

typedef struct {
    __unsafe_unretained NSMutableArray* outputArray;
} ArrayApplierData;

- (IBAction)screensaverButtonClicked:(id)sender {
    CGImageRef screenshot = CGWindowListCreateImage(CGRectInfinite, kCGWindowListOptionOnScreenOnly, kCGNullWindowID, kCGWindowImageDefault);

    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd-HHmmss"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];

    NSString *imgPath = [NSString stringWithFormat:@"%@/vbackup-%@.png", picsDir, dateString];
    CGImageWriteToFile(screenshot, imgPath);

    CFArrayRef windowsList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
    NSMutableArray * prunedWindowList = [NSMutableArray array];
	ArrayApplierData data = {prunedWindowList};

    CFArrayApplyFunction(windowsList, CFRangeMake(0, CFArrayGetCount(windowsList)), &extractActiveProgramNames, &data);

    [_runningApps setObject:prunedWindowList forKey:imgPath];

    NSString *infoPath = [NSString stringWithFormat:@"%@/%@", picsDir, kInfoFileName];
    [NSKeyedArchiver archiveRootObject:_runningApps toFile:infoPath];

	CFRelease(windowsList);

    [self reloadScreenshotsFromDefaultStore];
    CGImageRelease(screenshot);
}

void extractActiveProgramNames(const void *inputDictionary, void *context) {
    NSDictionary *entry = (__bridge NSDictionary*)inputDictionary;
	ArrayApplierData *data = (ArrayApplierData*)context;

    int sharingState = [[entry objectForKey:(id)kCGWindowSharingState] intValue];
    int level = [[entry objectForKey:(id)kCGWindowLayer] intValue];

	if((sharingState != kCGWindowSharingNone) && (level == 0)) {
		// Grab the application name, but since it's optional we need to check before we can use it.
		NSString *applicationName = [entry objectForKey:(id)kCGWindowOwnerName];

		if(applicationName != NULL) {
            if([data->outputArray containsObject:applicationName] == NO) {
                [data->outputArray addObject:applicationName];
            }
		}
	}
}

void CGImageWriteToFile(CGImageRef image, NSString *path) {
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];
    CGImageDestinationRef dest = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, nil);
    CGImageDestinationAddImage(dest, image, NULL);

    if (!CGImageDestinationFinalize(dest)) {
        NSLog(@"Failed to write image to %@", path);
    }

    CFRelease(dest);
}

@end
