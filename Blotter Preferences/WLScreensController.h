//
//  WLScreensController.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 13.02.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern NSString* const WLScreenLocalizedName;
extern NSString* const WLScreenID;

/*!
    @discussion  WLScreensController monitors parameters of system's screens and user selected screen.
    When either parameter changes, WLScreensController updates screens content.
*/

@interface WLScreensController : NSObject {
    NSArray *screens;
}
@property (readonly) NSArray *screens;

@end
