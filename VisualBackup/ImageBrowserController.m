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
}





- (IBAction)addImageButtonClicked:(id)sender
{
    // load images here
    
    // [_imageBrowser reloadData];
    
    
    NSArray *urls = openFiles();
    
    if (!urls)
    {
        NSLog(@"No files selected, return...");
        return;
    }
	
	/* launch import in an independent thread */
    [NSThread detachNewThreadSelector:@selector(addImagesWithPaths:) toTarget:self withObject:urls];

}


- (NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)browser
{
    return [_images count];
}

- (id)imageBrowser:(IKImageBrowserView *)aBrowser itemAtIndex:(NSUInteger)index
{
    return [_images objectAtIndex:index];
}






// BLAH!


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

- (void)addAnImageWithPath:(NSString *)path
{
    ImageBrowserItem *p;
    
	/* add a path to our temporary array */
    p = [[ImageBrowserItem alloc] init];
    [p setPath:path];

    [_importedImages addObject:p];
}




- (void)addImagesWithPath:(NSString *)path recursive:(BOOL)recursive
{
    NSInteger i, n;
    BOOL dir;
    
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dir];
    
    if (dir)
    {
        NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
        
        n = [content count];
        
		// parse the directory content
        for (i=0; i<n; i++)
        {
            if (recursive)
                [self addImagesWithPath:[path stringByAppendingPathComponent:[content objectAtIndex:i]] recursive:YES];
            else
                [self addAnImageWithPath:[path stringByAppendingPathComponent:[content objectAtIndex:i]]];
        }
    }
    else
    {
        [self addAnImageWithPath:path];
    }
}

/* performed in an independant thread, parse all paths in "paths" and add these paths in our temporary array */
- (void)addImagesWithPaths:(NSArray *)urls
{
    NSInteger i, n;
        
    n = [urls count];
    for ( i= 0; i < n; i++)
    {
        NSURL *url = [urls objectAtIndex:i];
        [self addImagesWithPath:[url path] recursive:NO];
    }
    
	/* update the datasource in the main thread */
    [self performSelectorOnMainThread:@selector(updateDatasource) withObject:nil waitUntilDone:YES];
    
}






// openFiles is a simple C function that opens an NSOpenPanel and return an array of URLs
static NSArray *openFiles()
{
    NSOpenPanel *panel;
    
    panel = [NSOpenPanel openPanel];
    [panel setFloatingPanel:YES];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:YES];
	NSInteger i = [panel runModal];
	if (i == NSOKButton)
    {
		return [panel URLs];
    }
    
    return nil;
}





@end
