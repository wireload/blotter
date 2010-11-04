//
//  NSColor-Utilities.m
//  Deskboard
//
//  Created by Alexander Ljungberg on 04/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import "NSColor-Utilities.h"


@implementation NSColor (Utilities)

- (NSString *)hexString
{
    CGFloat red, green, blue;
    [[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&red green:&green blue:&blue alpha:nil];

    return [NSString stringWithFormat: @"%X%X%X", (unsigned)(red*255), (unsigned)(green*255), (unsigned)(blue*255)];
}

@end
