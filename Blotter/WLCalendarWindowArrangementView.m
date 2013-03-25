//
//  WLCalendarWindowArrangementView.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 27.10.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "WLGraphics.h"
#import "WLCalendarWindowArrangementView.h"
#import "WLNinePartBlockLayer.h"
#import "WLBlockLayoutManager.h"
#import "NSCursor+WLPositioningPreferences.h"
#import "NSColor+WLPrefColors.h"


static NSString *_WLPositionKey = @"position";

static NSString *_WLStartFrame = @"startFrame";

static NSString *_WLTopLeftEdgeFrameKey = @"topLeft";

static NSString *_WLTopCenterEdgeFrameKey = @"topCenter";

static NSString *_WLTopRightEdgeFrameKey = @"topRight";

static NSString *_WLCenterLeftEdgeFrameKey = @"centerLeft";

static NSString *_WLCenterCenterEdgeFrameKey = @"centerCenter";

static NSString *_WLCenterRightEdgeFrameKey = @"centerRight";

static NSString *_WLBottomLeftEdgeKey = @"bottomLeft";

static NSString *_WLBottomCenterEdgeKey = @"bottomCenter";

static NSString *_WLBottomRightEdgeKey = @"bottomRight";

static NSString *_WLEdgeSizeKey = @"_edgeSize";


static const NSSize _WLDefaultEdgeSize = {.width = 20.0, .height = 20.0};

static const NSSize _WLMinimumWindowFrameSize = {.width = 10.0, .height = 10.0};


@implementation WLCalendarWindowArrangementView

- (void)dealloc
{
    [_calendarWindowLayer removeObserver:self forKeyPath:@"bounds"];
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
        _resizeHandlesLayer.opacity = 0.0;
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
                [_navigationHelperLayers[i] setNeedsLayout];
            }];
            if (NSPointInRect(aPoint, f))
                _navigationHelperLayers[i].hidden = NO;
            else
                _navigationHelperLayers[i].hidden = YES;
        }
        [CATransaction commit];
    }
    NSRect windowFrame = [self centerScanRect:NSRectFromCGRect(_calendarWindowLayer.frame)];
    [_calendarWindowLayer setValue:[NSValue valueWithRect:windowFrame] forKey:_WLStartFrame];
    _navigationLayer.hidden = NO;
}

- (void)continuePositioningAtPoint:(NSPoint)aPoint startPoint:(NSPoint)aStartPoint
{
    [CATransaction WL_performWithDisabledActions:^{
        NSRect startFrame = [[_calendarWindowLayer valueForKey:_WLStartFrame] rectValue];
        NSRect newFrame = NSOffsetRect(startFrame,
                                       aPoint.x - aStartPoint.x,
                                       aPoint.y - aStartPoint.y);
        if ([self shouldSnapToGrid])
            newFrame = [self snapCalendarWindowViewFrameToGrid:newFrame];
        else
            newFrame = [self centerScanRect:newFrame];
        _calendarWindowLayer.frame = NSRectToCGRect(newFrame);
        [_calendarWindowLayer setNeedsLayout];
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
                [_calendarWindowLayer setNeedsLayout];
            }
            [self removeTrackingArea:_navigationHelperAreas[i]];
            _navigationHelperAreas[i] = nil;
            _navigationHelperLayers[i].hidden = YES;
        }
        if (!isPositionSelected)
        {
            _calendarWindowLayer.frame = NSRectToCGRect([[_calendarWindowLayer valueForKey:_WLStartFrame] rectValue]);
            [_calendarWindowLayer setNeedsLayout];
        }
    }
    else
    {
        CGRect windowFrame = CGRectInset(_calendarWindowLayer.frame, self.edgeSize.width, self.edgeSize.height);
        windowFrame = NSRectToCGRect([self.delegate calendarWindowArrangement:self setFrame:NSRectFromCGRect(windowFrame)]);
        _calendarWindowLayer.frame = CGRectInset(windowFrame, -self.edgeSize.width, -self.edgeSize.height);
        [_calendarWindowLayer setNeedsLayout];
    }
    _navigationLayer.hidden = YES;
}

- (void)startResizingAtPoint:(NSPoint)aPoint edge:(WLCalendarWindowEdge)anEdge
{
    NSRect windowFrame = [self centerScanRect:NSRectFromCGRect(_calendarWindowLayer.frame)];
    [_calendarWindowLayer setValue:[NSValue valueWithRect:windowFrame] forKey:_WLStartFrame];
    _navigationLayer.hidden = NO;
    [_resizeHandlesLayer.sublayers makeObjectsPerformSelector:@selector(setNeedsDisplay)];
}

- (NSRect)frameAfterResizingAtPoint:(NSPoint)aPoint startPoint:(NSPoint)aStartPoint edge:(WLCalendarWindowEdge)anEdge
{
    NSRect startFrame = [[_calendarWindowLayer valueForKey:_WLStartFrame] rectValue];
    /*
     ^
     |     @ - aStartPoint
     |
     |     0 - WLCalendarWindowTopLeftEdge
     |     1 - WLCalendarWindowTopCenterEdge
     |     2 - WLCalendarWindowTopRightEdge
     |     3 - WLCalendarWindowCenterLeftEdge
     |     4 - WLCalendarWindowCenterCenterEdge (not used)
     |     5 - WLCalendarWindowCenterRightEdge
     |     6 - WLCalendarWindowBottomLeftEdge
     |     7 - WLCalendarWindowBottomCenterEdge
     |     8 - WLCalendarWindowBottomRightEdge
     |
     |             ^            ^             ^
     |             | yOffset    |     yOffset |
     |     xOffset |            |             | xOffset
     |     <-------@--+---------@----------+--@------->
     |             | 0|         1          | 2|
     |             +--------------------------+
     |             |  |                    |  |
     |             |  |                    |  |
     |             |  |                    |  |
     |     <-------@ 3|         4          | 5@------->
     |             |  |                    |  |
     |             |  |                    |  |
     |             |  |                    |  |
     |             |  |                    |  |
     |             +-----------------------|--+
     |     xOffset | 6|         7          | 8| xOffset
     |     <-------@--+---------@----------+--@------->
     |             |            |             |
     |             | yOffset    |             | yOffset
     |             v            v             v
     +------------------------------------------------>
     */
    NSPoint currentPoint = aPoint;
    CGRect offsets = CGRectZero;
    switch (anEdge)
    {
        case WLCalendarWindowTopLeftEdge:
        {
            CGFloat xOffset = 0.0;
            CGFloat yOffset = 0.0;
            if ([self shouldResizeProportionally])
            {
                CGFloat offset = fmin(-(currentPoint.x - aStartPoint.x), currentPoint.y - aStartPoint.y);
                xOffset = -offset;
                yOffset = offset;
                if (xOffset < 0.0)
                    xOffset = NSWidth(startFrame) / NSHeight(startFrame) * -yOffset;
                else
                    yOffset = NSHeight(startFrame) / NSWidth(startFrame) * -xOffset;
            }
            else
            {
                xOffset = currentPoint.x - aStartPoint.x;
                yOffset = currentPoint.y - aStartPoint.y;
            }
            offsets.origin.x = xOffset;
            offsets.size.width = -xOffset;
            offsets.size.height = yOffset;
            break;
        }
        case WLCalendarWindowTopCenterEdge:
        {
            CGFloat yOffset = currentPoint.y - aStartPoint.y;
            offsets.size.height = yOffset;
            if ([self shouldResizeProportionally])
            {
                CGFloat xOffset = NSWidth(startFrame) / NSHeight(startFrame) * yOffset;
                offsets.origin.x = -xOffset / 2.0;
                offsets.size.width = xOffset;
            }
            break;
        }
        case WLCalendarWindowTopRightEdge:
        {
            CGFloat xOffset = 0.0;
            CGFloat yOffset = 0.0;
            if ([self shouldResizeProportionally])
            {
                CGFloat offset = fmin(currentPoint.x - aStartPoint.x, currentPoint.y - aStartPoint.y);
                xOffset = offset;
                yOffset = offset;
                if (xOffset < 0.0)
                    xOffset = NSWidth(startFrame) / NSHeight(startFrame) * xOffset;
                else
                    yOffset = NSHeight(startFrame) / NSWidth(startFrame) * yOffset;
            }
            else
            {
                xOffset = currentPoint.x - aStartPoint.x;
                yOffset = currentPoint.y - aStartPoint.y;
            }
            offsets.size.width = xOffset;
            offsets.size.height = yOffset;
            break;
        }
        case WLCalendarWindowCenterLeftEdge:
        {
            CGFloat xOffset = currentPoint.x - aStartPoint.x;
            offsets.origin.x = xOffset;
            offsets.size.width = -xOffset;
            if ([self shouldResizeProportionally])
            {
                CGFloat yOffset = NSHeight(startFrame) / NSWidth(startFrame) * xOffset;
                offsets.origin.y = yOffset / 2.0;
                offsets.size.height = -yOffset;
            }
            break;
        }
        case WLCalendarWindowCenterRightEdge:
        {
            CGFloat xOffset = currentPoint.x - aStartPoint.x;
            offsets.size.width = xOffset;
            if ([self shouldResizeProportionally])
            {
                CGFloat yOffset = NSHeight(startFrame) / NSWidth(startFrame) * xOffset;
                offsets.origin.y = -yOffset / 2.0;
                offsets.size.height = yOffset;
            }
            break;
        }
        case WLCalendarWindowBottomLeftEdge:
        {
            CGFloat xOffset = 0.0;
            CGFloat yOffset = 0.0;
            if ([self shouldResizeProportionally])
            {
                CGFloat offset = fmin(-(currentPoint.x - aStartPoint.x), -(currentPoint.y - aStartPoint.y));
                xOffset = -offset;
                yOffset = -offset;
                if (xOffset < 0.0)
                    xOffset = NSWidth(startFrame) / NSHeight(startFrame) * yOffset;
                else
                    yOffset = NSHeight(startFrame) / NSWidth(startFrame) * xOffset;
            }
            else
            {
                xOffset = currentPoint.x - aStartPoint.x;
                yOffset = currentPoint.y - aStartPoint.y;
            }
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
            if ([self shouldResizeProportionally])
            {
                CGFloat xOffset = NSWidth(startFrame) / NSHeight(startFrame) * yOffset;
                offsets.origin.x = xOffset / 2.0;
                offsets.size.width = -xOffset;
            }
            break;
        }
        case WLCalendarWindowBottomRightEdge:
        {
            CGFloat xOffset = 0.0;
            CGFloat yOffset = 0.0;
            if ([self shouldResizeProportionally])
            {
                CGFloat offset = fmin(currentPoint.x - aStartPoint.x, -(currentPoint.y - aStartPoint.y));
                xOffset = offset;
                yOffset = -offset;
                if (xOffset < 0.0)
                    xOffset = NSWidth(startFrame) / NSHeight(startFrame) * -yOffset;
                else
                    yOffset = NSHeight(startFrame) / NSWidth(startFrame) * -xOffset;
            }
            else
            {
                xOffset = currentPoint.x - aStartPoint.x;
                yOffset = currentPoint.y - aStartPoint.y;
            }
            offsets.origin.y = yOffset;
            offsets.size.width = xOffset;
            offsets.size.height = -yOffset;
            break;
        }
        default:
            break;
    }
    if ([self shouldKeepMiddleWhileResize])
    {
        offsets.origin.x *= 2.0;
        offsets.origin.y *= 2.0;
        offsets.size.width *= 2.0;
        offsets.size.height *= 2.0;
    }
    NSRect newFrame = startFrame;
    newFrame.origin.x += offsets.origin.x;
    newFrame.origin.y += offsets.origin.y;
    newFrame.size.width += offsets.size.width;
    newFrame.size.height += offsets.size.height;
    if ([self shouldKeepMiddleWhileResize])
    {
        newFrame = NSOffsetRect(newFrame,
                                NSMidX(startFrame) - NSMidX(newFrame),
                                NSMidY(startFrame) - NSMidY(newFrame));
    }

    NSRect maxFrame = NSRectFromCGRect(_calendarWindowLayer.superlayer.bounds);
    maxFrame = NSInsetRect(maxFrame, -self.edgeSize.width, -self.edgeSize.height);
    NSSize effectiveMinimumFrameSize = _WLMinimumWindowFrameSize;
    NSSize blotterMinimum = [self.delegate minimumSizeForCalendarWindowArrangement:self];
    effectiveMinimumFrameSize.width = fmax(effectiveMinimumFrameSize.width, blotterMinimum.width) + 2.0 * self.edgeSize.width;
    effectiveMinimumFrameSize.height = fmax(effectiveMinimumFrameSize.height, blotterMinimum.height) + 2.0 * self.edgeSize.height;
    NSPoint effectiveMinimumFrameOrigin = NSZeroPoint;
    if ([self shouldKeepMiddleWhileResize])
    {
        effectiveMinimumFrameOrigin.x = NSMidX(startFrame) - effectiveMinimumFrameSize.width / 2.0;
        effectiveMinimumFrameOrigin.y = NSMidY(startFrame) - effectiveMinimumFrameSize.height / 2.0;
    }
    else
    {
        switch (anEdge)
        {
            case WLCalendarWindowTopLeftEdge:
            {
                effectiveMinimumFrameOrigin.x = NSMaxX(startFrame) - effectiveMinimumFrameSize.width;
                effectiveMinimumFrameOrigin.y = NSMinY(startFrame);
                break;
            }
            case WLCalendarWindowTopCenterEdge:
            {
                effectiveMinimumFrameOrigin.x = NSMidX(startFrame) - effectiveMinimumFrameSize.width / 2.0;
                effectiveMinimumFrameOrigin.y = NSMinY(startFrame);
                break;
            }
            case WLCalendarWindowTopRightEdge:
            {
                effectiveMinimumFrameOrigin.x = NSMinX(startFrame);
                effectiveMinimumFrameOrigin.y = NSMinY(startFrame);
                break;
            }
            case WLCalendarWindowCenterLeftEdge:
            {
                effectiveMinimumFrameOrigin.x = NSMaxX(startFrame) - effectiveMinimumFrameSize.width;
                effectiveMinimumFrameOrigin.y = NSMidY(startFrame) - effectiveMinimumFrameSize.height / 2.0;
                break;
            }
            case WLCalendarWindowCenterRightEdge:
            {
                effectiveMinimumFrameOrigin.x = NSMinX(startFrame);
                effectiveMinimumFrameOrigin.y = NSMidY(startFrame) - effectiveMinimumFrameSize.height / 2.0;
                break;
            }
            case WLCalendarWindowBottomLeftEdge:
            {
                effectiveMinimumFrameOrigin.x = NSMaxX(startFrame) - effectiveMinimumFrameSize.width;
                effectiveMinimumFrameOrigin.y = NSMaxY(startFrame) - effectiveMinimumFrameSize.height;
                break;
            }
            case WLCalendarWindowBottomCenterEdge:
            {
                effectiveMinimumFrameOrigin.x = NSMidX(startFrame) - effectiveMinimumFrameSize.width / 2.0;
                effectiveMinimumFrameOrigin.y = NSMaxY(startFrame) - effectiveMinimumFrameSize.height;
                break;
            }
            case WLCalendarWindowBottomRightEdge:
            {
                effectiveMinimumFrameOrigin.x = NSMinX(startFrame);
                effectiveMinimumFrameOrigin.y = NSMaxY(startFrame) - effectiveMinimumFrameSize.height;
                break;
            }
            default:
                break;
        }
    }
    NSRect minFrame = NSMakeRect(effectiveMinimumFrameOrigin.x,
                                 effectiveMinimumFrameOrigin.y,
                                 effectiveMinimumFrameSize.width,
                                 effectiveMinimumFrameSize.height);
    newFrame.origin.x = fmin(NSMinX(minFrame), newFrame.origin.x);
    if (NSMinX(newFrame) < NSMinX(maxFrame))
    {
        newFrame.size.width -= NSMinX(maxFrame) - NSMinX(newFrame);
        newFrame.origin.x = NSMinX(maxFrame);
    }
    newFrame.origin.y = fmin(NSMinY(minFrame), newFrame.origin.y);
    if (NSMinY(newFrame) < NSMinY(maxFrame))
    {
        newFrame.size.height -= NSMinY(maxFrame) - NSMinY(newFrame);
        newFrame.origin.y = NSMinY(maxFrame);
    }
    newFrame.size.width = fmin(NSMaxX(maxFrame) - NSMinX(newFrame), newFrame.size.width);
    if (newFrame.size.width < effectiveMinimumFrameSize.width)
    {
        newFrame.origin.x = minFrame.origin.x;
        newFrame.size.width = effectiveMinimumFrameSize.width;
    }
    newFrame.size.height = fmin(NSMaxY(maxFrame) - NSMinY(newFrame), newFrame.size.height);
    if (newFrame.size.height < effectiveMinimumFrameSize.height)
    {
        newFrame.origin.y = minFrame.origin.y;
        newFrame.size.height = effectiveMinimumFrameSize.height;
    }

    if ([self shouldSnapToGrid])
        return [self snapCalendarWindowViewFrameToGrid:newFrame];
    else
        return [self centerScanRect:newFrame];
}

- (void)continueResizingAtPoint:(NSPoint)aPoint startPoint:(NSPoint)aStartPoint edge:(WLCalendarWindowEdge)anEdge
{
    [CATransaction WL_performWithDisabledActions:^{
        _calendarWindowLayer.frame = NSRectToCGRect([self frameAfterResizingAtPoint:aPoint startPoint:aStartPoint edge:anEdge]);
        [_calendarWindowLayer setNeedsLayout];
        // Force an immediate layout within this disabled actions block so that we don't get a resize animation when the parts of the 9-part image realise they need to move later.
        [_calendarWindowLayer layoutIfNeeded];
    }];
}

- (void)stopResizingAtPoint:(NSPoint)aPoint edge:(WLCalendarWindowEdge)anEdge
{
    CGRect windowFrame = CGRectInset(_calendarWindowLayer.frame, self.edgeSize.width, self.edgeSize.height);
    windowFrame = NSRectToCGRect([self.delegate calendarWindowArrangement:self setFrame:NSRectFromCGRect(windowFrame)]);
    _calendarWindowLayer.frame = CGRectInset(windowFrame, -self.edgeSize.width, -self.edgeSize.height);
    [_calendarWindowLayer setNeedsLayout];
    _navigationLayer.hidden = YES;
    [_resizeHandlesLayer.sublayers makeObjectsPerformSelector:@selector(setNeedsDisplay)];
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
        px = floor(width / 2.0 - pWidth / 2.0) + 0.5;

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
        py = floor(height / 2.0 - pHeight / 2.0) + 0.5;

    return [self centerScanRect:NSMakeRect(px, py, pWidth, pHeight)];
}

- (NSRect)snapCalendarWindowViewFrameToGrid:(NSRect)aFrame
{
    aFrame.origin.x = round(aFrame.origin.x / 10.0) * 10.0;
    aFrame.origin.y = round(aFrame.origin.y / 10.0) * 10.0;
    aFrame.size.width = round(aFrame.size.width / 10.0) * 10.0;
    aFrame.size.height = round(aFrame.size.height / 10.0) * 10.0;
    return [self centerScanRect:aFrame];
}

- (NSInteger)edgeForLocationInView:(NSPoint)aLocation
{
    NSPoint locationInCalendarLayer = NSPointFromCGPoint([[self layer] convertPoint:NSPointToCGPoint(aLocation) toLayer:_calendarWindowLayer]);
    if (self.arrangementMode & WLCalendarWindowResizingArrangement)
    {
        if (NSPointInRect(locationInCalendarLayer, NSOffsetRect([[_calendarWindowLayer valueForKey:_WLTopLeftEdgeFrameKey] rectValue], 0.0, -1.0)))
            return WLCalendarWindowTopLeftEdge;
        else if (NSPointInRect(locationInCalendarLayer, NSOffsetRect([[_calendarWindowLayer valueForKey:_WLTopCenterEdgeFrameKey] rectValue], 0.0, -1.0)))
            return WLCalendarWindowTopCenterEdge;
        else if (NSPointInRect(locationInCalendarLayer, NSOffsetRect([[_calendarWindowLayer valueForKey:_WLTopRightEdgeFrameKey] rectValue], 0.0, -1.0)))
            return WLCalendarWindowTopRightEdge;
        else if (NSPointInRect(locationInCalendarLayer, NSOffsetRect([[_calendarWindowLayer valueForKey:_WLCenterLeftEdgeFrameKey] rectValue], 0.0, -1.0)))
            return WLCalendarWindowCenterLeftEdge;
        else if (NSPointInRect(locationInCalendarLayer, NSOffsetRect([[_calendarWindowLayer valueForKey:_WLCenterCenterEdgeFrameKey] rectValue], 0.0, -1.0)))
            return WLCalendarWindowCenterCenterEdge;
        else if (NSPointInRect(locationInCalendarLayer, NSOffsetRect([[_calendarWindowLayer valueForKey:_WLCenterRightEdgeFrameKey] rectValue], 0.0, -1.0)))
            return WLCalendarWindowCenterRightEdge;
        else if (NSPointInRect(locationInCalendarLayer, NSOffsetRect([[_calendarWindowLayer valueForKey:_WLBottomLeftEdgeKey] rectValue], 0.0, -1.0)))
            return WLCalendarWindowBottomLeftEdge;
        else if (NSPointInRect(locationInCalendarLayer, NSOffsetRect([[_calendarWindowLayer valueForKey:_WLBottomCenterEdgeKey] rectValue], 0.0, -1.0)))
            return WLCalendarWindowBottomCenterEdge;
        else if (NSPointInRect(locationInCalendarLayer, NSOffsetRect([[_calendarWindowLayer valueForKey:_WLBottomRightEdgeKey] rectValue], 0.0, -1.0)))
            return WLCalendarWindowBottomRightEdge;
        else
            return -1;
    }
    else
    {
        if (NSPointInRect(locationInCalendarLayer, [[_calendarWindowLayer valueForKey:_WLCenterCenterEdgeFrameKey] rectValue]))
            return WLCalendarWindowCenterCenterEdge;
        else
            return -1;
    }
}

- (BOOL)shouldSnapToGrid
{
    return !([NSEvent modifierFlags] & NSControlKeyMask) && self.arrangementMode & WLCalendarWindowResizingArrangement;
}

- (BOOL)shouldResizeProportionally
{
    return ([NSEvent modifierFlags] & NSShiftKeyMask) && self.arrangementMode & WLCalendarWindowResizingArrangement;
}

- (BOOL)shouldKeepMiddleWhileResize
{
    return ([NSEvent modifierFlags] & NSAlternateKeyMask) && self.arrangementMode & WLCalendarWindowResizingArrangement;
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
            [recessedLayer setNeedsLayout];
        }
        NSRect windowFrame = [self.delegate calendarWindowViewFrameOfCalendarWindowArrangement:self];
        windowFrame = NSInsetRect(windowFrame, -self.edgeSize.width, -self.edgeSize.height);
        _calendarWindowLayer.frame = NSRectToCGRect(windowFrame);
        [_calendarWindowLayer setNeedsLayout];
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

- (void)resetCursorRects
{
    [super resetCursorRects];

    if (_isPositioning || _isResizing || _resizeHandlesLayer == nil)
        return;

    static void (^SetCursorRect)(WLCalendarWindowArrangementView *aSelf, NSString *aFrameKey, WLCalendarWindowEdge anEdge) = ^(WLCalendarWindowArrangementView *aSelf, NSString *aFrameKey, WLCalendarWindowEdge anEdge)
    {
        NSRect frameInCalendarLayer = [[aSelf->_calendarWindowLayer valueForKey:aFrameKey] rectValue];
        CGRect frameInView = [aSelf->_calendarWindowLayer convertRect:NSRectToCGRect(frameInCalendarLayer) toLayer:[aSelf layer]];
        frameInView = CGRectOffset(frameInView, 0.0, -1.0);
        [aSelf addCursorRect:NSRectFromCGRect(frameInView) cursor:[NSCursor WL_cursorForEdge:anEdge]];
    };

    if (arrangementMode & WLCalendarWindowResizingArrangement)
    {
        SetCursorRect(self, _WLTopLeftEdgeFrameKey, WLCalendarWindowTopLeftEdge);
        SetCursorRect(self, _WLTopCenterEdgeFrameKey, WLCalendarWindowTopCenterEdge);
        SetCursorRect(self, _WLTopRightEdgeFrameKey, WLCalendarWindowTopRightEdge);
        SetCursorRect(self, _WLCenterLeftEdgeFrameKey, WLCalendarWindowCenterLeftEdge);
        SetCursorRect(self, _WLCenterCenterEdgeFrameKey, WLCalendarWindowCenterCenterEdge);
        SetCursorRect(self, _WLCenterRightEdgeFrameKey, WLCalendarWindowCenterRightEdge);
        SetCursorRect(self, _WLBottomLeftEdgeKey, WLCalendarWindowBottomLeftEdge);
        SetCursorRect(self, _WLBottomCenterEdgeKey, WLCalendarWindowBottomCenterEdge);
        SetCursorRect(self, _WLBottomRightEdgeKey, WLCalendarWindowBottomRightEdge);
    }
    else
        SetCursorRect(self, _WLCenterCenterEdgeFrameKey, WLCalendarWindowCenterCenterEdge);
}


#pragma mark NSResponder

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)mouseEntered:(NSEvent *)anEvent
{
    BLPosition p = (BLPosition)[[(NSDictionary *)[anEvent userData] objectForKey:_WLPositionKey] integerValue];
    _navigationHelperLayers[p].hidden = NO;
}

- (void)mouseExited:(NSEvent *)anEvent
{
    BLPosition p = (BLPosition)[[(NSDictionary *)[anEvent userData] objectForKey:_WLPositionKey] integerValue];
    _navigationHelperLayers[p].hidden = YES;
}

- (void)mouseDown:(NSEvent *)anEvent
{
    NSPoint locationInView = [self convertPoint:[anEvent locationInWindow] fromView:nil];
    NSInteger edge = [self edgeForLocationInView:locationInView];
    if (edge != -1)
    {
        _startPoint = locationInView;
        static void (^StartResizing)(WLCalendarWindowArrangementView *aSelf, NSPoint aStartPoint, WLCalendarWindowEdge anEdge) = ^(WLCalendarWindowArrangementView *aSelf, NSPoint aStartPoint, WLCalendarWindowEdge anEdge)
        {
            aSelf->_resizedEdge = anEdge;
            aSelf->_isResizing = YES;
            [aSelf startResizingAtPoint:aStartPoint edge:anEdge];
        };

        static void (^StartPositioning)(WLCalendarWindowArrangementView *aSelf, NSPoint aStartPoint) = ^(WLCalendarWindowArrangementView *aSelf, NSPoint aStartPoint)
        {
            aSelf->_isPositioning = YES;
            [aSelf startPositioningAtPoint:aStartPoint];
        };

        if (self.arrangementMode & WLCalendarWindowResizingArrangement)
        {
            switch (edge)
            {
                case WLCalendarWindowTopLeftEdge:
                    StartResizing(self, _startPoint, WLCalendarWindowTopLeftEdge);
                    break;
                case WLCalendarWindowTopCenterEdge:
                    StartResizing(self, _startPoint, WLCalendarWindowTopCenterEdge);
                    break;
                case WLCalendarWindowTopRightEdge:
                    StartResizing(self, _startPoint, WLCalendarWindowTopRightEdge);
                    break;
                case WLCalendarWindowCenterLeftEdge:
                    StartResizing(self, _startPoint, WLCalendarWindowCenterLeftEdge);
                    break;
                case WLCalendarWindowCenterCenterEdge:
                    StartPositioning(self, _startPoint);
                    break;
                case WLCalendarWindowCenterRightEdge:
                    StartResizing(self, _startPoint, WLCalendarWindowCenterRightEdge);
                    break;
                case WLCalendarWindowBottomLeftEdge:
                    StartResizing(self, _startPoint, WLCalendarWindowBottomLeftEdge);
                    break;
                case WLCalendarWindowBottomCenterEdge:
                    StartResizing(self, _startPoint, WLCalendarWindowBottomCenterEdge);
                    break;
                case WLCalendarWindowBottomRightEdge:
                    StartResizing(self, _startPoint, WLCalendarWindowBottomRightEdge);
                    break;
                default:
                    break;
            }
        }
        else if (self.arrangementMode & WLCalendarWindowPositioningArrangement && edge == WLCalendarWindowCenterCenterEdge)
            StartPositioning(self, _startPoint);
    }
    [[self window] invalidateCursorRectsForView:self];
}

- (void)mouseDragged:(NSEvent *)anEvent
{
    if (_isPositioning)
        [self continuePositioningAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil] startPoint:_startPoint];
    else if (_isResizing) {
        [self continueResizingAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil] startPoint:_startPoint edge:_resizedEdge];
        [self cursorUpdate:anEvent];
    }
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
    [[self window] invalidateCursorRectsForView:self];
}

- (void)cursorUpdate:(NSEvent *)anEvent
{
    static const CGFloat testDelta = 9999.00;

    NSPoint locationInView = [self convertPoint:[anEvent locationInWindow] fromView:nil];
    WLCalendarWindowEdge edge = [self edgeForLocationInView:locationInView];

    NSRect oldFrame = NSRectFromCGRect(_calendarWindowLayer.frame);

    NSPoint comparisonPoint = [self convertPoint:[anEvent locationInWindow] fromView:nil];
    comparisonPoint.x -= testDelta;
    BOOL canMoveLeft = _isResizing && !NSEqualRects(oldFrame, [self frameAfterResizingAtPoint:comparisonPoint startPoint:_startPoint edge:_resizedEdge]);
    comparisonPoint.x += 2 * testDelta;
    BOOL canMoveRight = _isResizing && !NSEqualRects(oldFrame, [self frameAfterResizingAtPoint:comparisonPoint startPoint:_startPoint edge:_resizedEdge]);
    comparisonPoint.x -= testDelta;
    comparisonPoint.y -= testDelta;
    BOOL canMoveDown = _isResizing && !NSEqualRects(oldFrame, [self frameAfterResizingAtPoint:comparisonPoint startPoint:_startPoint edge:_resizedEdge]);
    comparisonPoint.y += 2 * testDelta;
    BOOL canMoveUp = _isResizing && !NSEqualRects(oldFrame, [self frameAfterResizingAtPoint:comparisonPoint startPoint:_startPoint edge:_resizedEdge]);

    BOOL canMoveDiagonal = (canMoveUp || canMoveDown) && (canMoveLeft || canMoveRight);

    NSCursor *aCursor = nil;
    if (!canMoveDiagonal) {
        if (canMoveLeft && canMoveRight)
            aCursor = [NSCursor resizeLeftRightCursor];
        else if (canMoveLeft)
            aCursor = [NSCursor resizeLeftCursor];
        else if (canMoveRight)
            aCursor = [NSCursor resizeRightCursor];
        else if (canMoveUp && canMoveDown)
            aCursor = [NSCursor resizeUpDownCursor];
        else if (canMoveUp)
            aCursor = [NSCursor resizeUpCursor];
        else if (canMoveDown)
            aCursor = [NSCursor resizeDownCursor];
    }

    // Diagonal cursors, or some reasonable default cursor if for some reason we can't resize in
    // any direction.
    if (aCursor == nil)
        aCursor = [NSCursor WL_cursorForEdge:(WLCalendarWindowEdge)edge];

    [aCursor set];
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
                                forKey:_WLBottomLeftEdgeKey];
        [_calendarWindowLayer setValue:[NSValue valueWithRect:NSIntegralRect(NSMakeRect(_calendarWindowLayer.bounds.origin.x + self.edgeSize.width,
                                                                                        _calendarWindowLayer.bounds.origin.y,
                                                                                        _calendarWindowLayer.bounds.size.width - 2 * self.edgeSize.width,
                                                                                        self.edgeSize.height))]
                                forKey:_WLBottomCenterEdgeKey];
        [_calendarWindowLayer setValue:[NSValue valueWithRect:NSIntegralRect(NSMakeRect(_calendarWindowLayer.bounds.size.width - self.edgeSize.width,
                                                                                        _calendarWindowLayer.bounds.origin.y,
                                                                                        self.edgeSize.width,
                                                                                        self.edgeSize.height))]
                                forKey:_WLBottomRightEdgeKey];
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
        if (!_isResizing && !_isPositioning)
            [[self window] invalidateCursorRectsForView:self];
    }
    else
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:aChange context:aContext];
}

@end


@implementation WLCalendarWindowArrangementView (Layers)

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
        [_resizeHandlesLayer setNeedsLayout];
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

- (CALayer *)setupShadowLayer
{
    WLBlockLayer *l = [WLBlockLayer layer];
    l.drawer = ^(CGContextRef aContext, WLBlockLayer *aLayer, CGRect aDirtyRect)
    {
        [NSGraphicsContext saveGraphicsState];
        NSGraphicsContext *c = [NSGraphicsContext graphicsContextWithGraphicsPort:aContext flipped:NO];
        [NSGraphicsContext setCurrentContext:c];
        WLRecessedBoxShadow(NSRectFromCGRect(aLayer.bounds));
        [NSGraphicsContext restoreGraphicsState];

    };
    l.opaque = NO;
    return l;
}

- (CALayer *)setupNavigationLayer
{
    WLBlockLayer *l = [WLBlockLayer layer];
    l.needsDisplayOnBoundsChange = YES;
    __block WLCalendarWindowArrangementView *selfBlock = self;
    l.drawer = ^(CGContextRef aContext, WLBlockLayer *aLayer, CGRect aDirtyRect)
    {
        CGContextSetAllowsAntialiasing(aContext, NO);
        if (selfBlock.arrangementMode == WLCalendarWindowPositioningArrangement)
        {
            CGContextSetStrokeColorWithColor(aContext, [[[NSColor whiteColor] colorWithAlphaComponent:0.9] WL_CGColor]);
            CGContextSetLineDash(aContext, 0.0, (CGFloat[]){2.0, 3.0}, 2);

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
            CGContextSetStrokeColorWithColor(aContext, [[[NSColor whiteColor] colorWithAlphaComponent:0.5] WL_CGColor]);
            for (CGFloat i=aLayer.bounds.origin.x; i<CGRectGetMaxX(aLayer.bounds); i += 20.0)
            {
                CGContextMoveToPoint(aContext, i, aLayer.bounds.origin.y);
                CGContextAddLineToPoint(aContext, i, CGRectGetMaxY(aLayer.bounds));
            }
            for (CGFloat i=aLayer.bounds.origin.y; i<CGRectGetMaxY(aLayer.bounds); i += 20.0)
            {
                CGContextMoveToPoint(aContext, aLayer.bounds.origin.x, i);
                CGContextAddLineToPoint(aContext, CGRectGetMaxX(aLayer.bounds), i);
            }
            CGContextStrokePath(aContext);

            CGContextSetStrokeColorWithColor(aContext, [[[NSColor whiteColor] colorWithAlphaComponent:0.25] WL_CGColor]);
            for (CGFloat i=aLayer.bounds.origin.x + 10.0; i<CGRectGetMaxX(aLayer.bounds); i += 20.0)
            {
                CGContextMoveToPoint(aContext, i, aLayer.bounds.origin.y);
                CGContextAddLineToPoint(aContext, i, CGRectGetMaxY(aLayer.bounds));
            }
            for (CGFloat i=aLayer.bounds.origin.y + 10.0; i<CGRectGetMaxY(aLayer.bounds); i += 20.0)
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
    static const CGFloat CalendarWindowFrameLineWidth = 2.0;
    WLNinePartBlockLayer *l = [WLNinePartBlockLayer layer];
    l.drawer = ^(CGContextRef aContext, WLBlockLayer *aLayer, CGRect aDirtyRect)
    {
        [NSGraphicsContext saveGraphicsState];
        NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithGraphicsPort:aContext flipped:NO];
        [NSGraphicsContext setCurrentContext:context];

        NSBezierPath *path = [NSBezierPath bezierPath];
        NSRect centerFrame = NSRectFromCGRect(CGRectInset(CGContextGetClipBoundingBox(aContext), _WLDefaultEdgeSize.width, _WLDefaultEdgeSize.height));
        centerFrame = NSInsetRect(centerFrame, CalendarWindowFrameLineWidth / 2, CalendarWindowFrameLineWidth / 2);
        [path appendBezierPathWithRoundedRect:centerFrame xRadius:5.0 yRadius:5.0];

        [[[NSColor blackColor] colorWithAlphaComponent:0.25] setFill];
        [path fill];

        [[[NSColor blackColor] colorWithAlphaComponent:0.75] setStroke];
        [path setLineWidth:CalendarWindowFrameLineWidth];
        [path stroke];
        [NSGraphicsContext restoreGraphicsState];
    };
    // Extend size to take care of such things like anti-aliasing.
    l.edgeSize = CGSizeMake(_WLDefaultEdgeSize.width + CalendarWindowFrameLineWidth + 1,
                            _WLDefaultEdgeSize.height + CalendarWindowFrameLineWidth + 1);
    l.needsDisplayOnBoundsChange = YES;
    l.anchorPoint = CGPointMake(0.0, 0.0);
    l.cornerRadius = 5.0;
    l.masksToBounds = YES;
    l.borderWidth = 2.0;
    l.borderColor = [[NSColor whiteColor] WL_CGColor];
    [l setValue:[NSValue valueWithSize:_WLDefaultEdgeSize] forKeyPath:_WLEdgeSizeKey];
    [l addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:NULL];
    return l;
}

- (CALayer *)setupResizeHandlesLayer
{
    static const CGFloat DotWidth = 3.0;
    static const CGFloat DotSpace = 6.0;
    static const CGSize Margin = {.width = 9.0, .height = 9.0};

    CALayer *l = [CALayer layer];

    l.layoutManager = [[[WLBlockLayoutManager alloc] initWithLayoutManager:^(CALayer *aLayer) {
        CGSize size = [aLayer bounds].size;
        for (NSInteger i = 0; i < WLCalendarWindowNumberOfEdges; i++) {
            if (i == WLCalendarWindowCenterCenterEdge)
                continue;
            CALayer *sublayer = [[aLayer sublayers] objectAtIndex:i + (i > 4 ? -1 : 0)];

            CGRect frame = CGRectMake(Margin.width + 1, Margin.height, DotSpace * 2 + DotWidth, DotSpace * 2 + DotWidth + 1);
            switch(i % 3) {
                case 1:
                    frame.origin.x = floor(size.width / 2 - frame.size.width / 2);
                    break;
                case 2:
                    frame.origin.x = floor(size.width - Margin.width - DotWidth);
                    break;
            }
            if (i < 3)
                ;
            else if (i < 6) {
                frame.origin.y = floor(size.height / 2 - frame.size.height / 2) - 1;
            } else {
                frame.origin.y = floor(size.height - Margin.height - DotWidth) - 1;
            }
            if (i == WLCalendarWindowTopRightEdge || i == WLCalendarWindowBottomRightEdge)
                frame.origin.x = size.width - Margin.width - DotSpace - DotWidth;
            if (i == WLCalendarWindowBottomLeftEdge || i == WLCalendarWindowBottomRightEdge)
                frame.origin.y = size.height - Margin.height - DotSpace - DotWidth - 1;

            sublayer.frame = frame;
            [sublayer setNeedsLayout];
        }
    }] autorelease];

    for (NSInteger i = 0; i < WLCalendarWindowNumberOfEdges; i++) {
        if (i == WLCalendarWindowCenterCenterEdge)
            continue;
        WLBlockLayer *sublayer = [WLBlockLayer layer];

        sublayer.autoresizingMask = 0;

        // Don't animate content changes - when you click a resize handle it should immediately look
        // selected, not cross fade to a selected state.
        NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                           [NSNull null], @"contents",
                                           nil];
        sublayer.actions = newActions;
        [newActions release];
        __block WLCalendarWindowArrangementView *selfBlock = self;
        sublayer.drawer = ^(CGContextRef aContext, WLBlockLayer *aLayer, CGRect aDirtyRect)
        {
            /* The corner handles look like L shapes and the side handles look like I shapes. */

            BOOL isResizeHandle = selfBlock->_isResizing && (
                                   (i == WLCalendarWindowTopLeftEdge && selfBlock->_resizedEdge == WLCalendarWindowBottomLeftEdge) ||
                                   (i == WLCalendarWindowTopCenterEdge && selfBlock->_resizedEdge == WLCalendarWindowBottomCenterEdge) ||
                                   (i == WLCalendarWindowTopRightEdge && selfBlock->_resizedEdge == WLCalendarWindowBottomRightEdge) ||
                                   (i == WLCalendarWindowCenterLeftEdge && selfBlock->_resizedEdge == WLCalendarWindowCenterLeftEdge) ||
                                   (i == WLCalendarWindowCenterRightEdge && selfBlock->_resizedEdge == WLCalendarWindowCenterRightEdge) ||
                                   (i == WLCalendarWindowBottomLeftEdge && selfBlock->_resizedEdge == WLCalendarWindowTopLeftEdge) ||
                                   (i == WLCalendarWindowBottomCenterEdge && selfBlock->_resizedEdge == WLCalendarWindowTopCenterEdge) ||
                                   (i == WLCalendarWindowBottomRightEdge && selfBlock->_resizedEdge == WLCalendarWindowTopRightEdge)
                                   );
            CGContextSetFillColorWithColor(aContext, [(isResizeHandle ? [NSColor WL_activeDotColor] : [NSColor WL_dotColor]) WL_CGColor]);
            CGContextSetShadowWithColor(aContext, CGSizeMake(0, -1.0), 0.0, [[isResizeHandle ? [NSColor whiteColor] : [NSColor blackColor] colorWithAlphaComponent:0.20] WL_CGColor]);

            switch(i)
            {
                case WLCalendarWindowTopLeftEdge:
                    CGContextFillEllipseInRect(aContext, CGRectMake(0, 1, DotWidth, DotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(DotSpace, 1, DotWidth, DotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(0, 1 + DotSpace, DotWidth, DotWidth));
                    break;
                case WLCalendarWindowTopCenterEdge:
                case WLCalendarWindowBottomCenterEdge:
                    CGContextFillEllipseInRect(aContext, CGRectMake(0, 1, DotWidth, DotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(DotSpace, 1, DotWidth, DotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(2 * DotSpace, 1, DotWidth, DotWidth));
                    break;
                case WLCalendarWindowTopRightEdge:
                    CGContextFillEllipseInRect(aContext, CGRectMake(0, 1, DotWidth, DotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(DotSpace, 1, DotWidth, DotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(DotSpace, 1 + DotSpace, DotWidth, DotWidth));
                    break;
                case WLCalendarWindowCenterLeftEdge:
                case WLCalendarWindowCenterRightEdge:
                    CGContextFillEllipseInRect(aContext, CGRectMake(0, 1, DotWidth, DotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(0, 1 + DotSpace, DotWidth, DotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(0, 1 + 2 * DotSpace, DotWidth, DotWidth));
                    break;
                case WLCalendarWindowBottomLeftEdge:
                    CGContextFillEllipseInRect(aContext, CGRectMake(0, 1, DotWidth, DotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(0, 1 + DotSpace, DotWidth, DotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(DotSpace, 1 + DotSpace, DotWidth, DotWidth));
                    break;
                case WLCalendarWindowBottomRightEdge:
                    CGContextFillEllipseInRect(aContext, CGRectMake(0, 1 + DotSpace, DotWidth, DotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(DotSpace, 1 + DotSpace, DotWidth, DotWidth));
                    CGContextFillEllipseInRect(aContext, CGRectMake(DotSpace, 1, DotWidth, DotWidth));
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
    l.backgroundColor = [[[NSColor blackColor] colorWithAlphaComponent:0.25] WL_CGColor];
    return l;
}

@end


@implementation NSCursor (WLCalendarWindowArrangement)

+ (NSCursor *)WL_cursorForEdge:(WLCalendarWindowEdge)anEdge
{
    switch (anEdge)
    {
        case WLCalendarWindowTopLeftEdge:
            return [NSCursor WL_resizeUpLeftCursor];
        case WLCalendarWindowTopCenterEdge:
            return [NSCursor WL_resizeUpDownCursor];
        case WLCalendarWindowTopRightEdge:
            return [NSCursor WL_resizeUpRightCursor];
        case WLCalendarWindowCenterLeftEdge:
            return [NSCursor WL_resizeLeftRightCursor];
        case WLCalendarWindowCenterCenterEdge:
            return [NSCursor openHandCursor];
        case WLCalendarWindowCenterRightEdge:
            return [NSCursor WL_resizeLeftRightCursor];
        case WLCalendarWindowBottomLeftEdge:
            return [NSCursor WL_resizeDownLeftCursor];
        case WLCalendarWindowBottomCenterEdge:
            return [NSCursor WL_resizeUpDownCursor];
        case WLCalendarWindowBottomRightEdge:
            return [NSCursor WL_resizeDownRightCursor];
        default:
            return [NSCursor arrowCursor];
    }
}

@end
