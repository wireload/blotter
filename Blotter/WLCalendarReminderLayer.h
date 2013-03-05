//
//  WLCalendarReminderLayer.h
//  Blotter
//
//  Created by Ilya Kulakov on 23.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>


/*!
    @brief  Draws representation of a single reminder in WLCalendarReminderView.
 */
@interface WLCalendarReminderLayer : CALayer

/*!
    @brief  Mark (like bullet) used to indent title of the represented reminder.
 */
@property (copy) NSAttributedString *mark;

/*!
    @brief  Title of the represented reminder.
 */
@property (copy) NSAttributedString *title;


/*!
    @brief  Returns height that layer should have to fit all lines when width is constrained by aWidth.
 */
- (CGFloat)preferredHeightWithWidth:(CGFloat)aWidth;

/*!
    @brief  Returns height that layer should have to fit at least one line of title.
 */
- (CGFloat)minimumHumanVisibleHeight;


- (CGRect)_titleFrame;

- (CGRect)_markFrame;

@end


@interface NSAttributedString (WLCalendarReminderLayer)

/*!
    @brief      Returns attributed title of the reminder for drawing.

    @discussion Returns nil if aString is empty.
 */
+ (NSAttributedString *)WL_reminderTitleWithString:(NSString *)aString;

/*!
    @brief      Returns attributed mark of a given color for drawing.

    @discussion Returns nil if aColor is NULL.
 */
+ (NSAttributedString *)WL_reminderMarkWithColor:(CGColorRef)aColor;

@end
