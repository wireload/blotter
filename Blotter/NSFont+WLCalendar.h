//
//  WLCalendar.h
//  Blotter
//
//  Created by Илья Кулаков on 11. 8. 25..
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface NSFont (WLCalendar)

+ (NSFont *)WL_columnTitleFont;

+ (NSFont *)WL_columnBoldTitleFont;


+ (NSFont *)WL_dateViewMonthDayFont;

+ (NSFont *)WL_dateViewMonthAndYearFont;

+ (NSFont *)WL_dateViewWeekdayFont;


+ (NSFont *)WL_boxViewTitleFont;


+ (NSFont *)WL_eventTitleFont;

+ (NSFont *)WL_eventLocationFont;


+ (NSFont *)WL_taskFont;


+ (NSFont *)WL_timeRulerMarkerFont;

@end
