//
//  SearchResultsController.h
//  VisualBackup
//
//  Created by Jevgeni Zelenkov on 06.02.13.
//  Copyright (c) 2013 Jevgeni Zelenkov. All rights reserved.
//

#import <Quartz/Quartz.h>
#import <Cocoa/Cocoa.h>
#import "ImageBrowserController.h"

@interface SearchResultsController : NSObject <NSControlTextEditingDelegate>
{
    NSMutableArray *allKeywords;

    IBOutlet ImageBrowserController *imageBrowserController;
    IBOutlet NSScrollView *_imageBrowserScroller;
    IBOutlet IKImageBrowserView *_imageBrowser;

    IBOutlet NSScrollView *_searchResultsBrowserScroller;
    IBOutlet IKImageBrowserView *_searchResultsBrowser;
    
    IBOutlet NSButton *toggle;
    IBOutlet NSSearchField *searchField;
    
    BOOL completePosting;
    BOOL commandHandling;
}

@property NSArray *foundImages;
-(IBAction)toggleButtonClicked:(id)sender;

@end
