//
//  AppDelegate.h
//  VisualBackup
//
//  Created by Jevgeni Zelenkov on 12/4/12.
//  Copyright (c) 2012 Jevgeni Zelenkov. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSMenu *statusMenu;
@property (strong, nonatomic) NSStatusItem *statusBar;

@end
