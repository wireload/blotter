//
//  WLCalendar.h
//  Blotter
//
//  Created by Илья Кулаков on 11. 8. 25..
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface NSFont (WLCalendar)

+ (CTFontRef)WL_columnTitleFont;

+ (CTFontRef)WL_columnBoldTitleFont;


+ (NSFont *)WL_dateViewMonthDayFont;

+ (NSFont *)WL_dateViewMonthAndYearFont;

+ (NSFont *)WL_dateViewWeekdayFont;


+ (NSFont *)WL_infoViewTitleFont;


+ (CTFontRef)WL_eventTitleFont;

+ (CTFontRef)WL_eventLocationFont;

@end
