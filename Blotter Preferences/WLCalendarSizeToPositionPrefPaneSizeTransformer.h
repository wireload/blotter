//
//  WLCalendarSizeToPositionPrefPaneSizeTransformer.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 19.10.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <Foundation/Foundation.h>


/*!
 @abstract      Transforms BLSize value into frame for the position pref pane.
 @discussion    Since default size may be different for different localizationt, you must provide the default size.
 @see           BLSize
 */
@interface WLCalendarSizeToPositionPrefPaneSizeTransformer : NSValueTransformer {
    NSSize defaultSize;
}

- (id)initWithDefaultSize:(NSSize)aDefaultSize;

@property (readonly) NSSize defaultSize;

@end
