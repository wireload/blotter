//
//  LayoutPrefController.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 06.09.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SS_PreferencePaneProtocol.h"


@interface LayoutPrefController : NSObject<SS_PreferencePaneProtocol, NSSplitViewDelegate> {
    IBOutlet NSView *_mainView;
    IBOutlet NSSplitView *_mainSplitView;
    IBOutlet NSSplitView *_weekSplitView;
    IBOutlet NSSplitView *_infoSplitView;
    IBOutlet NSSplitView *_tasksAndRightNowSplitView;
    BOOL _isViewLoaded;
}

- (IBAction)restoreDefaults:(NSButton *)aButton;

- (void)layoutSplitViewWithParameters:(id)aParameters;

@end
