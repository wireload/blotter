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
    NSDictionary *deviceDescription = [self deviceDescription];
    CGDirectDisplayID displayID = [[deviceDescription objectForKey:@"NSScreenNumber"] unsignedIntValue];
    NSDictionary *deviceInfo = (NSDictionary *)IODisplayCreateInfoDictionary(CGDisplayIOServicePort(displayID), kIODisplayOnlyPreferredName);
    NSDictionary *localizedNames = [deviceInfo objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
    
    NSString *deviceName = nil;
    if ([localizedNames count] > 0) {
        deviceName = [localizedNames objectForKey:[[localizedNames allKeys] objectAtIndex:0]];
    }
    else {
        deviceName = NSLocalizedString(@"Unknown screen", @"Placeholder when name of the screen cannot be given");
    }
    NSSize screenSize = [[deviceDescription objectForKey:NSDeviceSize] sizeValue];
    NSString *screenName = [NSString stringWithFormat:NSLocalizedString(@"%@, %.0f x %.0f", @"Format of screen name string"),
                            deviceName, screenSize.width, screenSize.height];
    
    [deviceInfo release];
    return screenName;
}

@end
