//
//  WLPrefPaneView.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 20.10.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WLPrefPaneView : NSView {
    NSSize preferredFrameSize;
    BOOL postsPreferredFrameSizeDidChangeNotification;
}

/*!
 @discussion    Default value is NO.
 */
@property BOOL postsPreferredFrameSizeDidChangeNotification;

@property (nonatomic) NSSize preferredFrameSize;

@end


extern NSString* const WLViewPreferredFrameSizeDidChangeNotification;