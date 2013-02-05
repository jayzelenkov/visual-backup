//
//  ImageBrowserController.m
//  VisualBackup
//
//  Created by Jevgeni Zelenkov on 12.24.12.
//  Copyright (c) 2012 Jevgeni Zelenkov. All rights reserved.
//

#import "ImageBrowserController.h"
#import "ImageBrowserItem.h"

@implementation ImageBrowserController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)awakeFromNib
{
    // create two arrays : the first one is our datasource representation,
    // the second one are temporary imported images (for thread safeness)
    
    _images = [[NSMutableArray alloc] init];
    _importedImages = [[NSMutableArray alloc] init];


    //allow reordering, animations et set draggind destination delegate
    [_imageBrowser setAllowsReordering:YES];
    [_imageBrowser setAnimates:YES];
    [_imageBrowser setDraggingDestinationDelegate:self];
    
    _runningApps = [NSMutableDictionary dictionaryWithCapacity:0];
    
    NSString *picsDir = [NSHomeDirectory() stringByAppendingPathComponent:  @"Pictures/VisualBackup-Test"];
    NSString *infoPath = [NSString stringWithFormat:@"%@/vbackup-data.txt", picsDir];
    BOOL isFileExists = [[NSFileManager defaultManager] fileExistsAtPath:infoPath];
    if(isFileExists) {
        _runningApps = [NSKeyedUnarchiver unarchiveObjectWithFile:infoPath];
    }

    // load images on load
    [self addImageButtonClicked:nil];
}

- (IBAction)addImageButtonClicked:(id)sender
{
    NSString *picsDir = [NSHomeDirectory() stringByAppendingPathComponent:  @"Pictures/VisualBackup-Test"];
    NSArray *filepaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:picsDir error:nil];
    NSMutableArray *images = [NSMutableArray array];

    [_images removeAllObjects];

    for (id each in filepaths)
    {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@", picsDir, (NSString *)each];
        NSURL *url = [NSURL fileURLWithPath:fullPath];
        if(url != nil)
        {
            [images addObject:url];
        }
    }
    
    NSString *infoPath = [NSString stringWithFormat:@"%@/vbackup-data.txt", picsDir];
    _runningApps = [NSKeyedUnarchiver unarchiveObjectWithFile:infoPath];

    /* launch import in an independent thread */
    [NSThread detachNewThreadSelector:@selector(addImagesWithPaths:) toTarget:self withObject:images];
}


- (NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)browser
{
    return [_images count];
}

- (id)imageBrowser:(IKImageBrowserView *)aBrowser itemAtIndex:(NSUInteger)index
{
    return [_images objectAtIndex:index];
}


/* entry point for reloading image-browser's data and setNeedsDisplay */
- (void)updateDatasource
{
    //-- update our datasource, add recently imported items
    [_images addObjectsFromArray:_importedImages];
	
	//-- empty our temporary array
    [_importedImages removeAllObjects];
    
    //-- reload the image browser and set needs display
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
    
    NSString *appsList = [[[itemObj getRunningApps] valueForKey:@"description"] componentsJoinedByString:@"\n"];
    return appsList;
}

- (void)addAnImageWithPath:(NSString *)path creationDate:(NSDate *)createdAt andRunningApps:(NSArray *)apps
{
    ImageBrowserItem *p;

	/* add a path to our temporary array */
    p = [[ImageBrowserItem alloc] init];
    [p setPath:path];
    [p setCreatedAt:createdAt];
    [p setRunningApps:apps];

    [_importedImages addObject:p];
}

/* performed in an independant thread, parse all paths in "paths" and add these paths in our temporary array */
- (void)addImagesWithPaths:(NSArray *)urls
{
    NSArray *imageTypes = [NSImage imageTypes];
    NSString *resType;
    NSDate *createdAt;

    for (id each in urls)
    {
        NSURL *url = each;
        [url getResourceValue:&resType forKey:NSURLTypeIdentifierKey error:nil];
        if([imageTypes containsObject:resType]) {
            [url getResourceValue:&createdAt forKey:NSURLCreationDateKey error:nil];
            
            NSArray *apps = [_runningApps objectForKey:[url path]];
            [self addAnImageWithPath:[url path] creationDate:createdAt andRunningApps:apps];
        }
    }
    
	/* update the datasource in the main thread */
    [self performSelectorOnMainThread:@selector(updateDatasource) withObject:nil waitUntilDone:YES];
}

typedef struct {
    __unsafe_unretained NSMutableArray* outputArray;
} ArrayApplierData;

- (IBAction)screensaverButtonClicked:(id)sender
{
    CGImageRef screenshot = CGWindowListCreateImage(CGRectInfinite, kCGWindowListOptionOnScreenOnly, kCGNullWindowID, kCGWindowImageDefault);

    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd-HHmmss"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];

    NSString *picsDir = [NSHomeDirectory() stringByAppendingPathComponent:  @"Pictures/VisualBackup-Test"];
    NSString *imgPath = [NSString stringWithFormat:@"%@/vbackup-%@.png", picsDir, dateString];
    CGImageWriteToFile(screenshot, imgPath);
    
    CFArrayRef windowsList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
    NSMutableArray * prunedWindowList = [NSMutableArray array];
	ArrayApplierData data = {prunedWindowList};
    
    CFArrayApplyFunction(windowsList, CFRangeMake(0, CFArrayGetCount(windowsList)), &extractActiveProgramNames, &data);

    if (_runningApps == nil)
        _runningApps = [NSMutableDictionary dictionaryWithCapacity:0];

    [_runningApps setObject:prunedWindowList forKey:imgPath];

    NSString *infoPath = [NSString stringWithFormat:@"%@/vbackup-data.txt", picsDir];
    [NSKeyedArchiver archiveRootObject:_runningApps toFile:infoPath];
    
	CFRelease(windowsList);

    [self addImageButtonClicked:sender];
    CGImageRelease(screenshot);
}

void extractActiveProgramNames(const void *inputDictionary, void *context);
void extractActiveProgramNames(const void *inputDictionary, void *context)
{
    NSDictionary *entry = (__bridge NSDictionary*)inputDictionary;
	ArrayApplierData *data = (ArrayApplierData*)context;

    int sharingState = [[entry objectForKey:(id)kCGWindowSharingState] intValue];
    int level = [[entry objectForKey:(id)kCGWindowLayer] intValue];

	if((sharingState != kCGWindowSharingNone) && (level == 0))
    {
		// Grab the application name, but since it's optional we need to check before we can use it.
		NSString *applicationName = [entry objectForKey:(id)kCGWindowOwnerName];

		if(applicationName != NULL)
		{
            if([data->outputArray containsObject:applicationName] == NO)
            {
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
