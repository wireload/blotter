//
//  WLScreensController.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 13.02.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern NSString* const WLScreenLocalizedName;

extern NSString* const WLScreenIdentifier;

/*!
    @discussion  WLScreensController monitors parameters of system's screens and user selected screen.
    When either parameter changes, WLScreensController updates content.
*/
@interface WLScreensController : NSArrayController

/*!
 @abstract      Returns list of screens currently presented in the system taking care of user selected screen.
 @discussion    If user selected screen is unplugged, returns a dummy dictionary for this screen.
 */
- (NSArray *)screens;

/*!
 @abstract  Updates content of the controller.
 */
- (void)_screensDidChange;

@end


@interface NSScreen (WLScreensController)

/*!
 @see   WLScreenLocalizedName
 @see   WLScreenIdentifier
 */
- (NSDictionary *)WL_dictionary;

/*!
 @see   WLScreenLocalizedName
 */
- (NSString *)WL_localizedScreenName;

/*!
 @see   WLScreenLocalizedName
 */
- (NSString *)WL_localizedScreenSizeString;

@end