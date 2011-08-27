//
//  NSColor+WLCalendar.h
//  Blotter
//
//  Created by Ilya Kulakov on 20.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSColor (WLCalendar)

+ (NSColor *)WL_weekendColor;

+ (NSColor *)WL_columnColor;

+ (NSColor *)WL_tasksColor;

+ (NSColor *)WL_tasksShadowColor;

+ (NSColor *)WL_dateShadowColor;

+ (NSColor *)WL_timelineShadowColor;

+ (NSColor *)WL_columnTitleShadowColor;

+ (NSColor *)WL_eventShadowColor;


+ (NSColor *)WL_dateViewBackgroundColor;

+ (NSColor *)WL_dateViewTextColor;


+ (NSColor *)WL_infoViewTitleColor;

@end
