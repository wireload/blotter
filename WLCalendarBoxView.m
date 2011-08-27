//
//  WLCalendarBoxView.m
//  Blotter
//
//  Created by Ilya Kulakov on 26.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarBoxView.h"
#import "NSFont+WLCalendar.h"
#import "NSColor+WLCalendar.h"


@implementation WLCalendarBoxView

#pragma mark Properties
@synthesize title;
@dynamic contentView;

- (NSView *)contentView
{
    return contentView;
}

- (void)setContentView:(NSView *)newContentView
{
    [newContentView setFrame:[self _contentViewRect]];
    [newContentView setAutoresizingMask:NSViewHeightSizable];
    if (contentView != nil)
        [self replaceSubview:contentView with:newContentView];
    else
        [self addSubview:newContentView];
    contentView = newContentView;
}


#pragma mark Methods

#pragma mark Private

- (NSDictionary *)_titleAttributes
{
    NSShadow *s = [[NSShadow alloc] init];
    [s setShadowColor:[NSColor WL_tasksShadowColor]];
    [s setShadowBlurRadius:0.0f];
    // View is flipped
    [s setShadowOffset:NSMakeSize(0.0f, -1.0f)];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSFont WL_infoViewTitleFont],   NSFontAttributeName,
                                [NSColor WL_infoViewTitleColor], NSForegroundColorAttributeName,
                                s,                               NSShadowAttributeName, nil];
    [s release];
    return attributes;
}

- (NSRect)_contentViewRect
{
    NSRect bounds = [self bounds];
    return NSMakeRect(NSMinX(bounds) + 14.0f,
                      NSMinY(bounds) + 17.0f + 30.0f + 15.0f,
                      NSWidth(bounds) - 14.0f - 14.0f,
                      NSHeight(bounds) - 17.0f - 30.0f - 15.0f - 17.0f);
}


#pragma mark NSView

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    
    NSRect bounds = [self bounds];
    NSSize bottomSize = NSMakeSize(bounds.size.width, [[NSImage imageNamed:@"info-bottom"] size].height);
    NSSize topSize = NSMakeSize(bounds.size.width, [[NSImage imageNamed:@"info-top"] size].height);
    NSSize middleSize = NSMakeSize(bounds.size.width, bounds.size.height - bottomSize.height - topSize.height);
    
    static const CGFloat AlphaFraction = 0.5f;

    NSRect topFrame = NSMakeRect(NSMinX(bounds), NSMinY(bounds), topSize.width, topSize.height);
    if (NSIntersectsRect(topFrame, topFrame))
    {
        NSDrawThreePartImage(topFrame,
                             [NSImage imageNamed:@"info-top-left"],
                             [NSImage imageNamed:@"info-top"],
                             [NSImage imageNamed:@"info-top-right"],
                             NO,
                             NSCompositeSourceOver,
                             AlphaFraction,
                             YES);
    }
    
    NSRect middleFrame = NSMakeRect(NSMinX(bounds), NSMaxY(topFrame), middleSize.width, middleSize.height);
    if (NSIntersectsRect(middleFrame, dirtyRect))
        [[NSImage imageNamed:@"info-middle"] drawInRect:middleFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:AlphaFraction respectFlipped:YES hints:nil];
    
    NSRect bottomFrame = NSMakeRect(NSMinX(bounds), NSMaxY(middleFrame), bottomSize.width, bottomSize.height);
    if (NSIntersectsRect(bottomFrame, dirtyRect))
    {
        NSDrawThreePartImage(bottomFrame,
                             [NSImage imageNamed:@"info-bottom-left"],
                             [NSImage imageNamed:@"info-bottom"],
                             [NSImage imageNamed:@"info-bottom-right"],
                             NO,
                             NSCompositeSourceOver,
                             AlphaFraction,
                             YES);
    }
    
    NSRect titleRect = NSMakeRect(NSMinX(bounds) + 14.0f, NSMinY(bounds) + 17.0f, NSWidth(bounds) - 14.0f, 30.0f);
    if (NSIntersectsRect(titleRect, dirtyRect))
        [title drawInRect:titleRect withAttributes:[self _titleAttributes]];
}

- (BOOL)isFlipped
{
    return YES;
}

@end
