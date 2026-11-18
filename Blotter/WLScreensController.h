//
//  WLScreensController.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 13.02.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <Cocoa/Cocoa.h>


NS_ASSUME_NONNULL_BEGIN

/*!
 Keys for the WLScreenDescription

 @const WLScreenDescriptionKeyLocalizedName Localized screen name as NSString.

 @const WLScreenDescriptionKeyUUID Unique screen identifier as NSUUID.
 */
typedef NSString *WLScreenDescriptionKey NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(ScreenDescriptionKey);
extern WLScreenDescriptionKey const WLScreenDescriptionKeyLocalizedName;
extern WLScreenDescriptionKey const WLScreenDescriptionKeyUUID;

typedef NSDictionary<WLScreenDescriptionKey, id> WLScreenDescription;

/*!
 Exposes the list of currently connected screens via controller's content property.

 @discussion
 Special care is taken for user-selected screen (stored in user defaults): if the selected screen is currently
 disconnected, special "Unplugged" screen takes its place.
*/
@interface WLScreensController : NSArrayController

/*!
 List of descriptions for all currently connected screens + an optional dummy description
 for the unplugged user-selected screen.
 */
- (NSArray<WLScreenDescription *> *)screenDescriptions;

/*!
 Called when configuration of the connected screens changes to update controller's content.

 @see NSApplicationDidChangeScreenParametersNotification
 */
- (void)screensDidChange:(nullable NSNotification *)aNotification;

@end


@interface NSScreen (WLScreensController)

/*!
 Instance of NSScreen with matching UUID.
 */
+ (nullable NSScreen *)WL_screenWithUUID:(NSUUID *)anUUID;

/*!
 Instance of NSScreen with matching identifier.
 */
+ (nullable NSScreen *)WL_screenWithIdentifier:(NSNumber *)anIdentifier;

/*!
 @see CGDisplayCreateUUIDFromDisplayID
 */
@property (readonly, copy) NSUUID *WL_uuid;

/*!
 @see NSScreenNumber
 */
@property (readonly, copy) NSNumber *WL_identifier;

@property (readonly, copy) NSString *WL_localizedScreenName;

@property (readonly, copy) NSString *WL_localizedScreenSizeString;

@end

NS_ASSUME_NONNULL_END
