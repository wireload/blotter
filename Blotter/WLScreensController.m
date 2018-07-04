//
//  WLScreensController.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 13.02.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <IOKit/graphics/IOGraphicsLib.h>
#import <WLFoundation/WLFoundation.h>
#import "WLScreensController.h"
#import "NSUserDefaults+WLApplicationDefaults.h"


NSString* const WLScreenLocalizedName = @"ScreenName";


@implementation WLScreensController

- (void)awakeFromNib
{
    self.content = [self screens];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_screensDidChange)
                                                 name:NSApplicationDidChangeScreenParametersNotification
                                               object:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:WLScreenIdentifierKey
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:WLScreenIdentifierKey];
    [super dealloc];
}


#pragma mark Methods

- (NSArray *)screens
{
    NSMutableArray *screens = [NSMutableArray arrayWithArray:[[NSScreen screens] valueForKey:@"WL_dictionary"]];
    NSNumber *selectedScreenID = [[NSUserDefaults standardUserDefaults] WL_screenIdentifier];
    if (selectedScreenID != nil &&
        ![[screens valueForKey:WLScreenIdentifierKey] containsObject:selectedScreenID])
    {
        NSString *screenName = NSLocalizedString(@"Unplugged", @"Name of unplugged monitor");
        NSDictionary *unpluggedScreen = @{WLScreenIdentifierKey: selectedScreenID,
                                                          WLScreenLocalizedName: screenName};
        [screens insertObject:unpluggedScreen atIndex:0];
    }
    return screens;
}

- (void)_screensDidChange
{
    self.content = [self screens];
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
    NSDictionary *screenDict = @{WLScreenLocalizedName: screenName,
                                WLScreenIdentifierKey: self.deviceDescription[@"NSScreenNumber"]};
    return screenDict;
}

// http://stackoverflow.com/questions/1236498/how-to-get-the-display-name-with-the-display-id-in-mac-os-x/1241627#1241627
- (NSString *)WL_localizedScreenName
{
    CGDirectDisplayID displayID = [self.deviceDescription[@"NSScreenNumber"] unsignedIntValue];
    NSDictionary *deviceInfo = (NSDictionary *)IODisplayCreateInfoDictionary(CGDisplayIOServicePort(displayID), kIODisplayOnlyPreferredName);
    NSDictionary *localizedNames = deviceInfo[@kDisplayProductName];

    NSString *deviceName = nil;
    if (localizedNames.count > 0) {
        deviceName = [[localizedNames[localizedNames.allKeys[0]] copy] autorelease];
    }
    else {
        deviceName = NSLocalizedString(@"Unknown screen", @"Placeholder when name of the screen cannot be given");
    }

    [deviceInfo release];
    return deviceName;
}

- (NSString *)WL_localizedScreenSizeString
{
    NSSize screenSize = [self.deviceDescription[NSDeviceSize] sizeValue];
    NSString *screenSizeString = [NSString stringWithFormat:NSLocalizedString(@"%.0f x %.0f", @"Format of screen size string"),
                                  screenSize.width, screenSize.height];
    return screenSizeString;
}

@end
