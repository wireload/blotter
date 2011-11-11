//
//  WLGraphics.m
//  Blotter
//
//  Created by Ilya Kulakov on 10.11.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import "WLGraphics.h"


void WLRecessedBoxShadow(NSRect frame)
{
    static dispatch_once_t onceToken;
    static NSImage *Images[9];
    dispatch_once(&onceToken, ^{
        Images[0] = [NSImage imageNamed:@"recessed-box-shadow-top-left"];
        Images[1] = [NSImage imageNamed:@"recessed-box-shadow-top"];
        Images[2] = [NSImage imageNamed:@"recessed-box-shadow-top-right"];
        Images[3] = [NSImage imageNamed:@"recessed-box-shadow-middle-left"];
        Images[4] = [NSImage imageNamed:@"recessed-box-shadow-middle"];
        Images[5] = [NSImage imageNamed:@"recessed-box-shadow-middle-right"];
        Images[6] = [NSImage imageNamed:@"recessed-box-shadow-bottom-left"];
        Images[7] = [NSImage imageNamed:@"recessed-box-shadow-bottom"];
        Images[8] = [NSImage imageNamed:@"recessed-box-shadow-bottom-right"];
    });

    [NSGraphicsContext saveGraphicsState];
    NSDrawNinePartImage(frame,
                        Images[0],
                        Images[1],
                        Images[2],
                        Images[3],
                        Images[4],
                        Images[5],
                        Images[6],
                        Images[7],
                        Images[8],
                        NSCompositeSourceOver,
                        1.0f,
                        NO);
    [NSGraphicsContext restoreGraphicsState];
}
