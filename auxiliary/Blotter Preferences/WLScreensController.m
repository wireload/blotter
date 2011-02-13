//
//  WLScreensController.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 13.02.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import "WLScreensController.h"
#import "NSScreen+WLScreenName.h"


NSString* const WLScreenLocalizedName = @"ScreenName";
NSString* const WLScreenID = @"ScreenIdentifier";

@interface WLScreensController (/* Private */)

- (void)_updateScreens;

- (NSArray *)_systemScreens;

@end


@implementation WLScreensController
@synthesize screens;

- (id)init
{
    if (self = [super init])
    {
        NSNumber *selectedScreenID = [[NSUserDefaults standardUserDefaults] objectForKey:WLScreenID];
        NSAssert(selectedScreenID != nil, @"There must be a screenID in UserDefaults");
        screens = [self _systemScreens];
        NSUInteger selectedScreenIndex = [screens indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop)
        {
            return [[obj objectForKey:WLScreenID] isEqualToNumber:selectedScreenID];
        }];

        if (selectedScreenIndex == NSNotFound)
        {
            NSDictionary *unpluggedScreen = [NSDictionary dictionaryWithObjectsAndKeys:
                                             selectedScreenID,                                              WLScreenID,
                                             NSLocalizedString(@"Unplugged", @"Name of unplugged monitor"), WLScreenLocalizedName,
                                             nil];
            screens = [screens arrayByAddingObject:unpluggedScreen];
        }
        [screens retain];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_updateScreens)
                                                     name:NSApplicationDidChangeScreenParametersNotification
                                                   object:nil];
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:WLScreenID
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:WLScreenID];
    [screens release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self _updateScreens];
}


#pragma mark Private

- (void)_updateScreens
{
    NSNumber *selectedScreenID = [[NSUserDefaults standardUserDefaults] objectForKey:WLScreenID];
    NSMutableArray *newScreens = [NSMutableArray arrayWithArray:[self _systemScreens]];
    NSUInteger newScreenIndex = [newScreens indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop)
    {
        return [[obj objectForKey:WLScreenID] isEqualToNumber:selectedScreenID];
    }];

    if (newScreenIndex != NSNotFound)
    {
        [self willChangeValueForKey:@"selectedScreenIndex"];
        [self willChangeValueForKey:@"screens"];
        [screens release];
        screens = [[NSArray alloc] initWithArray:newScreens];
        [self didChangeValueForKey:@"screens"];
        [self didChangeValueForKey:@"selectedScreenIndex"];
    }
    else
    {
        // We should always provide a human-readble string to a user, so we handle such cases when device is unplugged.
        NSDictionary *unpluggedScreen = [NSDictionary dictionaryWithObjectsAndKeys:
                                         selectedScreenID,                                              WLScreenID,
                                         NSLocalizedString(@"Unplugged", @"Name of unplugged monitor"), WLScreenLocalizedName,
                                         nil];
        [newScreens addObject:unpluggedScreen];
        [self willChangeValueForKey:@"selectedScreenIndex"];
        [self willChangeValueForKey:@"screens"];
        [screens release];
        screens = [newScreens copy];
        [self didChangeValueForKey:@"screens"];
        [self didChangeValueForKey:@"selectedScreenIndex"];
    }
}

- (NSArray *)_systemScreens
{
    NSMutableArray *systemScreens = [NSMutableArray array];
    for (NSScreen *screen in [NSScreen screens])
    {
        NSString *screenName = [NSString stringWithFormat:NSLocalizedString(@"%@, %@", @"Format of screen name string (localized device name + screen size)"),
                                [screen WL_localizedScreenName], [screen WL_localizedScreenSizeString]];
        NSDictionary *screenDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                    screenName,                                                     WLScreenLocalizedName,
                                    [[screen deviceDescription] objectForKey:@"NSScreenNumber"],    WLScreenID,
                                    nil];
        [systemScreens addObject:screenDict];
    }
    return systemScreens;
}

@end
