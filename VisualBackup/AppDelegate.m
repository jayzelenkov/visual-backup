//
//  AppDelegate.m
//  VisualBackup
//
//  Created by Jevgeni Zelenkov on 12/4/12.
//  Copyright (c) 2012 Jevgeni Zelenkov. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
}

- (void) awakeFromNib
{
    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    self.statusBar.title = @"VBackup";
    
    // you can also set an image
    //self.statusBar.image =

    self.statusBar.menu = self.statusMenu;
    self.statusBar.highlightMode = YES;
}

-(IBAction)showWindow:(id)sender {
    if(! [_window isVisible] )
        [_window makeKeyAndOrderFront:sender];
}

@end
