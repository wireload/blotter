//
//  WLCalendarAllDayEventsLayer.h
//  Blotter
//
//  Created by Ilya Kulakov on 14.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <WLCalendarStore/WLCalendarStore.h>
#import "WLCalendarEventLayer.h"


@class WLCalendarEventLayer;


@interface WLCalendarAllDayEventsLayer : CALayer

@property (nonatomic, copy) NSArray *events;

- (CGFloat)preferredHeightWithWidth:(CGFloat)aWidth;

- (WLCalendarEventLayer *)makeAllDayEventLayer;

@end


@interface WLCalendarEventLayer (WLCalendarAllDayEventsLayer)

@property (nonatomic) NSObject <WLCalEvent> *allDayEvent;

@end
