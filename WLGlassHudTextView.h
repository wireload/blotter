//
//  WLGlassHudTextField.h
//  Blotter
//
//  Created by Ilya Kulakov on 24.03.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class WLGlassHudTextView;

@interface _WLGlassHudTextViewInternal : NSTextView {
    WLGlassHudTextView *containerView;
}
@property (assign) WLGlassHudTextView *containerView;

@end


/*!
    @abstract    Container view for NSTextView.
    @discussion  Coordinates is flipped. Forwards most of received methods to a NSTextView instance.
*/
@interface WLGlassHudTextView : NSView <NSTextViewDelegate> {
    _WLGlassHudTextViewInternal *textView;
    id _textViewFrameObserver;
    BOOL postsSizeChangedNotifications;
}
@property (nonatomic) BOOL postsSizeChangedNotifications;

@end

extern NSString* const WLViewSizeDidChangeNotification;
extern NSString* const WLSizeDiff;
