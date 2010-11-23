//
//  BLFadeController.h
//  Blotter
//
//  Created by Alexander Ljungberg on 23/11/2010.
//  Copyright 2010 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BLFadeController : NSObject {
    NSTimer *fadeOutTimer;
    NSView  *fadeView;
}

@property (retain) NSView  *fadeView;

- (id)initWithView:(NSView *)aView;

@end
