//
//  ColorCheckboxCell.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 07.01.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import "WLColorCheckboxCell.h"


@implementation WLColorCheckboxCell

+ (NSImage *)checkboxCellImageWithColor:(NSColor *)aColor state:(NSInteger)aState
{
    static dispatch_once_t OnceToken;
    static NSCache *ImagesCache = nil;
    dispatch_once(&OnceToken, ^{
        ImagesCache = [NSCache new];
        [ImagesCache setName:@"WLColorCheckboxCell cache"];
    });

    NSDictionary *imagesPair = [ImagesCache objectForKey:aColor];
    NSImage *checkboxImage = [imagesPair objectForKey:[NSNumber numberWithInteger:aState]];

    if (!checkboxImage)
    {
        if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
        {
            NSRect checkboxRect = NSMakeRect(0.0, 0.0, 14.0, 16.0);

            NSImage *overlayImage = [[NSImage alloc] initWithSize:checkboxRect.size];
            [overlayImage lockFocus];
            [aColor setFill];
            NSRectFillUsingOperation(checkboxRect, NSCompositeSourceOver);
            [NSBezierPath fillRect:checkboxRect];
            [overlayImage unlockFocus];

            NSImage *colormaskImage = [[NSImage imageNamed:@"checkbox-colormask-10_6"] copy];
            [colormaskImage lockFocus];
            [overlayImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceIn fraction:1.0];
            [colormaskImage unlockFocus];

            NSImage *backgroundImage = [NSImage imageNamed:@"checkbox-background-10_6"];
            checkboxImage = [[NSImage alloc] initWithSize:checkboxRect.size];
            [checkboxImage lockFocus];
            [colormaskImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceOver fraction:1.0];
            [backgroundImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceOver fraction:1.0];

            if (aState == NSOnState)
            {
                NSImage *checkImage = [NSImage imageNamed:@"checkbox-check-10_6"];
                [checkImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceOver fraction:1.0];
            }

            [checkboxImage unlockFocus];
        }
        else
        {
            NSRect checkboxRect = NSMakeRect(0.0, 0.0, 16.0, 16.0);

            NSImage *overlayImage = [[NSImage alloc] initWithSize:checkboxRect.size];
            [overlayImage lockFocus];
            [[aColor colorWithAlphaComponent:0.4] set];
            [NSBezierPath fillRect:checkboxRect];
            [overlayImage unlockFocus];

            NSImage *colormaskImage = [[NSImage imageNamed:@"checkbox-colormask-10_7"] copy];
            [colormaskImage lockFocus];
            [overlayImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceIn fraction:1.0];
            [colormaskImage unlockFocus];

            checkboxImage = [[NSImage alloc] initWithSize:checkboxRect.size];
            [checkboxImage lockFocus];
            [colormaskImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceOver fraction:1.0];
            switch (aState)
            {
                case NSOnState:
                {
                    NSImage *checkImage = [NSImage imageNamed:@"checkbox-check-10_7"];
                    [checkImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceOver fraction:1.0];
                    break;
                }
                case NSOffState:
                {
                    NSImage *backgroundImage = [NSImage imageNamed:@"checkbox-background-10_7"];
                    [backgroundImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceOver fraction:1.0];
                    break;
                }
                default:
                    break;
            }
            [checkboxImage unlockFocus];
        }

        NSMutableDictionary *newImagesPair = [ImagesCache objectForKey:aColor];
        if (newImagesPair == nil)
        {
            newImagesPair = [NSMutableDictionary dictionary];
            [ImagesCache setObject:newImagesPair forKey:aColor];
        }
        [newImagesPair setObject:checkboxImage forKey:[NSNumber numberWithInteger:aState]];
    }
    return checkboxImage;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self != nil)
    {
        // NSButtonCell
        [self setButtonType:NSSwitchButton];
        [self setBackgroundColor:nil];
        [self setBezelStyle:NSRegularSquareBezelStyle];
        [self setGradientType:NSGradientNone];
        [self setHighlightsBy:NSNoCellMask];
        [self setImageDimsWhenDisabled:YES];
        [self setImagePosition:NSImageOnly];
        [self setImageScaling:NSImageScaleNone];
        [self setTransparent:NO];
        [self setShowsBorderOnlyWhileMouseInside:NO];
        [self setShowsStateBy:NSContentsCellMask];

        // NSCell
        [self setAlignment:NSNaturalTextAlignment];
        [self setAllowsEditingTextAttributes:NO];
        [self setAllowsMixedState:NO];
        [self setAllowsUndo:YES];
        [self setBackgroundStyle:NSBackgroundStyleLight];
        [self setControlSize:NSSmallControlSize];
        [self setControlTint:NSDefaultControlTint];
        [self setFocusRingType:NSFocusRingTypeDefault];
        [self setImportsGraphics:NO];
        [self setBezeled:NO];
        [self setBordered:NO];
        [self setType:NSTextCellType];
        [self setShowsFirstResponder:NO];
        [self setSendsActionOnEndEditing:NO];
        [self setRefusesFirstResponder:NO];
        [self setSelectable:NO];
        [self setScrollable:NO];
        [self setEditable:NO];
        [self setContinuous:NO];
        [self setEnabled:YES];

        [self setButtonColor:[NSColor clearColor]];
    }
    return self;
}

- (void)setButtonColor:(NSColor *)newColor
{
    [self setImage:[[self class] checkboxCellImageWithColor:newColor state:NSOffState]];
    [self setAlternateImage:[[self class] checkboxCellImageWithColor:newColor state:NSOnState]];
}

@end
