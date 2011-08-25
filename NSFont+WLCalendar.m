//
//  WLCalendar.m
//  Blotter
//
//  Created by Илья Кулаков on 11. 8. 25..
//  Copyright 2011  WireLoad. All rights reserved.
//

#import "NSFont+WLCalendar.h"


@implementation NSFont (WLCalendar)

+ (CTFontRef)WL_columnTitleFont
{
    return (CTFontRef)[(id)CTFontCreateWithName(CFSTR("Helvetica"), 11.0f, NULL) autorelease];
}

+ (CTFontRef)WL_columnBoldTitleFont
{
    return (CTFontRef)[(id)CTFontCreateWithName(CFSTR("Helvetica BOLD"), 11.0f, NULL) autorelease];
}

@end
