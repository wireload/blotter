//
//  WLLayoutPreferences.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 06.09.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WLFoundation/WLFoundation.h>
#import "WLLayoutSplitView.h"
#import "IKPreferencesRepresentation.h"


@interface WLLayoutPreferences : WLViewController <IKPreferencesRepresentation, WLLayoutSplitViewDelegate>
{
    IBOutlet WLLayoutSplitView *_rootSplitView;
    IBOutlet WLLayoutSplitView *_weekSplitView;
    IBOutlet WLLayoutSplitView *_infoSplitView;
    IBOutlet NSView *_calendarWindowView;
    IBOutlet NSView *_layoutControl;
    NSAffineTransform *_blotterWindowToRootSplitViewTransform;
    NSAffineTransform *_rootSplitViewToBlotterWindowTransform;
    NSAffineTransform *_blotterWindowToWeekSplitViewTransform;
    NSAffineTransform *_weekSplitViewToBlotterWindowTransform;
    NSAffineTransform *_blotterWindowToInfoSplitViewTransform;
    NSAffineTransform *_infoSplitViewToBlotterWindowTransform;
    BOOL _areSplitViewsResizedUsingMouse;
    WLLayoutSplitView *_resizedSplitView;
}

- (NSSize)preferredFrameSizeOfPaneView;


@property (retain) NSAffineTransform *_blotterWindowToRootSplitViewTransform;

@property (retain) NSAffineTransform *_rootSplitViewToBlotterWindowTransform;

@property (retain) NSAffineTransform *_blotterWindowToWeekSplitViewTransform;

@property (retain) NSAffineTransform *_weekSplitViewToBlotterWindowTransform;

@property (retain) NSAffineTransform *_blotterWindowToInfoSplitViewTransform;

@property (retain) NSAffineTransform *_infoSplitViewToBlotterWindowTransform;

/*!
 @abstract  Updates transformers according to current frame size of _mainView. Updates split views.
 */
- (void)_recalculateTransforms;

/*!
 @abstract  Updates preferred size of the _mainView.
 */
- (void)_screenFrameDidChange;

/*!
 @abstract  Adjusts frame of the _calendarWindowView to match new aspect ratio and size.
 @see       _adjustCalendarWindowViewFrame
 */
- (void)_calendarWindowSizeDidChange;

- (void)_layoutFrameDidChange;

- (void)_adjustCalendarWindowViewFrame;

- (void)_layoutSplitViewsWithParameters:(NSDictionary *)aParameters;

- (void)_layoutRootSplitViewWithParameters:(NSDictionary *)aParameters;

- (void)_layoutWeekSplitViewWithParameters:(NSDictionary *)aParameters;

- (void)_layoutInfoSplitViewWithParameters:(NSDictionary *)aParameters;

- (NSDictionary *)_parameters;

- (NSDictionary *)_defaultParameters;

@end
