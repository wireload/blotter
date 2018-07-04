//
//  WLAppDelegate.m
//  LoginItem
//
//  Created by Ilya Kulakov on 18.03.13.
//  Copyright (c) 2013 Wireload. All rights reserved.
//

#import "WLAppDelegate.h"

@implementation WLAppDelegate

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
