//
//  WLPrefPaneView.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 20.10.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import "WLPrefPaneView.h"


NSString* const WLViewPreferredFrameSizeDidChangeNotification = @"WLViewPreferredSizeDidChangeNotification";


@implementation WLPrefPaneView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


#pragma mark Properties
@synthesize postsPreferredFrameSizeDidChangeNotification;
@synthesize preferredFrameSize;

- (void)setPreferredFrameSize:(NSSize)newPreferredSize
{
    if (!NSEqualSizes(preferredFrameSize, newPreferredSize))
    {
        preferredFrameSize = newPreferredSize;
        if (self.postsPreferredFrameSizeDidChangeNotification)
            [[NSNotificationCenter defaultCenter] postNotificationName:WLViewPreferredFrameSizeDidChangeNotification object:self];
    }
}

@end
