//
//  NSScreen+WLAdditions.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 12.02.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <IOKit/graphics/IOGraphicsLib.h>
#import "NSScreen+WLScreenName.h"


@implementation NSScreen (WLScreenName)

// http://stackoverflow.com/questions/1236498/how-to-get-the-display-name-with-the-display-id-in-mac-os-x/1241627#1241627
- (NSString *)WL_localizedScreenName
{
    CGDirectDisplayID displayID = [[[self deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue];
    NSDictionary *deviceInfo = (NSDictionary *)IODisplayCreateInfoDictionary(CGDisplayIOServicePort(displayID), kIODisplayOnlyPreferredName);
    NSDictionary *localizedNames = [deviceInfo objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
    
    NSString *deviceName = nil;
    if ([localizedNames count] > 0) {
        deviceName = [[[localizedNames objectForKey:[[localizedNames allKeys] objectAtIndex:0]] copy] autorelease];
    }
    else {
        deviceName = NSLocalizedString(@"Unknown screen", @"Placeholder when name of the screen cannot be given");
    }
    
    [deviceInfo release];
    return deviceName;
}

- (NSString *)WL_localizedScreenSizeString
{
    NSSize screenSize = [[[self deviceDescription] objectForKey:NSDeviceSize] sizeValue];
    NSString *screenSizeString = [NSString stringWithFormat:NSLocalizedString(@"%.0f x %.0f", @"Format of screen size string"),
                                  screenSize.width, screenSize.height];
    return screenSizeString;
}

@end
