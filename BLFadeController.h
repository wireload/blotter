//
//  BLFadeController.h
//  Blotter
//
//  Created by Alexander Ljungberg on 23/11/2010.
//  Copyright 2010 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*!
 @abstract      Controls alpha value of a specific view.
 @discussion    Observes system notifications (NSApplicationDidBecomeActiveNotification and
 NSApplicationDidResignActiveNotification).
 */
@interface BLFadeController : NSObject {
    NSTimer *_fadeOutTimer;
    NSView  *fadeView;
}

@property (nonatomic, retain) NSView  *fadeView;

- (id)initWithView:(NSView *)aView;

- (void)fadeIn;


- (void)_fadeOut;

- (void)scheduleFadeOutTimer;

- (void)_applicationDidBecomeActive:(NSNotification *)aNotification;

- (void)_applicationDidResignActive:(NSNotification *)aNotification;

@end
