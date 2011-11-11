//
//  WLLayoutCalendarWindowView.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 23.09.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <Cocoa/Cocoa.h>


enum
{
    WLLayoutDateViewTag = 1,
    WLLayoutTasksViewTag,
    WLLayoutAllDayViewTag,
    WLLayoutDayViewTag,
    WLLayoutRightNowViewTag,
    WLLayoutInfoSplitViewTag,
    WLLayoutWeekSplitViewTag
};


@interface WLLayoutCalendarWindowView : NSView

@end
