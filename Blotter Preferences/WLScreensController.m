//
//  WLScreensController.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 13.02.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <IOKit/graphics/IOGraphicsLib.h>
#import "WLScreensController.h"


NSString* const WLScreenLocalizedName = @"ScreenName";

NSString* const WLScreenIdentifier = @"ScreenIdentifier";


@implementation WLScreensController

- (void)awakeFromNib
{
    [self setContent:[self screens]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_screensDidChange)
                                                 name:NSApplicationDidChangeScreenParametersNotification
                                               object:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:WLScreenIdentifier
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:WLScreenIdentifier];
    [super dealloc];
}


#pragma mark Methods

- (NSArray *)screens
{
    NSMutableArray *screens = [NSMutableArray arrayWithArray:[[NSScreen screens] valueForKey:@"WL_dictionary"]];
    NSNumber *selectedScreenID = [[NSUserDefaults standardUserDefaults] objectForKey:WLScreenIdentifier];
    if (selectedScreenID != nil &&
        ![[screens valueForKey:WLScreenIdentifier] containsObject:selectedScreenID])
    {
        NSString *screenName = NSLocalizedStringFromTableInBundle(@"Unplugged", nil, [NSBundle bundleForClass:[self class]], @"Name of unplugged monitor");
        NSDictionary *unpluggedScreen = [NSDictionary dictionaryWithObjectsAndKeys:
                                                          selectedScreenID,   WLScreenIdentifier,
                                                          screenName,         WLScreenLocalizedName,
                                                          nil];
        [screens insertObject:unpluggedScreen atIndex:0];
    }
    return screens;
}

- (void)_screensDidChange
{
    [self setContent:[self screens]];
}


#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self _screensDidChange];
}

@end


@implementation NSScreen (WLScreensController)

- (NSDictionary *)WL_dictionary
{
    NSString *screenName = [NSString stringWithFormat:NSLocalizedString(@"%@, %@", @"Format of screen name string (localized device name + screen size)"),
                            [self WL_localizedScreenName], [self WL_localizedScreenSizeString]];
    NSDictionary *screenDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                screenName,                                                     WLScreenLocalizedName,
                                [[self deviceDescription] objectForKey:@"NSScreenNumber"],      WLScreenIdentifier,
                                nil];
    return screenDict;
}

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
