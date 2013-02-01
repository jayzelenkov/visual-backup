//
//  ImageBrowserItem.h
//  VisualBackup
//
//  Created by Jevgeni Zelenkov on 30.01.13.
//  Copyright (c) 2013 Jevgeni Zelenkov. All rights reserved.
//

#import <Quartz/Quartz.h>
#import <Foundation/Foundation.h>

@interface ImageBrowserItem : NSObject
{
    NSString *_path;
    NSDate *_createdAt;
    NSArray *_runningApps;
}

- (void)setPath:(NSString *)path;
- (void)setCreatedAt:(NSDate *)createdAt;
- (void)setRunningApps:(NSArray *)runningApps;

@end
