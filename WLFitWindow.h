//
//  WLFitWindow.h
//  Blotter
//
//  Created by Ilya Kulakov on 13.02.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WLFitWindow : NSWindow

/*!
    @abstract   Fits currend window withing a given frame according to user settings.
*/

- (void)fitWithinFrame:(NSRect)aFrame;

@end
