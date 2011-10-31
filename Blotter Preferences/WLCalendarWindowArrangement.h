//
//  WLCalendarWindowArrangement.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 27.10.11.
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
    WLCalendarWindowTopLeftEdge = 0,
    WLCalendarWindowTopCenterEdge = 1,
    WLCalendarWindowTopRightEdge = 2,
    WLCalendarWindowCenterLeftEdge = 3,
    WLCalendarWindowCenterCenterEdge = 4,
    WLCalendarWindowCenterRightEdge = 5,
    WLCalendarWindowBottomLeftEdge = 6,
    WLCalendarWindowBottomCenterEdge = 7,
    WLCalendarWindowBottomRightEdge = 8,

    WLCalendarWindowNumberOfEdges
} WLCalendarWindowEdge;


@protocol WLCalendarWindowArrangementDelegate;


@interface WLCalendarWindowArrangement : NSView /*<CALayerDelegate, CALayoutManager>*/ {
    NSInteger arrangementMode;
    IBOutlet NSObject<WLCalendarWindowArrangementDelegate> *delegate;

    CALayer *recessedLayer;
    CALayer *_imageLayer;
    CALayer *_navigationLayer;
    CALayer *_calendarWindowLayer;
    CALayer *_resizeHandlesLayer;
    CALayer *_shadowLayer;
    NSTrackingArea *_navigationHelperAreas[9];
    NSRect _resizingAreas[WLCalendarWindowNumberOfEdges];
    CALayer *_navigationHelperLayers[9];
    BOOL _isPositioning;
    BOOL _isResizing;
    WLCalendarWindowEdge _resizedEdge;
    NSPoint _startPoint;
    id _flagsMonitor;
}

@property (nonatomic, copy) NSImage *backgroundImage;

@property (nonatomic) NSInteger arrangementMode;

@property (nonatomic) NSSize edgeSize;

@property (assign) NSObject<WLCalendarWindowArrangementDelegate> *delegate;

- (void)startPositioningAtPoint:(NSPoint)aPoint;

- (void)continuePositioningAtPoint:(NSPoint)aPoint startPoint:(NSPoint)aStartPoint;

- (void)stopPositioningAtPoint:(NSPoint)aPoint;

- (void)startResizingAtPoint:(NSPoint)aPoint edge:(WLCalendarWindowEdge)anEdge;

- (void)continueResizingAtPoint:(NSPoint)aPoint startPoint:(NSPoint)aStartPoint edge:(WLCalendarWindowEdge)anEdge;

- (void)stopResizingAtPoint:(NSPoint)aPoint edge:(WLCalendarWindowEdge)anEdge;

- (NSRect)navigationHelperFrameForPosition:(BLPosition)aPosition;

- (NSRect)positionerBounds;

- (NSRect)alignCalendarWindowFrame:(NSRect)aFrame;


/*!
 @abstract  Returns edge for current mouse location or -1 if mouse doesn't point to any edge.
 */
- (NSInteger)_edgeForCurrentMouseLocation;

@end


@interface WLCalendarWindowArrangement (Layers)

- (void)createLayers;

- (CALayer *)setupImageLayer;

- (CALayer *)setupShadowLayer;

- (CALayer *)setupNavigationLayer;

- (CALayer *)setupCalendarWindowLayer;

- (CALayer *)setupNavigationHelperLayer;

- (CALayer *)setupResizeHandlesLayer;

@end


@protocol WLCalendarWindowArrangementDelegate

- (NSRect)windowFrameOfCalendarWindowArrangement:(WLCalendarWindowArrangement *)anArrangement;

- (NSRect)calendarWindowArrangement:(WLCalendarWindowArrangement *)anArrangement setFrame:(NSRect)aFrame;

- (NSRect)calendarWindowArrangement:(WLCalendarWindowArrangement *)anArrangement setPosition:(BLPosition)aPosition;

- (NSSize)minimumSizeForCalendarWindowArrangement:(WLCalendarWindowArrangement *)anArrangement;

@end


@interface NSCursor (WLCalendarWindowArrangement)

+ (NSCursor *)WL_cursorForEdge:(WLCalendarWindowEdge)anEdge;

@end