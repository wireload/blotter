//
//  WLCalendarAllDayEventsLayer.h
//  Blotter
//
//  Created by Ilya Kulakov on 14.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "WLCalendarEventLayer.h"


@class WLCalendarEventLayer;


@interface WLCalendarAllDayEventsLayer : CALayer {
    NSMutableArray *_icalSortedEventLayers;
}

@property (nonatomic, copy) NSArray *events;

- (CGFloat)preferredHeightWithWidth:(CGFloat)aWidth;

@end


@interface WLCalendarEventLayer (WLCalendarAllDayEventsLayer)

+ (WLCalendarEventLayer *)allDayEventLayer;

@property (nonatomic, retain) id allDayEvent;

@end
