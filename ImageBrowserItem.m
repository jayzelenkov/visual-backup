//
//  ImageBrowserItem.m
//  VisualBackup
//
//  Created by Jevgeni Zelenkov on 30.01.13.
//  Copyright (c) 2013 Jevgeni Zelenkov. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "ImageBrowserItem.h"

@implementation ImageBrowserItem : NSObject


- (NSString *) imageRepresentationType
{
    return IKImageBrowserPathRepresentationType;
}

- (id) imageRepresentation
{
    return _path;
}

- (NSString *) imageUID
{
    return _path;
}

- (void)setPath:(NSString *)path
{
    if(_path != path)
    {
        _path = path;
    }
}

- (void)setCreatedAt:(NSDate *)createdAt
{
    _createdAt = createdAt;
}

- (void)setRunningApps:(NSArray *)runningApps
{
    if(_runningApps != nil) {
        _runningApps = nil;
    }
    
    _runningApps = [NSArray arrayWithArray:runningApps];
}

@end
