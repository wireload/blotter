//
//  WLGraphics.h
//  Blotter
//
//  Created by Ilya Kulakov on 10.11.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import <AppKit/AppKit.h>


NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, WLEdge)
{
    WLEdgeLeft = 0,
    WLEdgeTop = 1,
    WLEdgeRight = 2,
    WLEdgeBottom = 3,
    WLEdgeCenter = 4,

    WLEdgeTopLeft = 5,
    WLEdgeTopRight = 6,
    WLEdgeBottomLeft = 7,
    WLEdgeBottomRight = 8
};

static const WLEdge WLEdgeCount = 9;
static const WLEdge WLEdgeInvalid = NSUIntegerMax;


typedef NS_OPTIONS(NSUInteger, WLEdgeMask)
{
    WLEdgeMaskNone = 0,

    WLEdgeMaskLeft = 1ULL << WLEdgeLeft,
    WLEdgeMaskTop = 1ULL << WLEdgeTop,
    WLEdgeMaskRight = 1ULL << WLEdgeRight,
    WLEdgeMaskBottom = 1ULL << WLEdgeBottom,
    WLEdgeMaskCenter = 1ULL << WLEdgeCenter,

    WLEdgeMaskTopLeft = WLEdgeMaskTop | WLEdgeMaskLeft,
    WLEdgeMaskTopRight = WLEdgeMaskTop | WLEdgeMaskRight,
    WLEdgeMaskBottomRight = WLEdgeMaskBottom | WLEdgeMaskRight,
    WLEdgeMaskBottomLeft = WLEdgeMaskBottom | WLEdgeMaskLeft
};


extern const NSAlignmentOptions WLAlignTiebreakerInward;
extern const NSAlignmentOptions WLAlignTiebreakerOutward;

/*!
 Round rect to an integral that is a multiple of aMultiple.

 @discussion
 In addition to all NSAlignmentOptions defined in AppKit supports WLAlignTiebreakerInward and WLAlignTiebreakerOutward
 to round 0.5 either inward or outward. If unspecified, the default is to round away from zero.
 */
NSRect WLIntegralRect(NSRect aRect, NSAlignmentOptions anOptions, CGFloat aMultiple);

/*!
 Round rect with respect to its minimum and maximum sizes.

 @param aMovingEdge Edge that is moved first if rect must be resized to satisfy the constraints

 @param aMinSize Minimal size the resulting integral rect should have.
 */
NSRect WLConstrainedIntegralRect(NSRect aRect,
                                 NSAlignmentOptions anOptions,
                                 CGFloat aMultiple,
                                 NSSize aMinSize,
                                 WLEdge aMovingEdge);

void WLDrawScaledThreePartImage(NSRect frame, 
                                NSImage *startCap, 
                                NSImage *centerFill, 
                                NSImage *endCap, 
                                BOOL vertical, 
                                NSCompositingOperation op, 
                                CGFloat alphaFraction,
                                BOOL flipped);

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
                               BOOL flipped);


@interface NSImage (WLGraphics)

- (void)WL_drawScaledNinePartImageInRect:(NSRect)aDstRect
                           withCapInsets:(NSEdgeInsets)aCapInsets
                               operation:(NSCompositingOperation)anOperation
                                fraction:(CGFloat)aFraction
                          respectFlipped:(BOOL)aRespectContextIsFlipped
                                   hints:(nullable NSDictionary<NSImageHintKey, id> *)aHints;

@end


@interface NSGraphicsContext (WLGraphics)

- (NSDictionary<NSString *, id> *)WL_description;

@end


@interface NSColor (WLGraphics)

@property (class, readonly) NSColor *WL_noisePattern;

@end

NS_ASSUME_NONNULL_END
