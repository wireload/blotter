//
//  WLViewController.m
//  Blotter
//
//  Created by Ilya Kulakov on 10.12.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import "WLViewController.h"


@interface WLViewController (/* Private */)

@property (readwrite) BOOL isViewLoaded;

@end


@implementation WLViewController

# pragma mark NSViewController

- (void)setView:(NSView *)newView
{
    BOOL changeIsViewLoaded = (!self.isViewLoaded && newView != nil) || (self.isViewLoaded && newView == nil);
    
    if (changeIsViewLoaded)
        [self willChangeValueForKey:@"isViewLoaded"];

    self.isViewLoaded = newView != nil;
    super.view = newView;

    if (changeIsViewLoaded)
        [self didChangeValueForKey:@"isViewLoaded"];
}

# pragma mark NSObject

+ (BOOL)automaticallyNotifiesObserversOfIsViewLoaded
{
    return NO;
}

@end
