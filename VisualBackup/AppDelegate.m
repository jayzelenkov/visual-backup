//
//  AppDelegate.m
//  VisualBackup
//
//  Created by Jevgeni Zelenkov on 12/4/12.
//  Copyright (c) 2012 Jevgeni Zelenkov. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self bringToFront];
}

-(void) awakeFromNib {
    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

    self.statusBar.title = @"VBackup";
    self.statusBar.menu = self.statusMenu;
    self.statusBar.highlightMode = YES;
}

-(IBAction)showWindow:(id)sender {
    if(! [_window isVisible] )
        [_window makeKeyAndOrderFront:sender];

    [self bringToFront];
}

-(void)bringToFront {
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    TransformProcessType(&psn, kProcessTransformToForegroundApplication);
    SetFrontProcess(&psn);
}
@end
