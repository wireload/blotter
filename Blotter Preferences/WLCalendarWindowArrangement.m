//
//  WLCalendarWindowPositionControl.m
//  General Preferences
//
//  Created by Alexander Ljungberg on 23/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import "WLCalendarWindowArrangement.h"
#import "WLBlockLayer.h"
#import "NSColor+CGColor.h"
#import "CATransaction+WLBlocks.h"
#import "WLRecessedBoxShadowLayer.h"


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

static NSString *_WLEdgeSizeKey = @"edgeSize";


static const NSSize _WLDefaultEdgeSize = {.width = 20.0f, .height = 20.0f};

static const NSSize _WLMinimumWindowFrameSize = {.width = 10.0f, .height = 10.0f};


@implementation WLCalendarWindowArrangement

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
    if (arrangementMode & WLCalendarWindowResizingArrangement)
        _calendarWindowLayer.borderColor = [[NSColor whiteColor] WL_CGColor];
    else
        _calendarWindowLayer.borderColor = [[NSColor clearColor] WL_CGColor];
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
}

- (void)startResizingAtPoint:(NSPoint)aPoint edge:(WLCalendarWindowEdge)anEdge
{
    NSRect windowFrame = NSRectFromCGRect(_calendarWindowLayer.frame);
    windowFrame = [self alignCalendarWindowFrame:windowFrame];
    [_calendarWindowLayer setValue:[NSValue valueWithRect:windowFrame] forKey:_WLOriginalFrame];
    switch (anEdge) {
        case WLCalendarWindowTopLeftEdge:
            _calendarWindowLayer.contentsGravity = kCAGravityBottomRight;
            break;
        case WLCalendarWindowTopCenterEdge:
            _calendarWindowLayer.contentsGravity = kCAGravityBottom;
            break;
        case WLCalendarWindowTopRightEdge:
            _calendarWindowLayer.contentsGravity = kCAGravityBottomLeft;
            break;
        case WLCalendarWindowCenterLeftEdge:
            _calendarWindowLayer.contentsGravity = kCAGravityRight;
            break;
        case WLCalendarWindowCenterRightEdge:
            _calendarWindowLayer.contentsGravity = kCAGravityLeft;
            break;
        case WLCalendarWindowBottomLeftEdge:
            _calendarWindowLayer.contentsGravity = kCAGravityTopRight;
            break;
        case WLCalendarWindowBottomCenterEdge:
            _calendarWindowLayer.contentsGravity = kCAGravityTop;
            break;
        case WLCalendarWindowBottomRightEdge:
            _calendarWindowLayer.contentsGravity = kCAGravityTopLeft;
            break;
    }
    _navigationLayer.hidden = NO;
}

- (void)continueResizingAtPoint:(NSPoint)aPoint startPoint:(NSPoint)aStartPoint edge:(WLCalendarWindowEdge)anEdge
{
    [CATransaction WL_performWithDisabledActions:^{
        CGRect originalFrame = NSRectToCGRect([[_calendarWindowLayer valueForKey:_WLOriginalFrame] rectValue]);
        CGRect newFrame = originalFrame;
        switch (anEdge) {
            case WLCalendarWindowTopLeftEdge:
                newFrame.origin.x += aPoint.x - aStartPoint.x;
                newFrame.size.width -= aPoint.x - aStartPoint.x;
                newFrame.size.height += aPoint.y - aStartPoint.y;
                break;
            case WLCalendarWindowTopCenterEdge:
                newFrame.size.height += aPoint.y - aStartPoint.y;
                break;
            case WLCalendarWindowTopRightEdge:
                newFrame.size.width += aPoint.x - aStartPoint.x;
                newFrame.size.height += aPoint.y - aStartPoint.y;
                break;
            case WLCalendarWindowCenterLeftEdge:
                newFrame.origin.x += aPoint.x - aStartPoint.x;
                newFrame.size.width -= aPoint.x - aStartPoint.x;
                break;
            case WLCalendarWindowCenterRightEdge:
                newFrame.size.width += aPoint.x - aStartPoint.x;
                break;
            case WLCalendarWindowBottomLeftEdge:
                newFrame.origin.x += aPoint.x - aStartPoint.x;
                newFrame.origin.y += aPoint.y - aStartPoint.y;
                newFrame.size.width -= aPoint.x - aStartPoint.x;
                newFrame.size.height -= aPoint.y - aStartPoint.y;
                break;
            case WLCalendarWindowBottomCenterEdge:
                newFrame.origin.y += aPoint.y - aStartPoint.y;
                newFrame.size.height -= aPoint.y - aStartPoint.y;
                break;
            case WLCalendarWindowBottomRightEdge:
                newFrame.origin.y += aPoint.y - aStartPoint.y;
                newFrame.size.width += aPoint.x - aStartPoint.x;
                newFrame.size.height -= aPoint.y - aStartPoint.y;
                break;
        }

        newFrame = NSRectToCGRect([self alignCalendarWindowFrame:NSRectFromCGRect(newFrame)]);
        if (newFrame.origin.x > (CGRectGetMaxX(originalFrame) - _WLMinimumWindowFrameSize.width - 2 * self.edgeSize.width))
            newFrame.origin.x = CGRectGetMaxX(originalFrame) - _WLMinimumWindowFrameSize.width - 2 * self.edgeSize.width;
        if (newFrame.origin.y > (CGRectGetMaxY(originalFrame) - _WLMinimumWindowFrameSize.height - 2 * self.edgeSize.height))
            newFrame.origin.y = CGRectGetMaxY(originalFrame) - _WLMinimumWindowFrameSize.height - 2 * self.edgeSize.height;
        if (newFrame.size.width < (_WLMinimumWindowFrameSize.width + 2 * self.edgeSize.width))
            newFrame.size.width = _WLMinimumWindowFrameSize.width + 2 * self.edgeSize.width;
        if (newFrame.size.height < (_WLMinimumWindowFrameSize.height + 2 * self.edgeSize.height))
            newFrame.size.height = _WLMinimumWindowFrameSize.height + 2 * self.edgeSize.height;
        _calendarWindowLayer.frame = newFrame;
    }];
}

- (void)stopResizingAtPoint:(NSPoint)aPoint edge:(WLCalendarWindowEdge)anEdge
{
    CGRect windowFrame = CGRectInset(_calendarWindowLayer.frame, self.edgeSize.width, self.edgeSize.height);
    windowFrame = NSRectToCGRect([self.delegate calendarWindowArrangement:self setFrame:NSRectFromCGRect(windowFrame)]);
    _calendarWindowLayer.frame = CGRectInset(windowFrame, -self.edgeSize.width, -self.edgeSize.height);
    _navigationLayer.hidden = YES;
}

- (NSRect)navigationHelperFrameForPosition:(BLPosition)aPosition
{
    NSRect bounds = NSRectFromCGRect(recessedLayer.bounds);

    int width = bounds.size.width - 3;
    int height = bounds.size.height - 3;
    int pWidth = width / 3 - 10;
    int pHeight = height / 3 - 10;

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

    return NSIntegralRect(NSMakeRect(px, py, pWidth, pHeight));
}

- (NSRect)alignCalendarWindowFrame:(NSRect)aFrame
{
    aFrame.origin.x = roundf(aFrame.origin.x / 10.0f) * 10.0f;
    aFrame.origin.y = roundf(aFrame.origin.y / 10.0f) * 10.0f;
    aFrame.size.width = roundf(aFrame.size.width / 10.0f) * 10.0f;
    aFrame.size.height = roundf(aFrame.size.height / 10.0f) * 10.0f;
    return [self centerScanRect:aFrame];
}


#pragma mark CALayoutManager

- (void)layoutSublayersOfLayer:(CALayer *)aLayer
{
    if (_isPositioning || _isResizing)
        return;

    if (aLayer == [self layer] || aLayer == recessedLayer)
    {
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
        _calendarWindowLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;

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
        if (self.arrangementMode == WLCalendarWindowPositioningArrangement)
        {
            CGContextSetStrokeColorWithColor(aContext, [[[NSColor whiteColor] colorWithAlphaComponent:0.9f] WL_CGColor]);
            CGContextSetLineDash(aContext, 0.0f, (CGFloat[]){2.0f, 3.0f}, 2);
            CGContextAddRect(aContext, NSRectToCGRect([selfBlock navigationHelperFrameForPosition:BLPositionTopLeft]));
            CGContextAddRect(aContext, NSRectToCGRect([selfBlock navigationHelperFrameForPosition:BLPositionCenterLeft]));
            CGContextAddRect(aContext, NSRectToCGRect([selfBlock navigationHelperFrameForPosition:BLPositionBottomLeft]));
            CGContextAddRect(aContext, NSRectToCGRect([selfBlock navigationHelperFrameForPosition:BLPositionTopCenter]));
            CGContextAddRect(aContext, NSRectToCGRect([selfBlock navigationHelperFrameForPosition:BLPositionCenterCenter]));
            CGContextAddRect(aContext, NSRectToCGRect([selfBlock navigationHelperFrameForPosition:BLPositionBottomCenter]));
            CGContextAddRect(aContext, NSRectToCGRect([selfBlock navigationHelperFrameForPosition:BLPositionTopRight]));
            CGContextAddRect(aContext, NSRectToCGRect([selfBlock navigationHelperFrameForPosition:BLPositionCenterRight]));
            CGContextAddRect(aContext, NSRectToCGRect([selfBlock navigationHelperFrameForPosition:BLPositionBottomRight]));
            CGContextStrokePath(aContext);
        }
        else
        {
            CGContextSetStrokeColorWithColor(aContext, [[[NSColor whiteColor] colorWithAlphaComponent:0.5f] WL_CGColor]);
            for (CGFloat i=aLayer.bounds.origin.x; i<CGRectGetMaxX(aLayer.bounds); i += 20.0f)
            {
                CGContextMoveToPoint(aContext, i, aLayer.bounds.origin.y);
                CGContextAddLineToPoint(aContext, i, CGRectGetMaxY(aLayer.bounds));
                CGContextStrokePath(aContext);
            }
            for (CGFloat i=aLayer.bounds.origin.y; i<CGRectGetMaxY(aLayer.bounds); i += 20.0f)
            {
                CGContextMoveToPoint(aContext, aLayer.bounds.origin.x, i);
                CGContextAddLineToPoint(aContext, CGRectGetMaxX(aLayer.bounds), i);
                CGContextStrokePath(aContext);
            }

            CGContextSetStrokeColorWithColor(aContext, [[[NSColor whiteColor] colorWithAlphaComponent:0.25f] WL_CGColor]);
            for (CGFloat i=aLayer.bounds.origin.x + 10.0f; i<CGRectGetMaxX(aLayer.bounds); i += 20.0f)
            {
                CGContextMoveToPoint(aContext, i, aLayer.bounds.origin.y);
                CGContextAddLineToPoint(aContext, i, CGRectGetMaxY(aLayer.bounds));
                CGContextStrokePath(aContext);
            }
            for (CGFloat i=aLayer.bounds.origin.y + 10.0f; i<CGRectGetMaxY(aLayer.bounds); i += 20.0f)
            {
                CGContextMoveToPoint(aContext, aLayer.bounds.origin.x, i);
                CGContextAddLineToPoint(aContext, CGRectGetMaxX(aLayer.bounds), i);
                CGContextStrokePath(aContext);
            }
        }
    };
    return l;
}

- (CALayer *)setupCalendarWindowLayer
{
    WLBlockLayer *l = [NSClassFromString(@"WLBlockLayer") layer];
    NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                       [NSNull null], @"contents",
                                       nil];
    l.actions = newActions;
    [newActions release];
    [l addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:NULL];
    l.needsDisplayOnBoundsChange = YES;
    l.anchorPoint = CGPointMake(0.0f, 0.0f);
    l.cornerRadius = 5.0f;
    l.masksToBounds = YES;
    l.borderWidth = 2.0f;
    l.borderColor = [[NSColor whiteColor] WL_CGColor];
    [l setValue:[NSValue valueWithSize:_WLDefaultEdgeSize] forKeyPath:_WLEdgeSizeKey];
    l.drawer = ^(CGContextRef aContext, WLBlockLayer *aLayer, CGRect aDirtyRect)
    {
        static const CGFloat CalendarWindowFrameLineWidth = 5.0f;
        [NSGraphicsContext saveGraphicsState];
        NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithGraphicsPort:aContext flipped:NO];
        [NSGraphicsContext setCurrentContext:context];

        NSBezierPath *path = [NSBezierPath bezierPath];
        NSRect centerFrame = [[aLayer valueForKey:_WLCenterCenterEdgeFrameKey] rectValue];
        centerFrame = NSInsetRect(centerFrame, CalendarWindowFrameLineWidth / 2, CalendarWindowFrameLineWidth / 2);
        [path appendBezierPathWithRoundedRect:centerFrame xRadius:5.0f yRadius:5.0f];

        [[[NSColor blackColor] colorWithAlphaComponent:0.25f] setFill];
        [path fill];

        [[[NSColor blackColor] colorWithAlphaComponent:0.75f] setStroke];
        [path setLineWidth:CalendarWindowFrameLineWidth];
        [path stroke];
        [NSGraphicsContext restoreGraphicsState];
    };
    return l;
}

- (CALayer *)setupNavigationHelperLayer
{
    CALayer *l = [CALayer layer];
    l.backgroundColor = [[[NSColor blackColor] colorWithAlphaComponent:0.25f] WL_CGColor];
    return l;
}

@end
