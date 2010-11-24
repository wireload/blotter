//
//  BLPositionerControlCell.m
//  General Preferences
//
//  Created by Alexander Ljungberg on 23/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import "BLPositionerControl.h"
#import "BLPositionerControlCell.h"


@implementation BLPositionerControlCell

+ (BOOL)prefersTrackingUntilMouseUp
{
    return YES;
}

- (id)init {
    self = [super initTextCell:@"0"];
    if (self)
    {
        [self setIntValue:BLPositionTopLeft];

        // Initialization code here.
        NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"Recreated-Aqua" ofType:@"jpg"];
        backgroundImage = [[NSImage alloc] initWithContentsOfFile:path];

        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
                                                                  forKeyPath:@"values.CalendarSize"
                                                                     options:0
                                                                     context:NULL];
    }
    return self;
}

- (void)dealloc
{
    [backgroundImage release];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self];

    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [[self controlView] setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)anEvent
{
}

- (BOOL)startTrackingAt:(NSPoint)location inView:(NSView *)controlView
{
    if (!isDragging)
    {
        NSRect positionRect = [self selectedRect];
        if (NSPointInRect(location, positionRect))
        {
            isDragging = YES;
            dragStart = location;
            return [self continueTracking:location at:location inView:controlView];
        }
   }
   return isDragging;
}

- (BOOL)continueTracking:(NSPoint)lastPoint at:(NSPoint)location inView:(NSView *)controlView
{
    if (isDragging)
    {
        dragOffset = NSMakePoint(location.x - dragStart.x, location.y - dragStart.y);
        dragDropPosition = -1;
        if (abs(dragOffset.x) > 2 || abs(dragOffset.y) > 2)
        {
            for (int i = BLPositionTopLeft; i <= BLPositionBottomRight; i++)
            {
                if (NSPointInRect(location, [self rectForPosition:i]))
                {
                    dragDropPosition = i;
                    break;
                }
            }
        }
        [[self controlView] setNeedsDisplay:YES];
    }
    return isDragging;
}

- (void)stopTracking:(NSPoint)lastPoint at:(NSPoint)location inView:(NSView *)controlView mouseIsUp:(BOOL)flag
{
    if (isDragging)
    {
        isDragging = NO;
        if (dragDropPosition >= 0)
        {
            [self setIntegerValue:dragDropPosition];
        }
        [[self controlView] setNeedsDisplay:YES];
    }
}

- (NSRect)rectForPosition:(BLPosition)aPosition
{
    NSRect bounds = [[self controlView] bounds];

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

    return NSMakeRect(px, py, pWidth, pHeight);
}

- (NSRect)selectedRect
{
    int position = [self intValue];
    NSSize boundsSize = [[self controlView] bounds].size;
    NSRect fullFrame = [[NSScreen mainScreen] visibleFrame];
    NSPoint scaleFactor = NSMakePoint(boundsSize.width / fullFrame.size.width, boundsSize.height / fullFrame.size.height);
    NSRect relativeFrame = [BLCalendarFramer frameForPosition:position scaleFactor:scaleFactor margin:NSMakeSize(10, 10)];

    return relativeFrame;
}

- (void)drawWithFrame:(NSRect)bounds inView:(NSView *)controlView
{
    [NSBezierPath setDefaultLineWidth:1.0];

    [backgroundImage drawInRect:bounds fromRect:NSZeroRect
                operation:NSCompositeSourceOver fraction:1.0];

    CGFloat lineDash[2];
    lineDash[0] = 2.0;
    lineDash[1] = 3.0;

    NSColor *dashColor = [NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:0.9];
    NSColor *selectedColor = [NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:0.9];
    int position = [self intValue];

    for (int x = 0; x < 3; x++)
    {
        for (int y = 0; y < 3; y++)
        {
            int positionConstant = x + (2 - y) * 3;
            NSRect positionRect = [self rectForPosition:positionConstant];

            NSBezierPath *path = [NSBezierPath bezierPath];

            [path appendBezierPathWithRect:positionRect];
            [path setLineDash:lineDash count:2 phase:0.0];
            [path setLineJoinStyle:NSRoundLineJoinStyle];

            if (isDragging)
            {
                [path setLineDash:lineDash count:2 phase:0.0];
                [dashColor set];
                [path stroke];
            }

            // Highlight the nearest drop location.
            if (isDragging && dragDropPosition == positionConstant)
            {
                [[[NSColor blackColor] colorWithAlphaComponent:0.25] setFill];
                [path fill];
            }

            if (positionConstant == position)
            {
                path = [NSBezierPath bezierPath];

                [path appendBezierPathWithRect:[self selectedRect]];

                if (isDragging && (abs(dragOffset.x) > 2 || abs(dragOffset.y) > 2))
                {
                    NSAffineTransform *transform = [NSAffineTransform transform];
                    [transform translateXBy:dragOffset.x yBy:dragOffset.y];
                    [path transformUsingAffineTransform:transform];
                }

                [selectedColor setFill];
                [path fill];

                [path setLineDash:0 count:0 phase:0];
                [[NSColor whiteColor] set];
                [path stroke];
            }
        }
    }

    [[NSColor grayColor] set];
    [NSBezierPath strokeRect:NSInsetRect(bounds, 0.5, 0.5)];
}

@end
