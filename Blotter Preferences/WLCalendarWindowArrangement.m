//
//  WLCalendarWindowArrangement.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 27.10.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "WLCalendarWindowArrangement.h"
#import "WLBlockLayer.h"
#import "WLNinePartBlockLayer.h"
#import "NSColor+CGColor.h"
#import "CATransaction+WLBlocks.h"
#import "WLRecessedBoxShadowLayer.h"
#import "WLBlockLayoutManager.h"
#import "NSCursor+ResizeAdditions.h"


static NSString *_WLPositionKey = @"position";

static NSString *_WLOriginalFrame = @"originalFrame";

static NSString *_WLTopLeftEdgeFrameKey = @"topLeft";

static NSString *_WLTopCenterEdgeFrameKey = @"topCenter";

static NSString *_WLTopRightEdgeFrameKey = @"topRight";

static NSString *_WLCenterLeftEdgeFrameKey = @"centerLeft";

static NSString *_WLCenterCenterEdgeFrameKey = @"centerCenter";

static NSString *_WLCenterRightEdgeFrameKey = @"centerRight";

static NSString *_WLBottomLeftKey = @"bottomLeft";

static NSString *_WLBottomCenterKey = @"bottomCenter";

static NSString *_WLBottomRightKey = @"bottomRight";

static NSString *_WLEdgeSizeKey = @"_edgeSize";


static const NSSize _WLDefaultEdgeSize = {.width = 20.0f, .height = 20.0f};

static const NSSize _WLMinimumWindowFrameSize = {.width = 10.0f, .height = 10.0f};


@implementation WLCalendarWindowArrangement

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect]) {       
        for (int i = 0; i < 9; i++)
            _resizeAreas[i] = nil;
    }
    return self;
}

- (void)dealloc
{
    [_calendarWindowLayer removeObserver:self forKeyPath:@"bounds"];

    for (int i = 0; i < 9; i++) {
        if (_resizeAreas[i] == nil)
            continue;
        [self removeTrackingArea:_resizeAreas[i]];
        [_resizeAreas[i] release];
        _resizeAreas[i] = nil;
    }

    [super dealloc];
}

#pragma mark Properties
@dynamic backgroundImage;
@synthesize arrangementMode;
@dynamic edgeSize;
@synthesize delegate;

- (NSImage *)backgroundImage
{
    NSParameterAssert([self wantsLayer]);

    return (NSImage *)_imageLayer.contents;
}

- (void)setBackgroundImage:(NSImage *)newBackgroundImage
{
    NSParameterAssert([self wantsLayer]);

    _imageLayer.contents = newBackgroundImage;
}

- (void)setArrangementMode:(NSInteger)newArrangementMode
{
    NSParameterAssert([self wantsLayer]);

    arrangementMode = newArrangementMode;
    if (arrangementMode & WLCalendarWindowResizingArrangement) {
        _resizeHandlesLayer.opacity = 1.0;
        _calendarWindowLayer.borderColor = [[NSColor whiteColor] WL_CGColor];
    }
    else {
        _resizeHandlesLayer.opacity = 0.0f;
        _calendarWindowLayer.borderColor = [[NSColor clearColor] WL_CGColor];        
    }
    [_navigationLayer setNeedsDisplay];
    [[self layer] setNeedsLayout];
}

- (void)setEdgeSize:(NSSize)newEdgeSize
{
    NSParameterAssert([self wantsLayer]);

    [_calendarWindowLayer setValue:[NSValue valueWithSize:newEdgeSize] forKeyPath:_WLEdgeSizeKey];
    [[self layer] setNeedsLayout];
    [_calendarWindowLayer setNeedsDisplay];
}

- (NSSize)edgeSize
{
    NSParameterAssert([self wantsLayer]);

    return [[_calendarWindowLayer valueForKey:_WLEdgeSizeKey] sizeValue];
}

- (NSRect)positionerBounds
{
    NSParameterAssert([self wantsLayer]);

    return NSRectFromCGRect([recessedLayer bounds]);
}


#pragma mark Methods

- (void)startPositioningAtPoint:(NSPoint)aPoint
{
    if (self.arrangementMode == WLCalendarWindowPositioningArrangement)
    {
        [CATransaction begin];
        for (NSInteger i=0; i<9; ++i)
        {
            NSRect f = [self navigationHelperFrameForPosition:(BLPosition)i];
            _navigationHelperAreas[i] = [[NSTrackingArea alloc] initWithRect:f
                                                                     options:NSTrackingMouseEnteredAndExited | NSTrackingActiveWhenFirstResponder | NSTrackingEnabledDuringMouseDrag
                                                                       owner:self
                                                                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:i] forKey:_WLPositionKey]];
            [self addTrackingArea:_navigationHelperAreas[i]];
            [_navigationHelperAreas[i] release];
            [CATransaction WL_performWithDisabledActions:^{
                _navigationHelperLayers[i].frame = NSRectToCGRect(f);
            }];
            if (NSPointInRect(aPoint, f))
                _navigationHelperLayers[i].hidden = NO;
            else
                _navigationHelperLayers[i].hidden = YES;
        }
        [CATransaction commit];
    }
    NSRect windowFrame = NSRectFromCGRect(_calendarWindowLayer.frame);
    if (self.arrangementMode & WLCalendarWindowResizingArrangement)
        windowFrame = [self alignCalendarWindowFrame:windowFrame];
    [_calendarWindowLayer setValue:[NSValue valueWithRect:NSIntegralRect(windowFrame)] forKey:_WLOriginalFrame];
    _navigationLayer.hidden = NO;
}

- (void)continuePositioningAtPoint:(NSPoint)aPoint startPoint:(NSPoint)aStartPoint
{
    [CATransaction WL_performWithDisabledActions:^{
        CGRect newFrame = NSRectToCGRect([[_calendarWindowLayer valueForKey:_WLOriginalFrame] rectValue]);
        if (self.arrangementMode == WLCalendarWindowPositioningArrangement)
        {
            newFrame.origin.x += aPoint.x - aStartPoint.x;
            newFrame.origin.y += aPoint.y - aStartPoint.y;
        }
        else
        {
            newFrame.origin.x = roundf((newFrame.origin.x + aPoint.x - aStartPoint.x) / 10.0f) * 10.0f;
            newFrame.origin.y = roundf((newFrame.origin.y + aPoint.y - aStartPoint.y) / 10.0f) * 10.0f;
        }
        _calendarWindowLayer.frame = newFrame;

    }];
}

- (void)stopPositioningAtPoint:(NSPoint)aPoint
{
    if (self.arrangementMode == WLCalendarWindowPositioningArrangement)
    {
        BOOL isPositionSelected = NO;
        for (NSInteger i=0; i<9; ++i)
        {
            if (!isPositionSelected && NSPointInRect(aPoint, [_navigationHelperAreas[i] rect]))
            {
                isPositionSelected = YES;
                _calendarWindowLayer.frame = NSRectToCGRect([self.delegate calendarWindowArrangement:self setPosition:i]);
            }
            [self removeTrackingArea:_navigationHelperAreas[i]];
            _navigationHelperAreas[i] = nil;
            _navigationHelperLayers[i].hidden = YES;
        }
        if (!isPositionSelected)
            _calendarWindowLayer.frame = NSRectToCGRect([[_calendarWindowLayer valueForKey:_WLOriginalFrame] rectValue]);
    }
    else
    {
        CGRect windowFrame = CGRectInset(_calendarWindowLayer.frame, self.edgeSize.width, self.edgeSize.height);
        windowFrame = NSRectToCGRect([self.delegate calendarWindowArrangement:self setFrame:NSRectFromCGRect(windowFrame)]);
        _calendarWindowLayer.frame = CGRectInset(windowFrame, -self.edgeSize.width, -self.edgeSize.height);
    }
    _navigationLayer.hidden = YES;
    [self updateTrackingAreas];
}

- (void)startResizingAtPoint:(NSPoint)aPoint edge:(WLCalendarWindowEdge)anEdge
{
    NSRect windowFrame = NSRectFromCGRect(_calendarWindowLayer.frame);
    windowFrame = [self alignCalendarWindowFrame:windowFrame];
    [_calendarWindowLayer setValue:[NSValue valueWithRect:windowFrame] forKey:_WLOriginalFrame];
    _navigationLayer.hidden = NO;
    [self setResizeHandlesNeedDisplay];
}

- (void)continueResizingAtPoint:(NSPoint)aPoint startPoint:(NSPoint)aStartPoint edge:(WLCalendarWindowEdge)anEdge
{
    [CATransaction WL_performWithDisabledActions:^{
        NSPoint currentPoint = aPoint;
        BOOL isShiftPressed = NO;
        if ([NSEvent modifierFlags] & NSShiftKeyMask)
        {
            isShiftPressed = YES;
            currentPoint = aStartPoint;
            switch (anEdge) {
                case WLCalendarWindowTopLeftEdge:
                {
                    CGFloat offset = fminf(aStartPoint.x - aPoint.x, aPoint.y - aStartPoint.y);
                    currentPoint.x -= offset;
                    currentPoint.y += offset;
                    break;
                }
                case WLCalendarWindowTopRightEdge:
                {
                    CGFloat offset = fminf(aPoint.x - aStartPoint.x, aPoint.y - aStartPoint.y);
                    currentPoint.x += offset;
                    currentPoint.y += offset;
                    break;
                }
                case WLCalendarWindowBottomLeftEdge:
                {
                    CGFloat offset = fminf(aStartPoint.x - aPoint.x, aStartPoint.y - aPoint.y);
                    currentPoint.x -= offset;
                    currentPoint.y -= offset;
                    break;
                }
                case WLCalendarWindowBottomRightEdge:
                {
                    CGFloat offset = fminf(aPoint.x - aStartPoint.x, aStartPoint.y - aPoint.y);
                    currentPoint.x += offset;
                    currentPoint.y -= offset;
                    break;
                }
                default:
                    currentPoint = aPoint;
                    break;
            }
        }

        /*
              ^
              |
              |     S - start point
              |     E - current point
              |
              |
              |             +--+--------------------+--+
              |             |  |                    |  |
              |             +--------------------------+
              |             |  |                    |  |
              |             |  |                    |  |
              |             |  |                    |  |
              |             |  |                    |  |
              |             |  |                    |  |
              |             |  |                    |  |
              |             |  |                    |  |
              |             |  |                    |  |
              |             +-----------------------|--+
              |     xOffset |  |                    |  |
              |   <--------+S--+--------------------+--+
              |             +
              |             | yOffset
              |   E         v
              +------------------------------------------------>
        */
        CGRect originalFrame = NSRectToCGRect([[_calendarWindowLayer valueForKey:_WLOriginalFrame] rectValue]);
        CGRect newFrame = originalFrame;
        CGRect offsets = CGRectZero;
        switch (anEdge) {
            case WLCalendarWindowTopLeftEdge:
            {
                CGFloat xOffset = currentPoint.x - aStartPoint.x;
                CGFloat yOffset = currentPoint.y - aStartPoint.y;
                offsets.origin.x = xOffset;
                offsets.size.width = -xOffset;
                offsets.size.height = yOffset;
                break;
            }
            case WLCalendarWindowTopCenterEdge:
            {
                CGFloat yOffset = currentPoint.y - aStartPoint.y;
                offsets.size.height = yOffset;
                if (isShiftPressed)
                {
                    yOffset = roundf(yOffset / 10.0f) * 10.0f;
                    offsets.origin.x = -roundf((yOffset / 2.0f) / 10.0f) * 10.0f;
                    offsets.size.width = yOffset;
                }
                break;
            }
            case WLCalendarWindowTopRightEdge:
            {
                CGFloat xOffset = currentPoint.x - aStartPoint.x;
                CGFloat yOffset = currentPoint.y - aStartPoint.y;
                offsets.size.width = xOffset;
                offsets.size.height = yOffset;
                break;
            }
            case WLCalendarWindowCenterLeftEdge:
            {
                CGFloat xOffset = currentPoint.x - aStartPoint.x;
                offsets.origin.x = xOffset;
                offsets.size.width = -xOffset;
                if (isShiftPressed)
                {
                    xOffset = roundf(xOffset / 10.0f) * 10.0f;
                    offsets.origin.y = roundf((xOffset / 2.0f) / 10.0f) * 10.0f;
                    offsets.size.height = -xOffset;
                }
                break;
            }
            case WLCalendarWindowCenterRightEdge:
            {
                CGFloat xOffset = currentPoint.x - aStartPoint.x;
                offsets.size.width = xOffset;
                if (isShiftPressed)
                {
                    xOffset = roundf(xOffset / 10.0f) * 10.0f;
                    offsets.origin.y = -roundf((xOffset / 2.0f) / 10.0f) * 10.0f;
                    offsets.size.height = xOffset;
                }
                break;
            }
            case WLCalendarWindowBottomLeftEdge:
            {
                CGFloat xOffset = currentPoint.x - aStartPoint.x;
                CGFloat yOffset = currentPoint.y - aStartPoint.y;
                offsets.origin.x = xOffset;
                offsets.origin.y = yOffset;
                offsets.size.width = -xOffset;
                offsets.size.height = -yOffset;
                break;
            }
            case WLCalendarWindowBottomCenterEdge:
            {
                CGFloat yOffset = currentPoint.y - aStartPoint.y;
                offsets.origin.y = yOffset;
                offsets.size.height = -yOffset;
                if (isShiftPressed)
                {
                    yOffset = roundf(yOffset / 10.0f) * 10.0f;
                    offsets.origin.x = roundf((yOffset / 2.0f) / 10.0f) * 10.0f;
                    offsets.size.width = -yOffset;
                }
                break;
            }
            case WLCalendarWindowBottomRightEdge:
            {
                CGFloat xOffset = currentPoint.x - aStartPoint.x;
                CGFloat yOffset =  currentPoint.y - aStartPoint.y;
                offsets.origin.y = yOffset;
                offsets.size.width = xOffset;
                offsets.size.height = -yOffset;
                break;
            }
        }
        newFrame.origin.x += offsets.origin.x;
        newFrame.origin.y += offsets.origin.y;
        newFrame.size.width += offsets.size.width;
        newFrame.size.height += offsets.size.height;

        // Don't allow a custom size so small that Blotter would be useless or look buggy.
        NSSize effectiveMinimumFrameSize = _WLMinimumWindowFrameSize;
        NSSize blotterMinimum = [self.delegate minimumSizeForCalendarWindowArrangement:self];
        effectiveMinimumFrameSize.width = fmaxf(effectiveMinimumFrameSize.width, blotterMinimum.width);
        effectiveMinimumFrameSize.height = fmaxf(effectiveMinimumFrameSize.height, blotterMinimum.height);
        
        if (newFrame.origin.x > (CGRectGetMaxX(originalFrame) - effectiveMinimumFrameSize.width - 2 * self.edgeSize.width))
            newFrame.origin.x = CGRectGetMaxX(originalFrame) - effectiveMinimumFrameSize.width - 2 * self.edgeSize.width;
        if (newFrame.origin.y > (CGRectGetMaxY(originalFrame) - effectiveMinimumFrameSize.height - 2 * self.edgeSize.height))
            newFrame.origin.y = CGRectGetMaxY(originalFrame) - effectiveMinimumFrameSize.height - 2 * self.edgeSize.height;
        if (newFrame.size.width < (effectiveMinimumFrameSize.width + 2 * self.edgeSize.width))
            newFrame.size.width = effectiveMinimumFrameSize.width + 2 * self.edgeSize.width;
        if (newFrame.size.height < (effectiveMinimumFrameSize.height + 2 * self.edgeSize.height))
            newFrame.size.height = effectiveMinimumFrameSize.height + 2 * self.edgeSize.height;
        _calendarWindowLayer.frame = NSRectToCGRect([self alignCalendarWindowFrame:NSRectFromCGRect(newFrame)]);;
        // Force an immediate layout within this disabled actions block so that we don't get a resize animation when the parts of the 9-part image realise they need to move later.
        [_calendarWindowLayer layoutIfNeeded];
    }];
}

- (void)stopResizingAtPoint:(NSPoint)aPoint edge:(WLCalendarWindowEdge)anEdge
{
    CGRect windowFrame = CGRectInset(_calendarWindowLayer.frame, self.edgeSize.width, self.edgeSize.height);
    windowFrame = NSRectToCGRect([self.delegate calendarWindowArrangement:self setFrame:NSRectFromCGRect(windowFrame)]);
    _calendarWindowLayer.frame = CGRectInset(windowFrame, -self.edgeSize.width, -self.edgeSize.height);
    _navigationLayer.hidden = YES;
    [self setResizeHandlesNeedDisplay];
    [self updateTrackingAreas];
}

- (NSRect)navigationHelperFrameForPosition:(BLPosition)aPosition
{
    NSRect bounds = NSRectFromCGRect(recessedLayer.bounds);

    CGFloat width = bounds.size.width - 3;
    CGFloat height = bounds.size.height - 3;
    CGFloat pWidth = width / 3 - 10;
    CGFloat pHeight = height / 3 - 10;

    CGFloat px = 1.5;
    CGFloat py = 1.5;
    if (aPosition == BLPositionTopCenter ||
        aPosition == BLPositionCenterCenter ||
        aPosition == BLPositionBottomCenter)
        px = floorf(width / 2.0 - pWidth / 2.0) + 0.5;

    if (aPosition == BLPositionTopRight ||
        aPosition == BLPositionCenterRight ||
        aPosition == BLPositionBottomRight)
        px = width - pWidth + 0.5;

    if (aPosition == BLPositionTopLeft ||
        aPosition == BLPositionTopCenter ||
        aPosition == BLPositionTopRight)
        py = height - pHeight + 0.5;

    if (aPosition == BLPositionCenterLeft ||
        aPosition == BLPositionCenterCenter ||
        aPosition == BLPositionCenterRight)
        py = floorf(height / 2.0 - pHeight / 2.0) + 0.5;

    return [self centerScanRect:NSMakeRect(px, py, pWidth, pHeight)];
}

- (NSRect)alignCalendarWindowFrame:(NSRect)aFrame
{
    aFrame.origin.x = floorf(aFrame.origin.x / 10.0f) * 10.0f;
    aFrame.origin.y = floorf(aFrame.origin.y / 10.0f) * 10.0f;
    aFrame.size.width = ceilf(aFrame.size.width / 10.0f) * 10.0f;
    aFrame.size.height = ceilf(aFrame.size.height / 10.0f) * 10.0f;
    return [self centerScanRect:aFrame];
}


#pragma mark CALayoutManager

- (void)layoutSublayersOfLayer:(CALayer *)aLayer
{
    if (_isPositioning || _isResizing)
        return;

    if (aLayer == [self layer] || aLayer == recessedLayer)
    {
        if ([self inLiveResize])
        {
            /*
             Conceal certain glitches in the calendar widgets CA based resize animation. The window frame
             animation has a different frame rate timing than the CA based animation, causing what appears to 
             be the the double buffer swapping in the middle of CA based layout and redraws. This is visible
             as tearing of the calendar border. By making the CA animation very fast, the proxy moves into 
             its final position faster, hiding the tearing effects.
             
             The drawback is that the proxy animation finishes faster than the window movement. 
            */
            [CATransaction setAnimationDuration:0.1];
        }
        if (aLayer == [self layer])
        {
            recessedLayer.frame = CGRectMake(0,
                                             1,
                                             [self bounds].size.width,
                                             [self bounds].size.height - 1);
        }
        NSRect windowFrame = [self.delegate windowFrameOfCalendarWindowArrangement:self];
        windowFrame = NSInsetRect(windowFrame, -self.edgeSize.width, -self.edgeSize.height);
        if (self.arrangementMode & WLCalendarWindowResizingArrangement && ![self inLiveResize])
            windowFrame = [self alignCalendarWindowFrame:windowFrame];
        _calendarWindowLayer.frame = NSRectToCGRect(windowFrame);
    }
}


#pragma mark NSView

- (void)setFrameSize:(NSSize)newSize
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [super setFrameSize:newSize];
    [CATransaction commit];
}

- (void)viewDidEndLiveResize
{
    [[self layer] setNeedsLayout];
}


#pragma mark NSResponder

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)mouseEntered:(NSEvent *)anEvent
{
    BLPosition p = [[(NSDictionary *)[anEvent userData] objectForKey:_WLPositionKey] integerValue];
    _navigationHelperLayers[p].hidden = NO;
}

- (void)mouseExited:(NSEvent *)anEvent
{
    BLPosition p = [[(NSDictionary *)[anEvent userData] objectForKey:_WLPositionKey] integerValue];
    _navigationHelperLayers[p].hidden = YES;
}

- (void)mouseDown:(NSEvent *)anEvent
{
    NSPoint locationInView = [self convertPoint:[anEvent locationInWindow] fromView:nil];
    NSPoint locationInCalendarLayer = NSPointFromCGPoint([[self layer] convertPoint:NSPointToCGPoint(locationInView) toLayer:_calendarWindowLayer]);
    BOOL doesUserClickCalendarWindow = [_calendarWindowLayer containsPoint:NSPointToCGPoint(locationInCalendarLayer)];
    if (doesUserClickCalendarWindow)
    {
        _startPoint = [self convertPoint:[anEvent locationInWindow] fromView:nil];
        if (self.arrangementMode & WLCalendarWindowResizingArrangement)
        {
            if (NSPointInRect(locationInCalendarLayer, [[_calendarWindowLayer valueForKey:_WLTopLeftEdgeFrameKey] rectValue]))
            {
                _resizedEdge = WLCalendarWindowTopLeftEdge;
                _isResizing = YES;
                [self startResizingAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil] edge:WLCalendarWindowTopLeftEdge];
            }
            else if (NSPointInRect(locationInCalendarLayer, [[_calendarWindowLayer valueForKey:_WLTopCenterEdgeFrameKey] rectValue]))
            {
                _resizedEdge = WLCalendarWindowTopCenterEdge;
                _isResizing = YES;
                [self startResizingAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil] edge:WLCalendarWindowTopCenterEdge];
            }
            else if (NSPointInRect(locationInCalendarLayer, [[_calendarWindowLayer valueForKey:_WLTopRightEdgeFrameKey] rectValue]))
            {
                _resizedEdge = WLCalendarWindowTopRightEdge;
                _isResizing = YES;
                [self startResizingAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil] edge:WLCalendarWindowTopRightEdge];
            }
            else if (NSPointInRect(locationInCalendarLayer, [[_calendarWindowLayer valueForKey:_WLCenterLeftEdgeFrameKey] rectValue]))
            {
                _resizedEdge = WLCalendarWindowCenterLeftEdge;
                _isResizing = YES;
                [self startResizingAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil] edge:WLCalendarWindowCenterLeftEdge];
            }
            else if (NSPointInRect(locationInCalendarLayer, [[_calendarWindowLayer valueForKey:_WLCenterRightEdgeFrameKey] rectValue]))
            {
                _resizedEdge = WLCalendarWindowCenterRightEdge;
                _isResizing = YES;
                [self startResizingAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil] edge:WLCalendarWindowCenterRightEdge];
            }
            else if (NSPointInRect(locationInCalendarLayer, [[_calendarWindowLayer valueForKey:_WLBottomLeftKey] rectValue]))
            {
                _resizedEdge = WLCalendarWindowBottomLeftEdge;
                _isResizing = YES;
                [self startResizingAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil] edge:WLCalendarWindowBottomLeftEdge];
            }
            else if (NSPointInRect(locationInCalendarLayer, [[_calendarWindowLayer valueForKey:_WLBottomCenterKey] rectValue]))
            {
                _resizedEdge = WLCalendarWindowBottomCenterEdge;
                _isResizing = YES;
                [self startResizingAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil] edge:WLCalendarWindowBottomCenterEdge];
            }
            else if (NSPointInRect(locationInCalendarLayer, [[_calendarWindowLayer valueForKey:_WLBottomRightKey] rectValue]))
            {
                _resizedEdge = WLCalendarWindowBottomRightEdge;
                _isResizing = YES;
                [self startResizingAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil] edge:WLCalendarWindowBottomRightEdge];
            }
            else if (NSPointInRect(locationInCalendarLayer, [[_calendarWindowLayer valueForKey:_WLCenterCenterEdgeFrameKey] rectValue]))
            {
                _isPositioning = YES;
                [self startPositioningAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil]];
            }
        }
        else if (self.arrangementMode & WLCalendarWindowPositioningArrangement &&
                 NSPointInRect(locationInCalendarLayer, [[_calendarWindowLayer valueForKey:_WLCenterCenterEdgeFrameKey] rectValue]))
        {
            _isPositioning = YES;
            [self startPositioningAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil]];
        }
    }
}

- (void)mouseDragged:(NSEvent *)anEvent
{
    if (_isPositioning)
        [self continuePositioningAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil] startPoint:_startPoint];
    else if (_isResizing)
        [self continueResizingAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil] startPoint:_startPoint edge:_resizedEdge];
}

- (void)mouseUp:(NSEvent *)anEvent
{
    if (_isPositioning)
    {
        [self stopPositioningAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil]];
        _isPositioning = NO;
    }
    else if (_isResizing)
    {
        [self stopResizingAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil] edge:_resizedEdge];
        _isResizing = NO;
    }
    _startPoint = NSZeroPoint;
}

- (void)cursorUpdate:(NSEvent *)anEvent
{
    // Leave the cursor alone while resizing.
    if (_isResizing || _isPositioning)
        return;
    
    NSPoint hitPoint;
    NSTrackingArea *trackingArea;
    
    trackingArea = [anEvent trackingArea];
    hitPoint = [self convertPoint:[anEvent locationInWindow]
                         fromView:nil];

    // FIXME According to documentation, the cursor should automatically be reset when the mouse leaves a cursor
    // area. This does not appear to work: instead this method gets called again with the same userInfo and
    // tracking area as when the mouse first entered.
    if ([self mouse:hitPoint inRect:[trackingArea rect]]) {
        [((NSCursor *)[((NSDictionary *) [trackingArea userInfo]) objectForKey:@"cursor"]) set];
    } else {
        [super cursorUpdate:anEvent];
    }
}


#pragma mark NSObject

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject change:(NSDictionary *)aChange context:(void *)aContext
{
    if ([aKeyPath isEqualToString:@"bounds"])
    {
        [_calendarWindowLayer setValue:[NSValue valueWithRect:NSIntegralRect(NSMakeRect(_calendarWindowLayer.bounds.origin.x,
                                                                                        _calendarWindowLayer.bounds.origin.y,
                                                                                        self.edgeSize.width,
                                                                                        self.edgeSize.height))]
                                forKey:_WLBottomLeftKey];
        [_calendarWindowLayer setValue:[NSValue valueWithRect:NSIntegralRect(NSMakeRect(_calendarWindowLayer.bounds.origin.x + self.edgeSize.width,
                                                                                        _calendarWindowLayer.bounds.origin.y,
                                                                                        _calendarWindowLayer.bounds.size.width - 2 * self.edgeSize.width,
                                                                                        self.edgeSize.height))]
                                forKey:_WLBottomCenterKey];
        [_calendarWindowLayer setValue:[NSValue valueWithRect:NSIntegralRect(NSMakeRect(_calendarWindowLayer.bounds.size.width - self.edgeSize.width,
                                                                                        _calendarWindowLayer.bounds.origin.y,
                                                                                        self.edgeSize.width,
                                                                                        self.edgeSize.height))]
                                forKey:_WLBottomRightKey];
        [_calendarWindowLayer setValue:[NSValue valueWithRect:NSIntegralRect(NSMakeRect(_calendarWindowLayer.bounds.origin.x,
                                                                                        _calendarWindowLayer.bounds.origin.y + self.edgeSize.height,
                                                                                        self.edgeSize.width,
                                                                                        _calendarWindowLayer.bounds.size.height - 2 * self.edgeSize.height))]
                                forKey:_WLCenterLeftEdgeFrameKey];
        [_calendarWindowLayer setValue:[NSValue valueWithRect:NSIntegralRect(NSMakeRect(_calendarWindowLayer.bounds.size.width - self.edgeSize.width,
                                                                                        _calendarWindowLayer.bounds.origin.y + self.edgeSize.height,
                                                                                        self.edgeSize.width,
                                                                                        _calendarWindowLayer.bounds.size.height - 2 * self.edgeSize.height))]
                                forKey:_WLCenterRightEdgeFrameKey];
        [_calendarWindowLayer setValue:[NSValue valueWithRect:NSIntegralRect(NSMakeRect(_calendarWindowLayer.bounds.origin.x + self.edgeSize.width,
                                                                                        _calendarWindowLayer.bounds.origin.y + self.edgeSize.height,
                                                                                        _calendarWindowLayer.bounds.size.width - 2 * self.edgeSize.width,
                                                                                        _calendarWindowLayer.bounds.size.height - 2 * self.edgeSize.height))]
                                forKey:_WLCenterCenterEdgeFrameKey];
        [_calendarWindowLayer setValue:[NSValue valueWithRect:NSIntegralRect(NSMakeRect(_calendarWindowLayer.bounds.origin.x,
                                                                                        _calendarWindowLayer.bounds.size.height - self.edgeSize.height,
                                                                                        self.edgeSize.width,
                                                                                        self.edgeSize.height))]
                                forKey:_WLTopLeftEdgeFrameKey];
        [_calendarWindowLayer setValue:[NSValue valueWithRect:NSIntegralRect(NSMakeRect(_calendarWindowLayer.bounds.origin.x + self.edgeSize.width,
                                                                                        _calendarWindowLayer.bounds.size.height - self.edgeSize.height,
                                                                                        _calendarWindowLayer.bounds.size.width - 2 * self.edgeSize.width,
                                                                                        self.edgeSize.height))]
                                forKey:_WLTopCenterEdgeFrameKey];
        [_calendarWindowLayer setValue:[NSValue valueWithRect:NSIntegralRect(NSMakeRect(_calendarWindowLayer.bounds.size.width - self.edgeSize.width,
                                                                                        _calendarWindowLayer.bounds.size.height - self.edgeSize.height,
                                                                                        self.edgeSize.width,
                                                                                        self.edgeSize.height))]
                                forKey:_WLTopRightEdgeFrameKey];
        [self updateTrackingAreas];
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end


@implementation WLCalendarWindowArrangement (Layers)


- (void)createLayers
{
    if (![self wantsLayer])
    {
        CALayer *rootLayer = [CALayer layer];
        // The shadow layer draws a semi transparent shine line at the bottom.
        rootLayer.opaque = NO;
        rootLayer.layoutManager = self;
        rootLayer.masksToBounds = YES;
        rootLayer.cornerRadius = 1.5;

        recessedLayer = [CALayer layer];
        recessedLayer.layoutManager = self;
        recessedLayer.delegate = self;
        recessedLayer.masksToBounds = YES;
        recessedLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
        recessedLayer.opaque = YES;

        _imageLayer = [self setupImageLayer];
        _imageLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;

        _navigationLayer = [self setupNavigationLayer];
        _navigationLayer.hidden = YES;
        for (NSUInteger i = 0; i < 9; ++i)
        {
            _navigationHelperLayers[i] = [self setupNavigationHelperLayer];
            [_navigationLayer addSublayer:_navigationHelperLayers[i]];
        }
        _navigationLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;

        _calendarWindowLayer = [self setupCalendarWindowLayer];
        _calendarWindowLayer.autoresizingMask = kCALayerNotSizable;

        _resizeHandlesLayer = [self setupResizeHandlesLayer];
        [_calendarWindowLayer addSublayer:_resizeHandlesLayer];
        _resizeHandlesLayer.frame = _calendarWindowLayer.bounds;
        _resizeHandlesLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
        _resizeHandlesLayer.opacity = 0.0;
        
        _shadowLayer = [self setupShadowLayer];
        _shadowLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;

        [_imageLayer addSublayer:_navigationLayer];
        [recessedLayer addSublayer:_imageLayer];
        [recessedLayer addSublayer:_calendarWindowLayer];
        [rootLayer addSublayer:recessedLayer];
        [rootLayer addSublayer:_shadowLayer];
        [self setLayer:rootLayer];
        [self setWantsLayer:YES];
    }
}

- (CALayer *)setupImageLayer
{
    CALayer *l = [CALayer layer];
    l.opaque = YES;
    l.contentsGravity = kCAGravityResize;
    l.masksToBounds = YES;
    // This is hardly visible but makes the positioner slightly less sharp edged.
    l.cornerRadius = 1.25;
    return l;
}

- (CALayer *)setupShadowLayer {
    CALayer *l = [WLRecessedBoxShadowLayer layer];
    l.opaque = NO;
    return l;
}

- (CALayer *)setupNavigationLayer
{
    WLBlockLayer *l = [NSClassFromString(@"WLBlockLayer") layer];
    l.needsDisplayOnBoundsChange = YES;
    __block WLCalendarWindowArrangement *selfBlock = self;
    l.drawer = ^(CGContextRef aContext, WLBlockLayer *aLayer, CGRect aDirtyRect)
    {
        CGContextSetAllowsAntialiasing(aContext, NO);
        if (selfBlock.arrangementMode == WLCalendarWindowPositioningArrangement)
        {
            CGContextSetStrokeColorWithColor(aContext, [[[NSColor whiteColor] colorWithAlphaComponent:0.9f] WL_CGColor]);
            CGContextSetLineDash(aContext, 0.0f, (CGFloat[]){2.0f, 3.0f}, 2);

            CGContextAddRect(aContext,
                             [aLayer convertRect:NSRectToCGRect([selfBlock navigationHelperFrameForPosition:BLPositionTopLeft]) fromLayer:[selfBlock layer]]);
            CGContextAddRect(aContext,
                             [aLayer convertRect:NSRectToCGRect([selfBlock navigationHelperFrameForPosition:BLPositionCenterLeft]) fromLayer:[selfBlock layer]]);
            CGContextAddRect(aContext,
                             [aLayer convertRect:NSRectToCGRect([selfBlock navigationHelperFrameForPosition:BLPositionBottomLeft]) fromLayer:[selfBlock layer]]);
            CGContextAddRect(aContext,
                             [aLayer convertRect:NSRectToCGRect([selfBlock navigationHelperFrameForPosition:BLPositionTopCenter]) fromLayer:[selfBlock layer]]);
            CGContextAddRect(aContext,
                             [aLayer convertRect:NSRectToCGRect([selfBlock navigationHelperFrameForPosition:BLPositionCenterCenter]) fromLayer:[selfBlock layer]]);
            CGContextAddRect(aContext,
                             [aLayer convertRect:NSRectToCGRect([selfBlock navigationHelperFrameForPosition:BLPositionBottomCenter]) fromLayer:[selfBlock layer]]);
            CGContextAddRect(aContext,
                             [aLayer convertRect:NSRectToCGRect([selfBlock navigationHelperFrameForPosition:BLPositionTopRight]) fromLayer:[selfBlock layer]]);
            CGContextAddRect(aContext,
                             [aLayer convertRect:NSRectToCGRect([selfBlock navigationHelperFrameForPosition:BLPositionCenterRight]) fromLayer:[selfBlock layer]]);
            CGContextAddRect(aContext,
                             [aLayer convertRect:NSRectToCGRect([selfBlock navigationHelperFrameForPosition:BLPositionBottomRight]) fromLayer:[selfBlock layer]]);
            CGContextStrokePath(aContext);
        }
        else
        {
            CGContextSetStrokeColorWithColor(aContext, [[[NSColor whiteColor] colorWithAlphaComponent:0.5f] WL_CGColor]);
            for (CGFloat i=aLayer.bounds.origin.x; i<CGRectGetMaxX(aLayer.bounds); i += 20.0f)
            {
                CGContextMoveToPoint(aContext, i, aLayer.bounds.origin.y);
                CGContextAddLineToPoint(aContext, i, CGRectGetMaxY(aLayer.bounds));
            }
            for (CGFloat i=aLayer.bounds.origin.y; i<CGRectGetMaxY(aLayer.bounds); i += 20.0f)
            {
                CGContextMoveToPoint(aContext, aLayer.bounds.origin.x, i);
                CGContextAddLineToPoint(aContext, CGRectGetMaxX(aLayer.bounds), i);
            }
            CGContextStrokePath(aContext);

            CGContextSetStrokeColorWithColor(aContext, [[[NSColor whiteColor] colorWithAlphaComponent:0.25f] WL_CGColor]);
            for (CGFloat i=aLayer.bounds.origin.x + 10.0f; i<CGRectGetMaxX(aLayer.bounds); i += 20.0f)
            {
                CGContextMoveToPoint(aContext, i, aLayer.bounds.origin.y);
                CGContextAddLineToPoint(aContext, i, CGRectGetMaxY(aLayer.bounds));
            }
            for (CGFloat i=aLayer.bounds.origin.y + 10.0f; i<CGRectGetMaxY(aLayer.bounds); i += 20.0f)
            {
                CGContextMoveToPoint(aContext, aLayer.bounds.origin.x, i);
                CGContextAddLineToPoint(aContext, CGRectGetMaxX(aLayer.bounds), i);
            }
            CGContextStrokePath(aContext);
        }
    };
    return l;
}

- (CALayer *)setupCalendarWindowLayer
{
    static const CGFloat CalendarWindowFrameLineWidth = 5.0f;
    WLNinePartBlockLayer *l = [NSClassFromString(@"WLNinePartBlockLayer") layer];
    l.drawer = ^(CGContextRef aContext, WLBlockLayer *aLayer, CGRect aDirtyRect)
    {
        [NSGraphicsContext saveGraphicsState];
        NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithGraphicsPort:aContext flipped:NO];
        [NSGraphicsContext setCurrentContext:context];

        NSBezierPath *path = [NSBezierPath bezierPath];
        NSRect centerFrame = NSRectFromCGRect(CGRectInset(CGContextGetClipBoundingBox(aContext), _WLDefaultEdgeSize.width, _WLDefaultEdgeSize.height));
        centerFrame = NSInsetRect(centerFrame, CalendarWindowFrameLineWidth / 2, CalendarWindowFrameLineWidth / 2);
        [path appendBezierPathWithRoundedRect:centerFrame xRadius:5.0f yRadius:5.0f];

        [[[NSColor blackColor] colorWithAlphaComponent:0.25f] setFill];
        [path fill];

        [[[NSColor blackColor] colorWithAlphaComponent:0.75f] setStroke];
        [path setLineWidth:CalendarWindowFrameLineWidth];
        [path stroke];
        [NSGraphicsContext restoreGraphicsState];
    };
    NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                       [NSNull null], @"contents",
                                       nil];
    l.actions = newActions;
    [newActions release];
    // Extend size to take care of such things like anti-aliasing.
    l.edgeSize = CGSizeMake(_WLDefaultEdgeSize.width + CalendarWindowFrameLineWidth + 1,
                            _WLDefaultEdgeSize.height + CalendarWindowFrameLineWidth + 1);
    l.needsDisplayOnBoundsChange = YES;
    l.anchorPoint = CGPointMake(0.0f, 0.0f);
    l.cornerRadius = 5.0f;
    l.masksToBounds = YES;
    l.borderWidth = 2.0f;
    l.borderColor = [[NSColor whiteColor] WL_CGColor];
    [l setValue:[NSValue valueWithSize:_WLDefaultEdgeSize] forKeyPath:_WLEdgeSizeKey];
    [l addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:NULL];
    return l;
}

- (CALayer *)setupResizeHandlesLayer
{
    static const int dotWidth = 3;
    static const int dotSpace = 6;
    static const CGSize margin = {.width = 9.0f, .height = 9.0f};
    
    CALayer *l = [CALayer layer];   
   
    l.layoutManager = [[[WLBlockLayoutManager alloc] initWithLayoutManager:^(CALayer *aLayer) {
        CGSize size = [aLayer bounds].size;
        for (int i = 0; i < 9; i++) {
            if (i == 4)
                continue;  
            CALayer *sublayer = [[aLayer sublayers] objectAtIndex:i + (i > 4 ? -1 : 0)];

            CGRect frame = CGRectMake(margin.width + 1, margin.height, dotSpace * 2 + dotWidth, dotSpace * 2 + dotWidth + 1);
            switch(i % 3) {
                case 1:
                    frame.origin.x = floorf(size.width / 2 - frame.size.width / 2);
                    break;
                case 2:
                    frame.origin.x = floorf(size.width - margin.width - dotWidth);
                    break;
            }
            if (i < 3)
                ;
            else if (i < 6) {
                frame.origin.y = floorf(size.height / 2 - frame.size.height / 2) - 1;
            } else {
                frame.origin.y = floorf(size.height - margin.height - dotWidth) - 1;
            }
            if (i == 2 || i == 8)
                frame.origin.x = size.width - margin.width - dotSpace - dotWidth;
            if (i == 6 || i == 8)
                frame.origin.y = size.height - margin.height - dotSpace - dotWidth - 1;
            
            sublayer.frame = frame;
        }
    }] autorelease];
    
    for (int i = 0; i < 9; i++) {
        if (i == 4)
            continue;
        WLBlockLayer *sublayer = [NSClassFromString(@"WLBlockLayer") layer];
               
        sublayer.autoresizingMask = 0;
        
        // Don't animate content changes - when you click a resize handle it should immediately look
        // selected, not cross fade to a selected state.
        NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                           [NSNull null], @"contents",
                                           nil];
        sublayer.actions = newActions;
        [newActions release];
        
        __block WLCalendarWindowArrangement *selfBlock = self;
        sublayer.drawer = ^(CGContextRef aContext, WLBlockLayer *aLayer, CGRect aDirtyRect)
        {
            /* The corner handles look like L shapes and the side handles look like I shapes. */
            
            BOOL isResizeHandle = selfBlock->_isResizing && (
                                   (i == 0 && selfBlock->_resizedEdge == WLCalendarWindowBottomLeftEdge) ||
                                   (i == 1 && selfBlock->_resizedEdge == WLCalendarWindowBottomCenterEdge) ||
                                   (i == 2 && selfBlock->_resizedEdge == WLCalendarWindowBottomRightEdge) ||
                                   (i == 3 && selfBlock->_resizedEdge == WLCalendarWindowCenterLeftEdge) ||
                                   (i == 5 && selfBlock->_resizedEdge == WLCalendarWindowCenterRightEdge) ||
                                   (i == 6 && selfBlock->_resizedEdge == WLCalendarWindowTopLeftEdge) ||
                                   (i == 7 && selfBlock->_resizedEdge == WLCalendarWindowTopCenterEdge) ||
                                   (i == 8 && selfBlock->_resizedEdge == WLCalendarWindowTopRightEdge)
                                   );
            CGContextSetFillColorWithColor(aContext, [(isResizeHandle ? [NSColor colorWithCalibratedWhite:0.2 alpha:1.0] : [NSColor whiteColor]) WL_CGColor]);
            CGContextSetShadowWithColor(aContext, CGSizeMake(0, -1.0), 0.0, [[isResizeHandle ? [NSColor whiteColor] : [NSColor blackColor] colorWithAlphaComponent:0.20] WL_CGColor]);
            
            switch(i)
            {
                case 0:
                    CGContextFillEllipseInRect(aContext, CGRectMake(0, 1, dotWidth, dotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(dotSpace, 1, dotWidth, dotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(0, 1 + dotSpace, dotWidth, dotWidth));
                    break;
                case 1:
                case 7:
                    CGContextFillEllipseInRect(aContext, CGRectMake(0, 1, dotWidth, dotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(dotSpace, 1, dotWidth, dotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(2 * dotSpace, 1, dotWidth, dotWidth));
                    break;
                case 2:
                    CGContextFillEllipseInRect(aContext, CGRectMake(0, 1, dotWidth, dotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(dotSpace, 1, dotWidth, dotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(dotSpace, 1 + dotSpace, dotWidth, dotWidth));
                    break;
                case 3:
                case 5:
                    CGContextFillEllipseInRect(aContext, CGRectMake(0, 1, dotWidth, dotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(0, 1 + dotSpace, dotWidth, dotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(0, 1 + 2 * dotSpace, dotWidth, dotWidth));
                    break;
                case 6:
                    CGContextFillEllipseInRect(aContext, CGRectMake(0, 1, dotWidth, dotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(0, 1 + dotSpace, dotWidth, dotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(dotSpace, 1 + dotSpace, dotWidth, dotWidth));
                    break;
                case 8:
                    CGContextFillEllipseInRect(aContext, CGRectMake(0, 1 + dotSpace, dotWidth, dotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(dotSpace, 1 + dotSpace, dotWidth, dotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(dotSpace, 1, dotWidth, dotWidth));
                    break;
            }
        };

        [l addSublayer:sublayer];
    }

    [l setNeedsLayout];
    return l;
}

- (CALayer *)setupNavigationHelperLayer
{
    CALayer *l = [CALayer layer];
    l.backgroundColor = [[[NSColor blackColor] colorWithAlphaComponent:0.25f] WL_CGColor];
    return l;
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    
    for (int i = 0; i < 9; i++) {
        if (_resizeAreas[i] != nil) {
            [self removeTrackingArea:_resizeAreas[i]];
            [_resizeAreas[i] release];
            _resizeAreas[i] = nil;
        }
        if (_resizeHandlesLayer == nil)
            continue;
        
        // No resize cursors for the resize handles if they aren't visible.
        if (i != 4 && !(arrangementMode & WLCalendarWindowResizingArrangement))
            continue;
        
        CGRect frame = CGRectMake(0, 0, self.edgeSize.width - 1, self.edgeSize.height - 1);
        CGSize size = [_resizeHandlesLayer bounds].size;
        
        NSCursor *cursor = nil;
        switch(i) {
            case 0:
                cursor = [NSCursor WL_resizeDownLeftCursor];
                break;
            case 1:                
                cursor = [NSCursor resizeDownCursor];
                frame = CGRectMake(self.edgeSize.width, 0, size.width - 2 * self.edgeSize.width, self.edgeSize.height - 1);
                break;
            case 2:
                cursor = [NSCursor WL_resizeDownRightCursor];
                frame = CGRectMake(size.width - self.edgeSize.width + 1, 0, self.edgeSize.width - 1, self.edgeSize.height - 1);
                break;
            case 3:
                cursor = [NSCursor resizeLeftCursor];
                frame = CGRectMake(0, self.edgeSize.height, self.edgeSize.width - 1, size.height - 2 * self.edgeSize.height);
                break;
            case 4:
                cursor = [NSCursor openHandCursor];
                // The calendar itself does not have a resize handle.
                frame = CGRectMake(self.edgeSize.width, self.edgeSize.height, size.width - 2 * self.edgeSize.width, size.height - 2 * self.edgeSize.height);
                break;
            case 5:                
                cursor = [NSCursor resizeRightCursor];
                frame = CGRectMake(size.width - self.edgeSize.width + 1, self.edgeSize.height, self.edgeSize.width - 1, size.height - 2 * self.edgeSize.height);
                break;
            case 6:
                cursor = [NSCursor WL_resizeUpLeftCursor];
                frame = CGRectMake(0, size.height - self.edgeSize.height + 1, self.edgeSize.width - 1, self.edgeSize.height - 1);
                break;
            case 7:
                cursor = [NSCursor resizeUpCursor];
                frame = CGRectMake(self.edgeSize.width, size.height - self.edgeSize.height + 1, size.width - 2 * self.edgeSize.width, self.edgeSize.height - 1);
                break;
            case 8:
                cursor = [NSCursor WL_resizeUpRightCursor];
                frame = CGRectMake(size.width - self.edgeSize.width + 1, size.height - self.edgeSize.height + 1, self.edgeSize.width - 1, self.edgeSize.height - 1);
                break;
            default:
                cursor = [NSCursor arrowCursor];
        }
        
        frame = [_resizeHandlesLayer convertRect:frame toLayer:nil];

        
        NSRect f = NSRectFromCGRect(frame);
        _resizeAreas[i] = [[NSTrackingArea alloc] initWithRect:f options:NSTrackingCursorUpdate | NSTrackingActiveInActiveApp owner:self userInfo:[NSDictionary dictionaryWithObject:cursor forKey:@"cursor"]];
        [self addTrackingArea:_resizeAreas[i]];
    }
}

- (void)setResizeHandlesNeedDisplay
{
    for (int i = 0; i < 8; i++) {
        CALayer *sublayer = [[_resizeHandlesLayer sublayers] objectAtIndex:i];
        [sublayer setNeedsDisplay];
    }
}

@end
