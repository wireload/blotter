//
//  LayoutPrefController.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 06.09.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SS_PreferencePaneProtocol.h"


@class WLPrefPaneView;


@interface LayoutPrefController : NSObject <SS_PreferencePaneProtocol, NSSplitViewDelegate> {
    IBOutlet WLPrefPaneView *_mainView;
    IBOutlet NSSplitView *_infoWidthSplitView;
    IBOutlet NSSplitView *_allDayHeightSplitView;
    IBOutlet NSSplitView *_dateHeightSplitView;
    IBOutlet NSSplitView *_tasksHeightSplitView;
    IBOutlet NSView *_layoutView;
    NSAffineTransform *_blotterWindowToInfoWidthSplitViewTransform;
    NSAffineTransform *_infoWidthSplitViewToBlotterWindowTransform;
    NSAffineTransform *_blotterWindowToAllDayHeightSplitViewTransform;
    NSAffineTransform *_allDayHeightSplitViewToBlotterWindowTransform;
    NSAffineTransform *_blotterWindowToDateHeightSplitViewTransform;
    NSAffineTransform *_dateHeightSplitViewToBlotterWindowTransform;
    NSAffineTransform *_blotterWindowToTasksHeightSplitViewTransform;
    NSAffineTransform *_tasksHeightSplitViewToBlotterWindowTransform;
    BOOL _splitViewsAreBeenInitializing;
}

- (IBAction)restoreDefaults:(NSButton *)aButton;

- (void)layoutSplitViewWithParameters:(id)aParameters;

- (void)transformsDidChange;

@end
