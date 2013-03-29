//
//  WLCalEventPart.h
//  Blotter
//
//  Created by Ilya Kulakov on 19.03.13.
//  Copyright 2013 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WLCalendarStore/WLCalEvent.h>


/*!
    @brief  Represents part of the WLCalEvent object with reference to the original event.
*/
@interface WLCalEventPart : NSObject <WLCalEvent>

/*!
    @brief  Original event.
*/
@property (readonly) NSObject <WLCalEvent> *originalEvent;

/*!
    @brief      Initializes the receiver to be part of anEvent within aDateRange.
 
    @param      anEvent The original event.
 
    @param      aDateRange Date range within event date range.
 
    @throws     NSInvalidArgumentException

    @discussion Designated initializer.
 
                If either parameter is nil or aDateRange lies (partially or completly) outside of anEvent's range.
*/
- (instancetype)initWithCalEvent:(NSObject <WLCalEvent> *)anEvent dateRange:(WLDateRange *)aDateRange;

/*!
    @brief  Splits anEvent into parts aligned by aUnit for aCalendar.
*/
+ (NSArray *)partsBySplittingEvent:(NSObject <WLCalEvent> *)anEvent intoCalendarUnits:(NSCalendarUnit)aUnit calendar:(NSCalendar *)aCalendar;

@end
