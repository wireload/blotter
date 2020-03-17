//
//  WLGraphics.m
//  Blotter
//
//  Created by Ilya Kulakov on 10.11.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import "WLGraphics.h"


const NSAlignmentOptions WLAlignTiebreakerInward = 1ULL << 32;
const NSAlignmentOptions WLAlignTiebreakerOutward = 1ULL << 33;


void WLRecessedBoxShadow(NSRect frame)
{
    static dispatch_once_t onceToken;
    static NSImage *Images[9];
    dispatch_once(&onceToken, ^{
        Images[0] = [NSImage imageNamed:@"recessed-box-shadow-top-left"];
        Images[1] = [NSImage imageNamed:@"recessed-box-shadow-top-centre"];
        Images[2] = [NSImage imageNamed:@"recessed-box-shadow-top-right"];
        Images[3] = [NSImage imageNamed:@"recessed-box-shadow-centre-left"];
        Images[4] = [NSImage imageNamed:@"recessed-box-shadow-centre-centre"];
        Images[5] = [NSImage imageNamed:@"recessed-box-shadow-centre-right"];
        Images[6] = [NSImage imageNamed:@"recessed-box-shadow-bottom-left"];
        Images[7] = [NSImage imageNamed:@"recessed-box-shadow-bottom-centre"];
        Images[8] = [NSImage imageNamed:@"recessed-box-shadow-bottom-right"];
    });

    [NSGraphicsContext saveGraphicsState];
    NSDrawNinePartImage(frame,
                        Images[0],
                        Images[1],
                        Images[2],
                        Images[3],
                        Images[4],
                        Images[5],
                        Images[6],
                        Images[7],
                        Images[8],
                        NSCompositeSourceOver,
                        1.0,
                        NSGraphicsContext.currentContext.flipped);
    [NSGraphicsContext restoreGraphicsState];
}

NSRect WLIntegralRect(NSRect aRect, NSAlignmentOptions anOptions, CGFloat aMultiple)
{
    static const CGFloat Tolerance = 1e-6;

    NSCParameterAssert((anOptions & (WLAlignTiebreakerInward | WLAlignTiebreakerOutward)) != (WLAlignTiebreakerInward | WLAlignTiebreakerOutward));

    NSRect intRect = NSMakeRect(NSMinX(aRect) / aMultiple,
                                NSMinY(aRect) / aMultiple,
                                NSWidth(aRect) / aMultiple,
                                NSHeight(aRect) / aMultiple);

    if (anOptions & NSAlignMinXNearest && anOptions & (WLAlignTiebreakerInward | WLAlignTiebreakerOutward))
    {
        CGFloat minXInt;
        CGFloat minXFrac = modf(NSMinX(intRect), &minXInt);
        if (fabs(minXFrac - 0.5) < Tolerance)
            anOptions ^= NSAlignMinXNearest | ((anOptions & WLAlignTiebreakerInward) ? NSAlignMinXInward : NSAlignMinXOutward);
    }

    if (anOptions & NSAlignMinYNearest && anOptions & (WLAlignTiebreakerInward | WLAlignTiebreakerOutward))
    {
        CGFloat minYInt;
        CGFloat minYFrac = modf(NSMinY(intRect), &minYInt);
        if (fabs(minYFrac - 0.5) < Tolerance)
            anOptions ^= NSAlignMinYNearest | ((anOptions & WLAlignTiebreakerInward) ? NSAlignMinYInward : NSAlignMinYOutward);
    }

    if (anOptions & NSAlignMaxXNearest && anOptions & (WLAlignTiebreakerInward | WLAlignTiebreakerOutward))
    {
        CGFloat maxXInt;
        CGFloat maxXFrac = modf(NSMaxX(intRect), &maxXInt);
        if (fabs(maxXFrac - 0.5) < Tolerance)
            anOptions ^= NSAlignMaxXNearest | ((anOptions & WLAlignTiebreakerInward) ? NSAlignMaxXInward : NSAlignMaxXOutward);
    }

    if (anOptions & NSAlignMaxYNearest && anOptions & (WLAlignTiebreakerInward | WLAlignTiebreakerOutward))
    {
        CGFloat maxYInt;
        CGFloat maxYFrac = modf(NSMaxY(intRect), &maxYInt);
        if (fabs(maxYFrac - 0.5) < Tolerance)
            anOptions ^= NSAlignMaxYNearest | ((anOptions & WLAlignTiebreakerInward) ? NSAlignMaxYInward : NSAlignMaxYOutward);
    }

    if (anOptions & NSAlignWidthNearest && anOptions & (WLAlignTiebreakerInward | WLAlignTiebreakerOutward))
    {
        CGFloat widthInt;
        CGFloat widthFrac = modf(NSWidth(intRect), &widthInt);
        if (fabs(widthFrac - 0.5) < Tolerance)
            anOptions ^= NSAlignWidthNearest | ((anOptions & WLAlignTiebreakerInward) ? NSAlignWidthInward : NSAlignWidthOutward);
    }

    if (anOptions & NSAlignHeightNearest && anOptions & (WLAlignTiebreakerInward | WLAlignTiebreakerOutward))
    {
        CGFloat heightInt;
        CGFloat heightFrac = modf(NSWidth(intRect), &heightInt);
        if (fabs(heightFrac - 0.5) < Tolerance)
            anOptions ^= NSAlignHeightNearest | ((anOptions & WLAlignTiebreakerInward) ? NSAlignHeightInward : NSAlignHeightOutward);
    }

    intRect = NSIntegralRectWithOptions(intRect, anOptions);
    return NSMakeRect(NSMinX(intRect) * aMultiple,
                      NSMinY(intRect) * aMultiple,
                      NSWidth(intRect) * aMultiple,
                      NSHeight(intRect) * aMultiple);
}

NSRect WLConstrainedIntegralRect(NSRect aRect, NSAlignmentOptions anOptions, CGFloat aMultiple, NSSize aMinSize, WLEdge aMovingEdge)
{
    __block NSRect intRect = WLIntegralRect(aRect, anOptions, aMultiple);

    BOOL shouldAdjustWidth = NO;
    BOOL shouldAdjustHeight = NO;
    if ((shouldAdjustWidth = NSWidth(intRect) < aMinSize.width) || (shouldAdjustHeight = NSHeight(intRect) < aMinSize.height))
    {
        // intRect is integral and aligned perfectly but too small
        // It needs to be resized with respect to the edge being stationary (i.e. edge which position is unchanged)

        __block NSAlignmentOptions resizeOptions = anOptions & NSAlignRectFlipped;

        __auto_type KeepLeft = ^{
            if (shouldAdjustWidth)
            {
                resizeOptions |= NSAlignMinXNearest | NSAlignWidthOutward;
                intRect.size.width = aMinSize.width;
            }
            else
                resizeOptions |= NSAlignMinXNearest | NSAlignMaxXNearest;
        };

        __auto_type KeepMidX = ^{
            if (shouldAdjustWidth)
            {
                resizeOptions |= NSAlignMinXOutward | NSAlignMaxXOutward;
                intRect.origin.x = NSMidX(intRect) - aMinSize.width / 2.0;
                intRect.size.width = aMinSize.width;
            }
            else
                resizeOptions |= NSAlignMinXNearest | NSAlignMaxXNearest;
        };

        __auto_type KeepRight = ^{
            if (shouldAdjustWidth)
            {
                resizeOptions |= NSAlignMaxXNearest | NSAlignWidthOutward;
                intRect.origin.x = NSMaxX(intRect) - aMinSize.width;
                intRect.size.width = aMinSize.width;
            }
            else
                resizeOptions |= NSAlignMinXNearest | NSAlignMaxXNearest;
        };
        __auto_type KeepTop = ^{
            if (shouldAdjustHeight)
            {
                if (anOptions & NSAlignRectFlipped)
                {
                    resizeOptions |= NSAlignMinYNearest | NSAlignHeightOutward;
                    intRect.size.height = aMinSize.height;
                }
                else
                {
                    resizeOptions |= NSAlignMaxYNearest | NSAlignHeightOutward;
                    intRect.origin.y = NSMaxY(intRect) - aMinSize.height;
                    intRect.size.height = aMinSize.height;
                }
            }
            else
                resizeOptions |= NSAlignMinYNearest | NSAlignMaxYNearest;
        };

        __auto_type KeepMidY = ^{
            if (shouldAdjustHeight)
            {
                resizeOptions |= NSAlignMinYOutward | NSAlignMaxYOutward;
                intRect.origin.y = NSMidY(intRect) - aMinSize.height / 2.0;
                intRect.size.height = aMinSize.height;
            }
            else
                resizeOptions |= NSAlignMinYNearest | NSAlignMaxYNearest;
        };

        __auto_type KeepBottom = ^{
            if (shouldAdjustHeight)
            {
                if (anOptions & NSAlignRectFlipped)
                {
                    resizeOptions |= NSAlignMaxYNearest | NSAlignHeightOutward;
                    intRect.origin.y = NSMaxY(intRect) - aMinSize.height;
                    intRect.size.height = aMinSize.height;
                }
                else
                {
                    resizeOptions |= NSAlignMinYNearest | NSAlignHeightOutward;
                    intRect.size.height = aMinSize.height;
                }
            }
            else
                resizeOptions |= NSAlignMinYNearest | NSAlignMaxYNearest;
        };

        switch (aMovingEdge)
        {
            case WLEdgeLeft:
                KeepRight();
                KeepMidY();
                break;
            case WLEdgeTopLeft:
                KeepRight();
                KeepBottom();
                break;
            case WLEdgeTop:
                KeepMidX();
                KeepBottom();
                break;
            case WLEdgeTopRight:
                KeepLeft();
                KeepBottom();
                break;
            case WLEdgeRight:
                KeepLeft();
                KeepMidY();
                break;
            case WLEdgeBottomRight:
                KeepLeft();
                KeepTop();
                break;
            case WLEdgeBottom:
                KeepMidX();
                KeepTop();
                break;
            case WLEdgeBottomLeft:
                KeepRight();
                KeepTop();
                break;
            case WLEdgeCenter:
                KeepMidX();
                KeepMidY();
                break;
        }

        intRect = WLIntegralRect(intRect, resizeOptions, aMultiple);
    }

    return intRect;
}

#define NSRectFromSize(size) (NSMakeRect(0, 0, (size).width, (size).height))

void WLDrawScaledThreePartImage(NSRect frame,
                                NSImage *startCap,
                                NSImage *centerFill,
                                NSImage *endCap,
                                BOOL vertical,
                                NSCompositingOperation op,
                                CGFloat alphaFraction,
                                BOOL flipped)
{
    BOOL matchesOnlyOnBestFittingAxisCenterFill = centerFill.matchesOnlyOnBestFittingAxis;
    [centerFill setMatchesOnlyOnBestFittingAxis:YES];

    NSSize startSize = startCap.size;
    NSSize endSize = endCap.size;
    CGFloat width = startSize.width;
    CGFloat startLength = vertical ? startSize.height : startSize.width;
    CGFloat endLength = vertical ? endSize.height : endSize.width;

    CGFloat capAxisLength = startLength + endLength;
    CGFloat excess = vertical ? capAxisLength - frame.size.height : capAxisLength - frame.size.width;
    CGFloat startOffset = 0;
    CGFloat endOffset = 0;

    if (excess > 0) {
        startLength -= floor(excess / 2.0);
        endOffset = ceil(excess / 2.0);
        endLength -= endOffset;
    }

    CGFloat endPosition = 0;
    CGFloat startPosition = 0;
    CGFloat midLength = 0;
    CGFloat midPosition = 0;

    if (vertical) {
        if (flipped)
        {
            endPosition = frame.size.height - endLength + endOffset;
            startPosition = 0;
            midPosition = 0 + startLength;
            midLength = endPosition - startLength;
        } else {
            startPosition = frame.size.height - startLength + startOffset;
            endPosition = 0;
            midPosition = 0 + endLength;
            midLength = startPosition - midPosition;
        }
    } else {
        startPosition = 0;
        endPosition = frame.size.width - endLength + endOffset;
        midPosition = 0 + startLength;
        midLength = endPosition - midPosition;
    }

    BOOL drawMiddle = midLength > 0;

    if (vertical)
    {
        [startCap drawInRect:NSMakeRect(0, startPosition, width, startLength)
                    fromRect:NSMakeRect(0, flipped ? startOffset : 0, width, startLength)
                   operation:op
                    fraction:alphaFraction
              respectFlipped:YES
                       hints:nil];

        if (drawMiddle)
        {
            [centerFill drawInRect:NSMakeRect(0, midPosition, width, midLength)
                          fromRect:NSMakeRect(0, flipped ? centerFill.size.height : 0, width, centerFill.size.height)
                         operation:op
                          fraction:alphaFraction
                    respectFlipped:YES
                             hints:nil];
        }

        [endCap drawInRect:NSMakeRect(0, endPosition, width, endLength)
                  fromRect:NSMakeRect(0, flipped ? endOffset : 0, width, endLength)
                 operation:op
                  fraction:alphaFraction
            respectFlipped:YES
                     hints:nil];
    } else {
        [startCap drawInRect:NSMakeRect(startPosition, 0, startLength, startSize.height)
                    fromRect:NSMakeRect(0, 0, startLength, startSize.height)
                   operation:op
                    fraction:alphaFraction
              respectFlipped:YES
                       hints:nil];

        if (drawMiddle)
        {
            [centerFill drawInRect:NSMakeRect(midPosition, 0, midLength, startSize.height)
                          fromRect:NSMakeRect(0, 0, centerFill.size.width, startSize.height)
                         operation:op
                          fraction:alphaFraction
                    respectFlipped:YES
                             hints:nil];
        }

        [endCap drawInRect:NSMakeRect(endPosition, 0, endLength, startSize.height)
                  fromRect:NSMakeRect(0, 0, endLength, startSize.height)
                 operation:op
                  fraction:alphaFraction
            respectFlipped:YES
                     hints:nil];
    }

    centerFill.matchesOnlyOnBestFittingAxis = matchesOnlyOnBestFittingAxisCenterFill;
}


/**
 Like NSDrawNinePartImage but scale the middle parts instead of tiling them. This allows some simple gradients
 from edge to edge as long as the detail is such that it scales up and down well with bilinear filtering.
 */
void WLDrawScaledNinePartImage(NSRect bounds,
                               NSImage *topLeftCorner,
                               NSImage *topEdgeFill,
                               NSImage *topRightCorner,
                               NSImage *leftEdgeFill,
                               NSImage *centerFill,
                               NSImage *rightEdgeFill,
                               NSImage *bottomLeftCorner,
                               NSImage *bottomEdgeFill,
                               NSImage *bottomRightCorner,
                               NSCompositingOperation op,
                               CGFloat alphaFraction,
                               BOOL flipped)
{
    BOOL matchesOnlyOnBestFittingAxisTopEdgeFill = topEdgeFill.matchesOnlyOnBestFittingAxis;
    BOOL matchesOnlyOnBestFittingAxisLeftEdgeFill = leftEdgeFill.matchesOnlyOnBestFittingAxis;
    BOOL matchesOnlyOnBestFittingAxisCenterFill = centerFill.matchesOnlyOnBestFittingAxis;
    BOOL matchesOnlyOnBestFittingAxisRightEdgeFill = rightEdgeFill.matchesOnlyOnBestFittingAxis;
    BOOL matchesOnlyOnBestFittingAxisBottomEdgeFill = bottomEdgeFill.matchesOnlyOnBestFittingAxis;

    [topEdgeFill setMatchesOnlyOnBestFittingAxis:YES];
    [leftEdgeFill setMatchesOnlyOnBestFittingAxis:YES];
    [centerFill setMatchesOnlyOnBestFittingAxis:YES];
    [rightEdgeFill setMatchesOnlyOnBestFittingAxis:YES];
    [bottomEdgeFill setMatchesOnlyOnBestFittingAxis:YES];

    NSSize topLeftSize = topLeftCorner.size;
    NSSize bottomRightSize = bottomRightCorner.size;

    // If we are drawing in an area in which the corner parts don't fit, remove pixels
    // from the centre instead of from the edges (and avoid overlapping). This looks a
    // lot better when a border style 9-part image shrinks, assuming the top and bottom
    // and left/right are symmetrical and can fit together at smaller sizes. In particular
    // this is true for your layout views in the layout preferences.
    CGFloat excessWidth = topLeftSize.width + bottomRightSize.width - bounds.size.width;
    CGFloat excessHeight = topLeftSize.height + bottomRightSize.height - bounds.size.height;
    NSPoint topLeftOffset = NSMakePoint(0, 0);
    NSPoint bottomRightOffset = NSMakePoint(0, 0);

    if (excessWidth > 0) {
        topLeftSize.width -= floor(excessWidth / 2.0);
        bottomRightOffset.x = ceil(excessWidth / 2.0);
        bottomRightSize.width -= bottomRightOffset.x;
    }

    if (excessHeight > 0) {
        topLeftOffset.y = floor(excessHeight / 2.0);;
        topLeftSize.height -= topLeftOffset.y;
        bottomRightOffset.y = ceil(excessHeight / 2.0);
        bottomRightSize.height -= bottomRightOffset.y;
    }

    CGFloat leftX = 0;
    CGFloat midX = topLeftSize.width;
    CGFloat rightX = bounds.size.width - bottomRightSize.width;
    CGFloat midWidth = rightX - midX;

    CGFloat bottomY = flipped ? bounds.size.height - bottomRightSize.height : 0;
    CGFloat midY = flipped ? topLeftSize.height : bottomRightSize.height;
    CGFloat topY = flipped ? 0 : bounds.size.height - topLeftSize.height;
    CGFloat midHeight = flipped ? bottomY - midY : topY - midY;

    BOOL    drawMiddleX = midWidth > 0;
    BOOL    drawMiddleY = midHeight > 0;

    [topLeftCorner drawInRect:NSMakeRect(leftX, topY, topLeftSize.width, topLeftSize.height)
                     fromRect:NSMakeRect(0, flipped ? topLeftOffset.y : 0, topLeftSize.width, topLeftSize.height)
                    operation:op
                     fraction:alphaFraction
               respectFlipped:YES
                        hints:nil];

    if (drawMiddleX)
        [topEdgeFill drawInRect:NSMakeRect(midX, topY, midWidth, topLeftSize.height)
                       fromRect:NSMakeRect(0, flipped ? topLeftOffset.y : 0, topEdgeFill.size.width, topLeftSize.height)
                      operation:op
                       fraction:alphaFraction
                 respectFlipped:YES
                          hints:nil];

    [topRightCorner drawInRect:NSMakeRect(rightX, topY, bottomRightSize.width, topLeftSize.height)
                      fromRect:NSMakeRect(bottomRightOffset.x, flipped ? topLeftOffset.y : 0, bottomRightSize.width, topLeftSize.height)
                     operation:op
                      fraction:alphaFraction
                respectFlipped:YES
                         hints:nil];

    if (drawMiddleY)
    {
        [leftEdgeFill drawInRect:NSMakeRect(leftX, midY, topLeftSize.width, midHeight)
                        fromRect:NSZeroRect
                       operation:op
                        fraction:alphaFraction
                  respectFlipped:YES
                           hints:nil];
        if (drawMiddleX)
            [centerFill drawInRect:NSMakeRect(midX, midY, midWidth, midHeight)
                          fromRect:NSZeroRect
                         operation:op
                          fraction:alphaFraction
                    respectFlipped:YES
                             hints:nil];
        [rightEdgeFill drawInRect:NSMakeRect(rightX, midY, bottomRightSize.width, midHeight)
                         fromRect:NSZeroRect
                        operation:op
                         fraction:alphaFraction
                   respectFlipped:YES
                            hints:nil];
    }

    [bottomLeftCorner drawInRect:NSMakeRect(leftX, bottomY, topLeftSize.width, bottomRightSize.height)
                        fromRect:NSMakeRect(0, !flipped ? bottomRightOffset.y : 0, topLeftSize.width, bottomRightSize.height)
                       operation:op
                        fraction:alphaFraction
                  respectFlipped:YES
                           hints:nil];

    if (drawMiddleX)
        [bottomEdgeFill drawInRect:NSMakeRect(midX, bottomY, midWidth, bottomRightSize.height)
                          fromRect:NSMakeRect(0, !flipped ? bottomRightOffset.y : 0, bottomEdgeFill.size.width, bottomRightSize.height)
                         operation:op
                          fraction:alphaFraction
                    respectFlipped:YES
                             hints:nil];

    [bottomRightCorner drawInRect:NSMakeRect(rightX, bottomY, bottomRightSize.width, bottomRightSize.height)
                         fromRect:NSMakeRect(bottomRightOffset.x, !flipped ? bottomRightOffset.y : 0, bottomRightSize.width, bottomRightSize.height)
                        operation:op
                         fraction:alphaFraction
                   respectFlipped:YES
                            hints:nil];

    topEdgeFill.matchesOnlyOnBestFittingAxis = matchesOnlyOnBestFittingAxisTopEdgeFill;
    leftEdgeFill.matchesOnlyOnBestFittingAxis = matchesOnlyOnBestFittingAxisLeftEdgeFill;
    centerFill.matchesOnlyOnBestFittingAxis = matchesOnlyOnBestFittingAxisCenterFill;
    rightEdgeFill.matchesOnlyOnBestFittingAxis = matchesOnlyOnBestFittingAxisRightEdgeFill;
    bottomEdgeFill.matchesOnlyOnBestFittingAxis = matchesOnlyOnBestFittingAxisBottomEdgeFill;
}

#undef NSRectFromSize
