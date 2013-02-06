//
//  ImageBrowserController.h
//  VisualBackup
//
//  Created by Jevgeni Zelenkov on 12.24.12.
//  Copyright (c) 2012 Jevgeni Zelenkov. All rights reserved.
//

#import <Quartz/Quartz.h>
#import <Cocoa/Cocoa.h>

@interface ImageBrowserController : NSWindowController <NSWindowDelegate>
{
    IBOutlet IKImageBrowserView *_imageBrowser;

    NSMutableArray *_images;
    NSMutableArray *_importedImages;
    NSMutableDictionary *_runningApps;
    NSTimer *_screenshotsTaker;
}

- (IBAction)screensaverButtonClicked:(id)sender;

@end
