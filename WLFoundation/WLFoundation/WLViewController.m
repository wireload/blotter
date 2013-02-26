//
//  WLViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 10.12.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "WLViewController.h"


@implementation WLViewController

- (void)setView:(NSView *)newView
{
    BOOL changeIsViewLoaded = (!self.isViewLoaded && newView != nil) || (self.isViewLoaded && newView == nil);
    
    if (changeIsViewLoaded)
        [self willChangeValueForKey:@"isViewLoaded"];

    _isViewLoaded = newView != nil;
    [super setView:newView];

    if (changeIsViewLoaded)
        [self didChangeValueForKey:@"isViewLoaded"];
}

@end
