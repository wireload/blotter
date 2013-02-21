//
//  WLApplicationPreferences.m
//  Blotter
//
//  Created by Ilya Kulakov on 07.02.13.
//  Copyright (c) 2013 WireLoad. All rights reserved.
//

#import "WLApplicationPreferences.h"


@implementation WLApplicationPreferences

#pragma mark NSWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    self.window.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces;
    self.window.level = NSFloatingWindowLevel;
}

- (void)showWindow:(id)aSender
{
    if (!self.window.isVisible)
        [self.window center];

    [super showWindow:aSender];
}

@end
