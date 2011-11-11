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
    static dispatch_once_t onceToken;
    static NSCache *imagesCache = nil;
    dispatch_once(&onceToken, ^{
        imagesCache = [NSCache new];
        [imagesCache setName:@"WLColorCheckboxCell cache"];
    });

    NSDictionary *imagesPair = [[[imagesCache objectForKey:aColor] retain] autorelease];
    NSImage *checkboxImage = [imagesPair objectForKey:[NSNumber numberWithInteger:aState]];
    if (checkboxImage == nil)
    {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
        {
            NSRect checkboxRect = NSMakeRect(0.0f, 0.0f, 14.0f, 16.0f);
            NSImage *overlayImage = [[NSImage alloc] initWithSize:checkboxRect.size];
            [overlayImage lockFocus];
            [aColor set];
            [NSBezierPath fillRect:checkboxRect];
            [overlayImage unlockFocus];

            NSImage *colormaskImage = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"chkbxColormask_10_6"]];

            NSImage *backgroundImage = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"chkbxBackground_10_6"]];

            [colormaskImage lockFocus];
            [overlayImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceIn fraction:1.0];
            [colormaskImage unlockFocus];
            [overlayImage release];

            checkboxImage = [[[NSImage alloc] initWithSize:checkboxRect.size] autorelease];
            [checkboxImage lockFocus];
            [colormaskImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceOver fraction:1.0];
            [colormaskImage release];
            [backgroundImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceOver fraction:1.0];
            [backgroundImage release];
            if (aState == NSOnState)
            {
                NSImage *checkImage = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"chkbxCheck_10_6"]];
                [checkImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceOver fraction:1.0];
                [checkImage release];
            }
            [checkboxImage unlockFocus];
        }
        else
        {
            NSRect checkboxRect = NSMakeRect(0.0f, 0.0f, 16.0f, 16.0f);
            NSImage *overlayImage = [[NSImage alloc] initWithSize:checkboxRect.size];
            [overlayImage lockFocus];
            [[aColor colorWithAlphaComponent:0.4f] set];
            [NSBezierPath fillRect:checkboxRect];
            [overlayImage unlockFocus];

            NSImage *colormaskImage = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"chkbxColormask_10_7"]];

            [colormaskImage lockFocus];
            [overlayImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceIn fraction:1.0];
            [colormaskImage unlockFocus];
            [overlayImage release];

            checkboxImage = [[[NSImage alloc] initWithSize:checkboxRect.size] autorelease];
            [checkboxImage lockFocus];
            [colormaskImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceOver fraction:1.0];
            [colormaskImage release];
            switch (aState)
            {
                case NSOnState:
                {
                    NSImage *checkImage = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"chkbxCheck_10_7"]];
                    [checkImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceOver fraction:1.0];
                    [checkImage release];
                    break;
                }
                case NSOffState:
                {
                    NSImage *backgroundImage = [[NSImage alloc] initWithContentsOfURL:[bundle URLForImageResource:@"chkbxBackground_10_7"]];
                    [backgroundImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceOver fraction:1.0];
                    [backgroundImage release];
                    break;
                }
                default:
                    break;
            }
            [checkboxImage unlockFocus];
        }

        NSMutableDictionary *newImagesPair = [imagesCache objectForKey:aColor];
        if (newImagesPair == nil)
        {
            newImagesPair = [NSMutableDictionary dictionary];
            [imagesCache setObject:newImagesPair forKey:aColor];
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
        [self setAlignment:NSLeftTextAlignment];
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
