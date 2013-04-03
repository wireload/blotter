//
//  ColorCheckboxCell.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 07.01.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>
#import <WLFoundation/NSImage+WLHiDPIDrawing.h>
#import "WLColorCheckboxCell.h"


@implementation WLColorCheckboxCell

+ (NSImage *)checkboxCellImageWithColor:(NSColor *)aColor state:(NSInteger)aState
{
    static dispatch_once_t onceToken;
    static NSCache *ImagesCache = nil;
    dispatch_once(&onceToken, ^{
        ImagesCache = [[NSCache alloc] init];
        [ImagesCache setName:@"WLColorCheckboxCell cache"];
    });

    NSDictionary *imagesPair = [ImagesCache objectForKey:aColor];
    NSImage *checkboxImage = imagesPair[@(aState)];

    if (checkboxImage == nil)
    {
        if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
        {
            static const NSSize CheckboxSize = {.width = 14.0, .height = 16.0};

            WLImageDrawingHandler h = ^(NSRect aDestinationRect)
            {
                [[NSImage imageNamed:@"checkbox-colormask-10_6"] drawInRect:aDestinationRect
                                                                   fromRect:aDestinationRect
                                                                  operation:NSCompositeSourceOver
                                                                   fraction:1.0];

                [aColor setFill];
                NSRectFillUsingOperation(aDestinationRect, NSCompositeSourceIn);
                [NSBezierPath fillRect:aDestinationRect];

                [[NSImage imageNamed:@"checkbox-background-10_6"] drawInRect:aDestinationRect
                                                                    fromRect:aDestinationRect
                                                                   operation:NSCompositeSourceOver
                                                                    fraction:1.0];

                if (aState == NSOnState)
                {
                    [[NSImage imageNamed:@"checkbox-check-10_6"] drawInRect:aDestinationRect
                                                                   fromRect:aDestinationRect
                                                                  operation:NSCompositeSourceOver
                                                                   fraction:1.0];
                }

                return YES;
            };

            checkboxImage = [NSImage WL_imageWithSize:CheckboxSize flipped:NO drawingHandler:h];
        }
        else
        {
            static const NSSize CheckboxSize = {.width = 16.0, .height = 16.0};

            WLImageDrawingHandler h = ^(NSRect aDestinationRect)
            {

                [[NSImage imageNamed:@"checkbox-colormask-10_7"] drawInRect:aDestinationRect
                                                                   fromRect:aDestinationRect
                                                                  operation:NSCompositeSourceOver
                                                                   fraction:1.0];

                [NSGraphicsContext saveGraphicsState];
                [[aColor colorWithAlphaComponent:0.4] set];
                [[NSGraphicsContext currentContext] setCompositingOperation:NSCompositeSourceIn];
                [NSBezierPath fillRect:aDestinationRect];
                [NSGraphicsContext restoreGraphicsState];

                switch (aState)
                {
                    case NSOnState:
                    {
                        [[NSImage imageNamed:@"checkbox-check-10_7"] drawInRect:aDestinationRect
                                                                       fromRect:aDestinationRect
                                                                      operation:NSCompositeSourceOver
                                                                       fraction:1.0];
                        break;
                    }
                    case NSOffState:
                    {
                        [[NSImage imageNamed:@"checkbox-background-10_7"] drawInRect:aDestinationRect
                                                                            fromRect:aDestinationRect
                                                                           operation:NSCompositeSourceOver
                                                                            fraction:1.0];
                        break;
                    }
                    default:
                        break;
                }

                return YES;
            };

            checkboxImage = [NSImage WL_imageWithSize:CheckboxSize flipped:NO drawingHandler:h];
        }

        NSMutableDictionary *newImagesPair = [ImagesCache objectForKey:aColor];

        if (newImagesPair == nil)
        {
            newImagesPair = [NSMutableDictionary dictionary];
            [ImagesCache setObject:newImagesPair forKey:aColor];
        }

        newImagesPair[@(aState)] = checkboxImage;
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
