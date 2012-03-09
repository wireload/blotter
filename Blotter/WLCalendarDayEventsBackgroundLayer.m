//
//  WLCalendarDayEventsBackgroundLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 07/03/2012.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#include <tgmath.h>
#import "WLCalendarDayEventsBackgroundLayer.h"
#import "NSColor+WLCalendar.h"
#import "NSFont+WLCalendar.h"


static const NSStringDrawingOptions _WLTitleDrawingOptions = NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine;


@implementation WLCalendarDayEventsBackgroundLayer

#pragma mark Properties
@dynamic titleFrame;
@dynamic title;
@dynamic isTitleHighlighted;


#pragma mark Methods

- (CGSize)preferredTitleFrameSizeWithBoundingSize:(CGSize)aBoundingSize
{
    return NSSizeToCGSize([self.title boundingRectWithSize:NSSizeFromCGSize(aBoundingSize)
                                                   options:_WLTitleDrawingOptions
                                                attributes:self.isTitleHighlighted ? [NSDictionary WL_highlightedTitleAttributes] : [NSDictionary WL_titleAttributes]].size);
}


#pragma mark CALayer

+ (BOOL)needsDisplayForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"titleFrame"])
        return YES;
    else if ([aKey isEqualToString:@"title"])
        return YES;
    else if ([aKey isEqualToString:@"isTitleHighlighted"])
        return YES;
    else
        return [super needsDisplayForKey:aKey];
}

+ (id)defaultValueForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"needsDisplayOnBoundsChange"])
        return [NSNumber numberWithBool:YES];
    else
        return [super defaultValueForKey:aKey];
}

- (void)drawInContext:(CGContextRef)aContext
{
    static dispatch_once_t onceToken;
    static NSGradient *WhiteToTransparentGradient = nil;
    dispatch_once(&onceToken, ^{
        WhiteToTransparentGradient = [[NSGradient alloc] initWithStartingColor:[[NSColor whiteColor] colorWithAlphaComponent:0.1]
                                                                   endingColor:[NSColor clearColor]];
    });

    NSGraphicsContext *c = [NSGraphicsContext graphicsContextWithGraphicsPort:aContext flipped:[self contentsAreFlipped]];
    [c setImageInterpolation:NSImageInterpolationHigh];
    [c setShouldAntialias:YES];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:c];

    NSRect dirtyRect = NSRectFromCGRect(CGContextGetClipBoundingBox(aContext));
#ifndef DEBUG_LAYERS
    NSSize bottomSize = NSMakeSize(self.bounds.size.width,
                                   [[NSImage imageNamed:@"day-bottom"] size].height);
    NSSize topSize = NSMakeSize(self.bounds.size.width,
                                [[NSImage imageNamed:@"day-top"] size].height);
    NSSize middleSize = NSMakeSize(self.bounds.size.width,
                                   fdim(self.bounds.size.height, bottomSize.height + topSize.height));

    NSRect topFrame = NSMakeRect(0.0,
                                 0.0,
                                 topSize.width,
                                 topSize.height);
    if (NSIntersectsRect(topFrame, dirtyRect))
    {
        NSDrawThreePartImage(topFrame,
                             [NSImage imageNamed:@"day-top-left"],
                             [NSImage imageNamed:@"day-top"],
                             [NSImage imageNamed:@"day-top-right"],
                             NO,
                             NSCompositeSourceOver,
                             1.0,
                             YES);
    }

    NSRect middleFrame = NSMakeRect(0.0,
                                    NSMaxY(topFrame),
                                    middleSize.width,
                                    middleSize.height);
    if (NSIntersectsRect(middleFrame, dirtyRect))
    {
        [(NSImage *)[NSImage imageNamed:@"day-middle-left"] drawInRect:NSMakeRect(0.0,
                                                                                  middleFrame.origin.y,
                                                                                  1.0,
                                                                                  middleFrame.size.height)
                                                              fromRect:NSZeroRect
                                                             operation:NSCompositeSourceOver
                                                              fraction:1.0
                                                        respectFlipped:YES
                                                                 hints:nil];
        [(NSImage *)[NSImage imageNamed:@"day-middle"] drawInRect:NSMakeRect(1.0,
                                                                             middleFrame.origin.y,
                                                                             fdim(middleFrame.size.width, 2.0),
                                                                             middleFrame.size.height)
                                                         fromRect:NSZeroRect
                                                        operation:NSCompositeSourceOver
                                                         fraction:1.0
                                                   respectFlipped:YES
                                                            hints:nil];
        [(NSImage *)[NSImage imageNamed:@"day-middle-right"] drawInRect:NSMakeRect(fdim(middleFrame.size.width, 1.0),
                                                                                   middleFrame.origin.y,
                                                                                   1.0,
                                                                                   middleFrame.size.height)
                                                               fromRect:NSZeroRect
                                                              operation:NSCompositeSourceOver
                                                               fraction:1.0
                                                         respectFlipped:YES
                                                                  hints:nil];
    }

    NSRect bottomFrame = NSMakeRect(0.0,
                                    NSMaxY(middleFrame),
                                    bottomSize.width,
                                    bottomSize.height);
    if (NSIntersectsRect(bottomFrame, dirtyRect))
    {
        NSDrawThreePartImage(bottomFrame,
                             [NSImage imageNamed:@"day-bottom-left"],
                             [NSImage imageNamed:@"day-bottom"],
                             [NSImage imageNamed:@"day-bottom-right"],
                             NO,
                             NSCompositeSourceOver,
                             1.0,
                             YES);
    }

    // Inset layer bounds, since images have 1px stroke.
    [WhiteToTransparentGradient drawInRect:NSInsetRect(NSRectFromCGRect(self.bounds),
                                                       1.0,
                                                       1.0)
                                     angle:90];
#endif
    if ([self.title length] > 0 && NSIntersectsRect(NSRectFromCGRect(self.titleFrame), dirtyRect))
    {
        NSDictionary *attributes = self.isTitleHighlighted ? [NSDictionary WL_highlightedTitleAttributes] : [NSDictionary WL_titleAttributes];
        // Vertically center the title.
        NSSize preferredTitleSize = [self.title boundingRectWithSize:NSSizeFromCGSize(self.titleFrame.size)
                                                        options:_WLTitleDrawingOptions
                                                     attributes:attributes].size;
        NSRect centeredFrame = NSRectFromCGRect(self.titleFrame);
        CGFloat yOffset = ceil(fdim(self.titleFrame.size.height / 2.0, preferredTitleSize.height / 2.0));
        centeredFrame.origin.y += yOffset;
        centeredFrame.size.height = fdim(centeredFrame.size.height, yOffset);
#ifdef DEBUG_LAYERS
        [[NSColor greenColor] setFill];
        NSRectFill(centeredFrame);
#endif
        [self.title drawWithRect:centeredFrame
                         options:_WLTitleDrawingOptions
                      attributes:attributes];
    }
    [NSGraphicsContext restoreGraphicsState];
}

@end


@implementation NSDictionary (WLCalendarDayEventsBackgroundLayer)

+ (NSDictionary *)WL_titleAttributes
{
    static dispatch_once_t onceToken;
    static NSDictionary *titleAttributes = nil;
    dispatch_once(&onceToken, ^{
        NSMutableParagraphStyle *p = [[NSMutableParagraphStyle alloc] init];
        [p setAlignment:NSCenterTextAlignment];
        [p setLineBreakMode:NSLineBreakByWordWrapping];
        NSShadow *s = [[NSShadow alloc] init];
        [s setShadowBlurRadius:0.0];
        [s setShadowColor:[NSColor WL_columnTitleShadowColor]];
        if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
            [s setShadowOffset:NSMakeSize(0.0, -1.0)];
        else
            [s setShadowOffset:NSMakeSize(0.0, 1.0)];
        titleAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                           (id)[NSFont WL_columnTitleFont],  NSFontAttributeName,
                           p,                                NSParagraphStyleAttributeName,
                           [NSColor whiteColor],             NSForegroundColorAttributeName,
                           s,                                NSShadowAttributeName,
                           nil];
        [s release];
        [p release];
    });
    return titleAttributes;
}

+ (NSDictionary *)WL_highlightedTitleAttributes
{
    static dispatch_once_t onceToken;
    static NSMutableDictionary *highlightedTitleAttributes = nil;
    dispatch_once(&onceToken, ^{
        NSDictionary *titleAttributes = [self WL_titleAttributes];
        highlightedTitleAttributes = [titleAttributes mutableCopy];
        [highlightedTitleAttributes setObject:(id)[NSFont WL_columnBoldTitleFont] forKey:NSFontAttributeName];
    });
    return highlightedTitleAttributes;
}

@end
