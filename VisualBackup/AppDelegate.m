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

}

-(void) awakeFromNib {
    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

    self.statusBar.title = @"vb";
    self.statusBar.menu = self.statusMenu;
    self.statusBar.highlightMode = YES;
}

-(IBAction)showWindow:(id)sender {
    [self bringToFront];

    if(! [_window isVisible] )
        [_window makeKeyAndOrderFront:sender];
}

-(void)bringToFront {
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    TransformProcessType(&psn, kProcessTransformToForegroundApplication);
    SetFrontProcess(&psn);
}
@end
