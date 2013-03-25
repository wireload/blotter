//
//  NSDateComponents(WLCalendarUnit).m
//  WLFoundation
//
//  Created by Ilya Kulakov on 22.03.13.
//  Copyright 2013 WireLoad. All rights reserved.
//
#import <Foundation/Foundation.h>


/*!
    @brief  Defines methods to set properties of NSDateComponents by using NSCalendarUnit.
*/
@interface NSDateComponents (WLCalendarUnit)

/*!
    @brief  Sets value of the correspoing property to newValue.
 
    @param  newValue New value of receiver's property.
 
    @param  aUnit Calendar unit that defines property of the receiver.
 
    @throws Throws NSInvalidArgumentException if there is no property for aUnit.
*/
- (void)WL_setValue:(NSInteger)newValue forCalendarUnit:(NSCalendarUnit)aUnit;

@end
