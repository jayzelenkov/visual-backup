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
    
    // load images on load
    [self addImageButtonClicked:nil];
}

- (IBAction)addImageButtonClicked:(id)sender
{
    NSString *picsDir = [NSHomeDirectory() stringByAppendingPathComponent:  @"Pictures/VisualBackup-Test"];
    NSArray *filepaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:picsDir error:nil];
    NSMutableArray *images = [NSMutableArray arrayWithCapacity: 0];

    NSInteger i, n;
    n = [filepaths count];

    [_images removeAllObjects];

    for ( i= 0; i < n; i++)
    {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@", picsDir, [filepaths objectAtIndex:i]];
        NSURL *url = [NSURL fileURLWithPath:fullPath];
        if(url != nil)
        {
            [images addObject:url];
        }
    }

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
}

- (void)addAnImageWithPath:(NSString *)path andCreationDate:(NSDate *)createdAt
{
    ImageBrowserItem *p;

	/* add a path to our temporary array */
    p = [[ImageBrowserItem alloc] init];
    [p setPath:path];
    [p setCreatedAt:createdAt];

    [_importedImages addObject:p];
}

/* performed in an independant thread, parse all paths in "paths" and add these paths in our temporary array */
- (void)addImagesWithPaths:(NSArray *)urls
{
    NSArray *imageTypes = [NSImage imageTypes];
    NSString *resType;
    NSDate *createdAt;

    NSInteger i, n;

    n = [urls count];
    for ( i= 0; i < n; i++)
    {
        NSURL *url = [urls objectAtIndex:i];
        [url getResourceValue:&resType forKey:NSURLTypeIdentifierKey error:nil];
        if([imageTypes containsObject:resType]) {
            [url getResourceValue:&createdAt forKey:NSURLCreationDateKey error:nil];
            [self addAnImageWithPath:[url path] andCreationDate:createdAt];
        }
    }
    
	/* update the datasource in the main thread */
    [self performSelectorOnMainThread:@selector(updateDatasource) withObject:nil waitUntilDone:YES];
}


- (IBAction)screensaverButtonClicked:(id)sender
{
    
    [self interrogateHardware];

    if(displays == nil)
    {
        NSLog(@"DisplayID pointer is nil!\n");
        return;
    }

    CGImageRef screenshot = CGDisplayCreateImage(displays[0]);
    
    if(screenshot == nil)
    {
        NSLog(@"no screenshot! Shit!");
    }
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd-HHmmss"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    NSLog(@"%@",dateString);

    NSString *picsDir = [NSHomeDirectory() stringByAppendingPathComponent:  @"Pictures/VisualBackup-Test"];
    NSString *fullPath = [NSString stringWithFormat:@"%@/vbackup-%@.png", picsDir, dateString];
    CGImageWriteToFile(screenshot, fullPath);

    [self addImageButtonClicked:sender];
}

-(void) interrogateHardware
{
    CGError				err = CGDisplayNoErr;
	CGDisplayCount		dspCount = 0;
    
    /* How many active displays do we have? */
    err = CGGetActiveDisplayList(0, NULL, &dspCount);
    
	/* If we are getting an error here then their won't be much to display. */
    if(err != CGDisplayNoErr)
    {
        return;
    }

	/* Maybe this isn't the first time though this function. */
	if(displays != nil)
    {
		free(displays);
    }

	/* Allocate enough memory to hold all the display IDs we have. */
    displays = calloc((size_t)dspCount, sizeof(CGDirectDisplayID));
    
	// Get the list of active displays
    err = CGGetActiveDisplayList(dspCount,
                                 displays,
                                 &dspCount);
	
	/* More error-checking here. */
    if(err != CGDisplayNoErr)
    {
        NSLog(@"Could not get active display list (%d)\n", err);
        return;
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
