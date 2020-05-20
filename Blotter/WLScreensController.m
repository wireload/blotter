//
//  WLScreensController.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 13.02.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <IOKit/graphics/IOGraphicsLib.h>

#import <WLFoundation/WLFoundation.h>

#import "NSUserDefaults+WLApplicationDefaults.h"
#import "WLLogNames.h"
#import "WLScreensController.h"


NSString* const WLScreenDescriptionKeyLocalizedName = @"ScreenName";

NSString* const WLScreenDescriptionKeyUUID = @"ScreenUUID";


@implementation WLScreensController

- (void)awakeFromNib
{
    self.content = [self screenDescriptions];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(screensDidChange:)
                                               name:NSApplicationDidChangeScreenParametersNotification
                                             object:NSApp];
    [NSUserDefaults.standardUserDefaults addObserver:self
                                          forKeyPath:WLScreenUUIDKey
                                             options:NSKeyValueObservingOptionNew
                                             context:NULL];
}

- (void)dealloc
{
    [NSUserDefaults.standardUserDefaults removeObserver:self forKeyPath:WLScreenUUIDKey];
}

#pragma mark Methods

- (NSArray<WLScreenDescription *> *)screenDescriptions
{
    __auto_type screens = NSScreen.screens;
    NSMutableArray *screenObjects = [NSMutableArray arrayWithCapacity:screens.count];

    NSUUID *selectedScreenUUID = NSUserDefaults.standardUserDefaults.WL_screenUUID;
    BOOL foundSelectedScreen = NO;

    for (NSScreen *s in screens)
    {
        __auto_type screenName = [NSString stringWithFormat:NSLocalizedString(@"%@, %@", @"Format of screen name string (localized device name + screen size)"),
                                  s.WL_localizedScreenName, s.WL_localizedScreenSizeString];
        __auto_type screenUUID = s.WL_uuid;

        if ([screenUUID isEqual:selectedScreenUUID])
            foundSelectedScreen = YES;

        [screenObjects addObject:@{
            WLScreenDescriptionKeyLocalizedName: screenName,
            WLScreenDescriptionKeyUUID: screenUUID
        }];
    }

    if (!foundSelectedScreen && selectedScreenUUID)
    {
        [screenObjects insertObject:@{
            WLScreenDescriptionKeyUUID: selectedScreenUUID,
            WLScreenDescriptionKeyLocalizedName: NSLocalizedString(@"Unplugged", @"Name of unplugged monitor")
        } atIndex:0];
    }

    return screenObjects;
}

- (void)screensDidChange:(NSNotification *)aNotification
{
    self.content = [self screenDescriptions];
}

#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath
                      ofObject:(id)anObject
                        change:(NSDictionary *)aChange
                       context:(void *)aContext
{
    if ([aKeyPath isEqualToString:WLScreenUUIDKey])
        [self screensDidChange:nil];
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end


@implementation NSScreen (WLScreensController)

#pragma mark Properties

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_uuid
{
    return [NSSet setWithObject:@"WL_identifier"];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_identifier
{
    return [NSSet setWithObject:@"deviceDescription.NSScreenNumber"];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_localizedScreenName
{
    return [NSSet setWithObject:@"WL_identifier"];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingWL_localizedScreenSizeString
{
    return [NSSet setWithObject:[NSString stringWithFormat:@"deviceDescription.%@", NSDeviceSize]];
}

- (NSUUID *)WL_uuid
{
    CGDirectDisplayID displayID = [self.WL_identifier unsignedIntValue];
    __auto_type displayCFUUID = CFAutorelease(CGDisplayCreateUUIDFromDisplayID(displayID));
    return [[NSUUID alloc] initWithUUIDString:CFBridgingRelease(CFUUIDCreateString(NULL, displayCFUUID))];
}

- (NSNumber *)WL_identifier
{
    return self.deviceDescription[@"NSScreenNumber"];
}

// http://stackoverflow.com/questions/1236498/how-to-get-the-display-name-with-the-display-id-in-mac-os-x/1241627#1241627
- (NSString *)WL_localizedScreenName
{
    NSString *localizedName = nil;

    // NSScreen exposes localized name in 10.15+

    if (@available(macOS 10.15, *))
    {
        localizedName = self.localizedName;

        if (localizedName.length)
            return localizedName;
    }

    CGDirectDisplayID displayID = [self.WL_identifier unsignedIntValue];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // While deperecated, there is no replacement as of macOS 10.15
    NSDictionary *deviceInfo = (NSDictionary *)CFBridgingRelease(IODisplayCreateInfoDictionary(CGDisplayIOServicePort(displayID),
                                                                                               kIODisplayOnlyPreferredName));
#pragma clang diagnostic pop

    NSDictionary *localizedNames = deviceInfo[@(kDisplayProductName)];

    if (localizedNames.count > 0)
        localizedName = [localizedNames[localizedNames.allKeys[0]] copy];

    if (localizedName.length)
        return localizedName;

    [[WLLog logForName:WLLogNameBlotter] logNotice:@"Unable to get name for screen %@", self.deviceDescription];
    return NSLocalizedString(@"Unknown display", @"Placeholder when name of the screen cannot be given");
}

- (NSString *)WL_localizedScreenSizeString
{
    NSSize screenSize = [self.deviceDescription[NSDeviceSize] sizeValue];
    return [NSString stringWithFormat:NSLocalizedString(@"%.0f x %.0f", @"Format of screen size string"),
            screenSize.width, screenSize.height];
}

#pragma mark Methods

+ (nullable NSScreen *)WL_screenWithUUID:(NSUUID *)anUUID
{
    __auto_type screens = self.screens;

    for (NSScreen *s in screens)
    {
        if ([s.WL_uuid isEqual:anUUID])
            return s;
    }

    return nil;
}

+ (nullable NSScreen *)WL_screenWithIdentifier:(NSNumber *)anIdentifier
{
    __auto_type screens = self.screens;

    for (NSScreen *s in screens)
    {
        if ([s.deviceDescription[@"NSScreenNumber"] isEqual:anIdentifier])
            return s;
    }

    return nil;
}

@end
