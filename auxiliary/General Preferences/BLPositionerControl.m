//
//  BLPositionerControl.m
//  General Preferences
//
//  Created by Alexander Ljungberg on 23/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import "BLPositionerControl.h"
#import "BLPositionerControlCell.h"
#import "BLCalendarFramer.h"

@implementation BLPositionerControl

+ (id)cellClass
{
    return [BLPositionerControlCell class];
}

/*- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setCell:[[BLPositionerControlCell alloc] init]];
    }
    return self;
}*/

@end
