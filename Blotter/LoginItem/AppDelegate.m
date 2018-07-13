//
//  AppDelegate.m
//  LoginItem
//
//  Created by Ilya Kulakov on 7/12/18.
//  Copyright © 2018 WireLoad. All rights reserved.
//

#import "AppDelegate.h"


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSArray *runningApps = [NSWorkspace sharedWorkspace].runningApplications;
    BOOL isRunning = [runningApps indexOfObjectWithOptions:NSEnumerationConcurrent
                                               passingTest:^BOOL(NSRunningApplication *anApp, NSUInteger idx, BOOL *stop)
                      {
                          return [anApp.bundleIdentifier isEqualToString:@"net.wireload.blotter.mac"];

                      }] != NSNotFound;

    if (!isRunning) {
        NSString *path = [NSBundle mainBundle].bundlePath;
        NSArray *p = path.pathComponents;
        NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:p];
        [pathComponents removeLastObject];
        [pathComponents removeLastObject];
        [pathComponents removeLastObject];
        [pathComponents addObject:@"MacOS"];
        [pathComponents addObject:@"Blotter"];
        NSString *newPath = [NSString pathWithComponents:pathComponents];
        [[NSWorkspace sharedWorkspace] launchApplication:newPath];
    }
    [NSApp terminate:nil];
}

@end
