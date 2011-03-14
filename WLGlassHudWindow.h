//
//  WLGlassHudWindow.h
//  Blotter
//
//  Created by Ilya Kulakov on 07.03.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WLGlassHudWindow : NSWindow {
    NSView *_realContentView;
    id _lastControl;
}


@end
