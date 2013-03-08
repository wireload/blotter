//
//  WLCalCalendar
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 12.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WLCalendarStore/WLCalObject.h>
#import <WLCalendarStore/WLCalTypes.h>


@protocol WLCalCalendar <WLCalObject>

/*!
    @brief  Indicates whether you can add, edit, and delete items in the calendar.
 */
@property (readonly) BOOL allowsContentModifications;

/*!
    @brief      Calendar’s color.

    @discussion MUST be non nil.
 */
@property (readonly) NSColor *color;

/*!
    @brief  A Boolean value indicating whether the calendar’s properties can be edited or deleted.
 */
@property (readonly, getter=isImmutable) BOOL immutable;

/*!
    @brief      Calendar’s title.

    @discussion MUST be non nil.
 */
@property (readonly) NSString *title;

/*!
    @brief  Calendar’s type
*/
@property (readonly) WLCalCalendarType type;

/*!
    @brief  The entity types this calendar can contain.
 */
@property (readonly) WLCalEntityMask allowedEntityTypes;

/*!
    @brief      An unique identifier for the calendar.

    @discussion MUST be non empty string.
 */
@property (readonly) NSString *calendarIdentifier;

@end
