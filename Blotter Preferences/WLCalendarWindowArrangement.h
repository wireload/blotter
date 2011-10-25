//
//  WLCalendarWindowPositionControl.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 07.01.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "WLCalendarWindowController.h"


enum {
    WLCalendarWindowPositioningArrangement = 1 << 0,
    WLCalendarWindowResizingArrangement = 1 << 1
};


typedef enum {
    WLCalendarWindowTopLeftEdge,
    WLCalendarWindowTopCenterEdge,
    WLCalendarWindowTopRightEdge,
    WLCalendarWindowCenterLeftEdge,
    WLCalendarWindowCenterRightEdge,
    WLCalendarWindowBottomLeftEdge,
    WLCalendarWindowBottomCenterEdge,
    WLCalendarWindowBottomRightEdge
} WLCalendarWindowEdge;


@protocol WLCalendarWindowArrangementDelegate;


@interface WLCalendarWindowArrangement : NSView /*<CALayerDelegate, CALayoutManager>*/ {
    NSInteger arrangementMode;
    IBOutlet NSObject<WLCalendarWindowArrangementDelegate> *delegate;

    CALayer *_imageLayer;
    CALayer *_navigationLayer;
    CALayer *_calendarWindowLayer;
    NSTrackingArea *_navigationHelperAreas[9];
    CALayer *_navigationHelperLayers[9];
    BOOL _isPositioning;
    BOOL _isResizing;
    WLCalendarWindowEdge _resizedEdge;
    NSPoint _startPoint;
}

@property (nonatomic, copy) NSImage *backgroundImage;

@property (nonatomic) NSInteger arrangementMode;

@property (nonatomic) NSSize edgeSize;

@property (assign) NSObject<WLCalendarWindowArrangementDelegate> *delegate;

- (void)startPositioningAtPoint:(NSPoint)aPoint;

- (void)continuePositioningAtPoint:(NSPoint)aPoint startPoint:(NSPoint)aLastPoint;

- (void)stopPositioningAtPoint:(NSPoint)aPoint;

- (void)startResizingAtPoint:(NSPoint)aPoint edge:(WLCalendarWindowEdge)anEdge;

- (void)continueResizingAtPoint:(NSPoint)aPoint startPoint:(NSPoint)aLastPoint edge:(WLCalendarWindowEdge)anEdge;

- (void)stopResizingAtPoint:(NSPoint)aPoint edge:(WLCalendarWindowEdge)anEdge;

- (NSRect)positioningHelperFrameForPosition:(BLPosition)aPosition;

@end


@interface WLCalendarWindowArrangement (Layers)

- (void)createLayers;

- (CALayer *)setupImageLayer;

- (CALayer *)setupNavigationLayer;

- (CALayer *)setupCalendarWindowLayer;

- (CALayer *)setupNavigationHelperLayer;

@end


@protocol WLCalendarWindowArrangementDelegate

- (NSRect)windowFrameOfCalendarWindowArrangement:(WLCalendarWindowArrangement *)anArrangement;

- (NSRect)calendarWindowArrangement:(WLCalendarWindowArrangement *)anArrangement setFrame:(NSRect)aFrame;

- (NSRect)calendarWindowArrangement:(WLCalendarWindowArrangement *)anArrangement setPosition:(BLPosition)aPosition;

@end