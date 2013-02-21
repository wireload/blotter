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
    Indicates whether you can add, edit, and delete items in the calendar.
 */
@property (readonly) BOOL allowsContentModifications;

/*!
    Calendar’s color.
 */
@property (copy, readonly) NSColor *color;

/*!
    A Boolean value indicating whether the calendar’s properties can be edited or deleted.
 */
@property (readonly, getter=isImmutable) BOOL immutable;

/*!
    Calendar’s title.
 */
@property (copy, readonly) NSString *title;

/*!
    Calendar’s type
*/
@property (readonly) WLCalCalendarType type;

/*!
    The entity types this calendar can contain.
 */
@property (readonly) WLCalEntityMask allowedEntityTypes;

/*!
    An unique identifier for the calendar.
 */
@property (readonly) NSString *calendarIdentifier;

@end
