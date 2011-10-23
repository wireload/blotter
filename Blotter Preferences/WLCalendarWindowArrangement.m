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


static NSString *_WLPositionKey = @"position";

static NSString *_WLStartFrame = @"startFrame";

static NSString *_WLTopLeftKey = @"topLeft";

static NSString *_WLTopCenterKey = @"topCenter";

static NSString *_WLTopRightKey = @"topRight";

static NSString *_WLCenterLeftKey = @"centerLeft";

static NSString *_WLCenterCenterKey = @"centerCenter";

static NSString *_WLCenterRightKey = @"centerRight";

static NSString *_WLBottomLeftKey = @"bottomLeft";

static NSString *_WLBottomCenterKey = @"bottomCenter";

static NSString *_WLBottomRightKey = @"bottomRight";


static const NSSize _WLEdgeSize = {.width = 15.0f, .height = 15.0f};

static const NSSize _WLMinimumWindowSize = {.width = 10.0f, .height = 10.0f};


@implementation WLCalendarWindowArrangement

#pragma mark Properties
@dynamic backgroundImage;
@synthesize arrangementMode;
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
    arrangementMode = newArrangementMode;
    if (arrangementMode & WLCalendarWindowResizingArrangement)
        _calendarWindowLayer.borderColor = [[NSColor whiteColor] WL_CGColor];
    else
        _calendarWindowLayer.borderColor = [[[NSColor whiteColor] colorWithAlphaComponent:0.5f] WL_CGColor];
    [_navigationLayer setNeedsDisplay];
    [[self layer] setNeedsLayout];
}


#pragma mark Methods

- (void)startPositioningAtPoint:(NSPoint)aPoint
{
    if (self.arrangementMode == WLCalendarWindowPositioningArrangement)
    {
        [CATransaction begin];
        for (NSInteger i=0; i<9; ++i)
        {
            NSRect f = [self positioningHelperFrameForPosition:(BLPosition)i];
            _navigationHelperAreas[i] = [[NSTrackingArea alloc] initWithRect:f
                                                                     options:NSTrackingMouseEnteredAndExited | NSTrackingActiveWhenFirstResponder | NSTrackingEnabledDuringMouseDrag
                                                                       owner:self
                                                                    userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:i] forKey:_WLPositionKey]];
            [self addTrackingArea:_navigationHelperAreas[i]];
            [_navigationHelperAreas[i] release];
            [CATransaction setDisableActions:YES];
            _navigationHelperLayers[i].frame = NSRectToCGRect(f);
            [CATransaction setDisableActions:NO];
            if (NSPointInRect(aPoint, f))
                _navigationHelperLayers[i].hidden = NO;
            else
                _navigationHelperLayers[i].hidden = YES;
        }
        [CATransaction commit];
    }
    [_calendarWindowLayer setValue:[NSValue valueWithRect:NSRectFromCGRect(_calendarWindowLayer.frame)] forKey:_WLStartFrame];
    _navigationLayer.hidden = NO;
}

- (void)continuePositioningAtPoint:(NSPoint)aPoint startPoint:(NSPoint)aStartPoint
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    CGRect newFrame = NSRectToCGRect([[_calendarWindowLayer valueForKey:_WLStartFrame] rectValue]);
    if (self.arrangementMode != WLCalendarWindowPositioningArrangement)
    {
        newFrame.origin.x = roundf((newFrame.origin.x + aPoint.x - aStartPoint.x) / 10.0f) * 10.0f;
        newFrame.origin.y = roundf((newFrame.origin.y + aPoint.y - aStartPoint.y) / 10.0f) * 10.0f;
    }
    else
    {
        newFrame.origin.x += aPoint.x - aStartPoint.x;
        newFrame.origin.y += aPoint.y - aStartPoint.y;
    }
    _calendarWindowLayer.frame = newFrame;
    [CATransaction commit];
}

- (void)stopPositioningAtPoint:(NSPoint)aPoint
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
        _calendarWindowLayer.frame = NSRectToCGRect([[_calendarWindowLayer valueForKey:_WLStartFrame] rectValue]);
    _navigationLayer.hidden = YES;
}

- (void)startResizingAtPoint:(NSPoint)aPoint edge:(WLCalendarWindowEdge)anEdge
{
    [_calendarWindowLayer setValue:[NSValue valueWithRect:NSRectFromCGRect(_calendarWindowLayer.frame)] forKey:_WLStartFrame];
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
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    CGRect newFrame = NSRectToCGRect([[_calendarWindowLayer valueForKey:_WLStartFrame] rectValue]);
    aPoint.x = roundf(aPoint.x / 10.0f) * 10.0f;
    aPoint.y = roundf(aPoint.y / 10.0f) * 10.0f;
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
//    newFrame.origin.x = roundf(newFrame.origin.x / 10.0f) * 10.0f;
//    newFrame.origin.y = roundf(newFrame.origin.y / 10.0f) * 10.0f;
//    newFrame.size.width = roundf(newFrame.size.width / 10.0f) * 10.0f;
//    newFrame.size.height = roundf(newFrame.size.height / 10.0f) * 10.0f;
    
//    newFrame.origin.x = fminf(newFrame.origin.x, CGRectGetMaxX(_calendarWindowLayer.frame) - 2 * _WLEdgeSize.width - _WLMinimumWindowSize.width);
//    newFrame.origin.x = roundf(newFrame.origin.x / 10.0f) * 10.0f;
//    newFrame.origin.y = fminf(newFrame.origin.y, CGRectGetMaxY(_calendarWindowLayer.frame) - 2 * _WLEdgeSize.height - _WLMinimumWindowSize.height);
//    newFrame.origin.y = roundf(newFrame.origin.y / 10.0f) * 10.0f;
//    newFrame.size.width = fmaxf(newFrame.size.width, 2 * _WLEdgeSize.width + _WLMinimumWindowSize.width);    
//    newFrame.size.height = fmaxf(newFrame.size.height, 2 * _WLEdgeSize.height + _WLMinimumWindowSize.height);
    _calendarWindowLayer.frame = newFrame;
    [CATransaction commit];
}

- (void)stopResizingAtPoint:(NSPoint)aPoint edge:(WLCalendarWindowEdge)anEdge
{
    
    NSRect frame = [self.delegate calendarWindowArrangement:self
                                                   setFrame:[[_calendarWindowLayer valueForKey:_WLCenterCenterKey] rectValue]];
    _calendarWindowLayer.frame = NSRectToCGRect(NSInsetRect(frame, -_WLEdgeSize.width, -_WLEdgeSize.height));
    _navigationLayer.hidden = YES;
}

- (NSRect)positioningHelperFrameForPosition:(BLPosition)aPosition
{
    NSRect bounds = [self bounds];
    
    int width = bounds.size.width - 2;
    int height = bounds.size.height - 2;
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


#pragma mark CALayoutManager

- (void)layoutSublayersOfLayer:(CALayer *)aLayer
{
    if (aLayer != [self layer])
        return;    

    if (!_isPositioning && !_isResizing)
    {
        _calendarWindowLayer.frame = CGRectIntegral(NSRectToCGRect(NSInsetRect([self.delegate windowFrameOfCalendarWindowArrangement:self],
                                                                               -_WLEdgeSize.width,
                                                                               -_WLEdgeSize.height)));
    }
    [_calendarWindowLayer setValue:[NSValue valueWithRect:NSIntegralRect(NSMakeRect(_calendarWindowLayer.bounds.origin.x,
                                                                         _calendarWindowLayer.bounds.origin.y,
                                                                         _WLEdgeSize.width,
                                                                         _WLEdgeSize.height))]
                            forKey:_WLBottomLeftKey];
    [_calendarWindowLayer setValue:[NSValue valueWithRect:NSIntegralRect(NSMakeRect(_calendarWindowLayer.bounds.origin.x + _WLEdgeSize.width,
                                                                         _calendarWindowLayer.bounds.origin.y,
                                                                         _calendarWindowLayer.bounds.size.width - 2 * _WLEdgeSize.width,
                                                                         _WLEdgeSize.height))]
                            forKey:_WLBottomCenterKey];
    [_calendarWindowLayer setValue:[NSValue valueWithRect:NSIntegralRect(NSMakeRect(_calendarWindowLayer.bounds.size.width - _WLEdgeSize.width,
                                                                         _calendarWindowLayer.bounds.origin.y,
                                                                         _WLEdgeSize.width,
                                                                         _WLEdgeSize.height))]
                            forKey:_WLBottomRightKey];
    [_calendarWindowLayer setValue:[NSValue valueWithRect:NSIntegralRect(NSMakeRect(_calendarWindowLayer.bounds.origin.x,
                                                                         _calendarWindowLayer.bounds.origin.y + _WLEdgeSize.height,
                                                                         _WLEdgeSize.width,
                                                                         _calendarWindowLayer.bounds.size.height - 2 * _WLEdgeSize.height))]
                            forKey:_WLCenterLeftKey];
    [_calendarWindowLayer setValue:[NSValue valueWithRect:NSIntegralRect(NSMakeRect(_calendarWindowLayer.bounds.size.width - _WLEdgeSize.width,
                                                                         _calendarWindowLayer.bounds.origin.y + _WLEdgeSize.height,
                                                                         _WLEdgeSize.width,
                                                                         _calendarWindowLayer.bounds.size.height - 2 * _WLEdgeSize.height))]
                            forKey:_WLCenterRightKey];
    [_calendarWindowLayer setValue:[NSValue valueWithRect:NSIntegralRect(NSMakeRect(_calendarWindowLayer.bounds.origin.x + _WLEdgeSize.width,
                                                                         _calendarWindowLayer.bounds.origin.y + _WLEdgeSize.height,
                                                                         _calendarWindowLayer.bounds.size.width - 2 * _WLEdgeSize.width,
                                                                         _calendarWindowLayer.bounds.size.height - 2 * _WLEdgeSize.height))]
                            forKey:_WLCenterCenterKey];
    [_calendarWindowLayer setValue:[NSValue valueWithRect:NSIntegralRect(NSMakeRect(_calendarWindowLayer.bounds.origin.x,
                                                                         _calendarWindowLayer.bounds.size.height - _WLEdgeSize.height,
                                                                         _WLEdgeSize.width,
                                                                         _WLEdgeSize.height))]
                            forKey:_WLTopLeftKey];
    [_calendarWindowLayer setValue:[NSValue valueWithRect:NSIntegralRect(NSMakeRect(_calendarWindowLayer.bounds.origin.x + _WLEdgeSize.width,
                                                                         _calendarWindowLayer.bounds.size.height - _WLEdgeSize.height,
                                                                         _calendarWindowLayer.bounds.size.width - 2 * _WLEdgeSize.width,
                                                                         _WLEdgeSize.height))]
                            forKey:_WLTopCenterKey];
    [_calendarWindowLayer setValue:[NSValue valueWithRect:NSIntegralRect(NSMakeRect(_calendarWindowLayer.bounds.size.width - _WLEdgeSize.width,
                                                                         _calendarWindowLayer.bounds.size.height - _WLEdgeSize.height,
                                                                         _WLEdgeSize.width,
                                                                         _WLEdgeSize.height))]
                            forKey:_WLTopRightKey];
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
            if (NSPointInRect(locationInCalendarLayer, [[_calendarWindowLayer valueForKey:_WLTopLeftKey] rectValue]))
            {
                _resizedEdge = WLCalendarWindowTopLeftEdge;
                _isResizing = YES;
                [self startResizingAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil] edge:WLCalendarWindowTopLeftEdge];
            }
            else if (NSPointInRect(locationInCalendarLayer, [[_calendarWindowLayer valueForKey:_WLTopCenterKey] rectValue]))
            {
                _resizedEdge = WLCalendarWindowTopCenterEdge;
                _isResizing = YES;
                [self startResizingAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil] edge:WLCalendarWindowTopCenterEdge];
            }
            else if (NSPointInRect(locationInCalendarLayer, [[_calendarWindowLayer valueForKey:_WLTopRightKey] rectValue]))
            {
                _resizedEdge = WLCalendarWindowTopRightEdge;
                _isResizing = YES;
                [self startResizingAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil] edge:WLCalendarWindowTopRightEdge];
            }
            else if (NSPointInRect(locationInCalendarLayer, [[_calendarWindowLayer valueForKey:_WLCenterLeftKey] rectValue]))
            {
                _resizedEdge = WLCalendarWindowCenterLeftEdge;
                _isResizing = YES;
                [self startResizingAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil] edge:WLCalendarWindowCenterLeftEdge];
            }
            else if (NSPointInRect(locationInCalendarLayer, [[_calendarWindowLayer valueForKey:_WLCenterRightKey] rectValue]))
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
            else if (NSPointInRect(locationInCalendarLayer, [[_calendarWindowLayer valueForKey:_WLCenterCenterKey] rectValue]))
            {
                _isPositioning = YES;
                [self startPositioningAtPoint:[self convertPoint:[anEvent locationInWindow] fromView:nil]];
            }
        }
        else if (self.arrangementMode & WLCalendarWindowPositioningArrangement)
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

@end


@implementation WLCalendarWindowArrangement (Layers)


- (void)createLayers
{
    if (![self wantsLayer])
    {   
        CALayer *rootLayer = [CALayer layer];
        rootLayer.opaque = YES;
        rootLayer.layoutManager = self;
        rootLayer.delegate = self;
        _imageLayer = [self setupImageLayer];
        _imageLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
        
        _navigationLayer = [self setupNavigationLayer];
        for (NSInteger i=0; i<9; ++i)
        {
            _navigationHelperLayers[i] = [self setupNavigationHelperLayer];
            [_navigationLayer addSublayer:_navigationHelperLayers[i]];
        }
        _navigationLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
        
        _calendarWindowLayer = [self setupCalendarWindowLayer];
        _calendarWindowLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
        
        [_imageLayer addSublayer:_navigationLayer];
        [rootLayer addSublayer:_imageLayer];
        [rootLayer addSublayer:_calendarWindowLayer];
        [self setLayer:rootLayer];
        [self setWantsLayer:YES];
    }
}

- (CALayer *)setupImageLayer
{
    CALayer *l = [CALayer layer];
    l.opaque = YES;
    l.contentsGravity = kCAGravityResize;
    return l;
}

- (CALayer *)setupNavigationLayer
{
    WLBlockLayer *l = [NSClassFromString(@"WLBlockLayer") layer];
    l.hidden = YES;
    l.needsDisplayOnBoundsChange = YES;
    __block WLCalendarWindowArrangement *selfBlock = self;
    l.drawer = ^(CGContextRef aContext, WLBlockLayer *aLayer, CGRect aDirtyRect)
    {
        CGContextSetAllowsAntialiasing(aContext, NO);
        if (self.arrangementMode == WLCalendarWindowPositioningArrangement)
        {
            CGContextSetStrokeColorWithColor(aContext, [[[NSColor whiteColor] colorWithAlphaComponent:0.9f] WL_CGColor]);
            CGContextSetLineDash(aContext, 0.0f, (CGFloat[]){2.0f, 3.0f}, 2);
            CGContextAddRect(aContext, NSRectToCGRect([selfBlock positioningHelperFrameForPosition:BLPositionTopLeft]));
            CGContextAddRect(aContext, NSRectToCGRect([selfBlock positioningHelperFrameForPosition:BLPositionCenterLeft]));
            CGContextAddRect(aContext, NSRectToCGRect([selfBlock positioningHelperFrameForPosition:BLPositionBottomLeft]));
            CGContextAddRect(aContext, NSRectToCGRect([selfBlock positioningHelperFrameForPosition:BLPositionTopCenter]));
            CGContextAddRect(aContext, NSRectToCGRect([selfBlock positioningHelperFrameForPosition:BLPositionCenterCenter]));
            CGContextAddRect(aContext, NSRectToCGRect([selfBlock positioningHelperFrameForPosition:BLPositionBottomCenter]));
            CGContextAddRect(aContext, NSRectToCGRect([selfBlock positioningHelperFrameForPosition:BLPositionTopRight]));
            CGContextAddRect(aContext, NSRectToCGRect([selfBlock positioningHelperFrameForPosition:BLPositionCenterRight]));
            CGContextAddRect(aContext, NSRectToCGRect([selfBlock positioningHelperFrameForPosition:BLPositionBottomRight]));
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
    l.needsDisplayOnBoundsChange = YES;
    l.anchorPoint = CGPointMake(0.0f, 0.0f);
    l.cornerRadius = 5.0f;
    l.masksToBounds = YES;
    l.borderWidth = 2.0f;
    l.borderColor = [[NSColor whiteColor] WL_CGColor];
    l.drawer = ^(CGContextRef aContext, WLBlockLayer *aLayer, CGRect aDirtyRect)
    {
        [NSGraphicsContext saveGraphicsState];
        NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithGraphicsPort:aContext flipped:NO];
        [NSGraphicsContext setCurrentContext:context];
        NSBezierPath *path = [NSBezierPath bezierPath];
        NSRect centerFrame = [[aLayer valueForKey:_WLCenterCenterKey] rectValue];
        [path appendBezierPathWithRoundedRect:centerFrame xRadius:5.0f yRadius:5.0f];
        [[[NSColor blackColor] colorWithAlphaComponent:0.25f] setFill];
        [path fill];
        [[[NSColor blackColor] colorWithAlphaComponent:0.75f] setStroke];
        [path setLineWidth:5];
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
