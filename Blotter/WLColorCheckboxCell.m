//
//  ColorCheckboxCell.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 07.01.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>
#import "WLColorCheckboxCell.h"


@implementation WLColorCheckboxCell

+ (NSImage *)checkboxCellImageWithColor:(NSColor *)aColor state:(NSInteger)aState
{
    static NSCache *ImagesCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ImagesCache = [[NSCache alloc] init];
        ImagesCache.name = @"WLColorCheckboxCell cache";
    });

    NSDictionary *imagesPair = [ImagesCache objectForKey:aColor];
    NSImage *checkboxImage = imagesPair[@(aState)];

    if (checkboxImage == nil)
    {
        static const NSSize CheckboxSize = {.width = 14.0, .height = 14.0};

        __auto_type h = ^(NSRect aDestinationRect)
        {
            NSString *maskImageName = floor(NSAppKitVersionNumber) < NSAppKitVersionNumber10_12 ? @"checkbox-mask-10_10" : @"checkbox-mask-10_12";
            NSString *normalImageName = floor(NSAppKitVersionNumber) < NSAppKitVersionNumber10_12 ? @"checkbox-normal-10_10" : @"checkbox-normal-10_12";
            NSString *emptyImageName = floor(NSAppKitVersionNumber) < NSAppKitVersionNumber10_12 ? @"checkbox-empty-10_10" : @"checkbox-empty-10_12";

            [[NSImage imageNamed:maskImageName] drawInRect:aDestinationRect
                                                  fromRect:aDestinationRect
                                                 operation:NSCompositingOperationSourceOver
                                                  fraction:1.0];

            [aColor setFill];
            NSRectFillUsingOperation(aDestinationRect, NSCompositingOperationSourceIn);

            switch (aState)
            {
                case NSOnState:
                {
                    [[NSImage imageNamed:normalImageName] drawInRect:aDestinationRect
                                                            fromRect:aDestinationRect
                                                           operation:NSCompositingOperationSourceOver
                                                            fraction:1.0];
                    break;
                }
                case NSOffState:
                {
                    [[NSImage imageNamed:emptyImageName] drawInRect:aDestinationRect
                                                           fromRect:aDestinationRect
                                                          operation:NSCompositingOperationSourceOver
                                                           fraction:1.0];
                    break;
                }
                default:
                    break;
            }

            return YES;
        };

        checkboxImage = [NSImage imageWithSize:CheckboxSize flipped:NO drawingHandler:h];

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

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self != nil)
    {
        // NSButtonCell
        [self setButtonType:NSSwitchButton];
        [self setBackgroundColor:nil];
        self.bezelStyle = NSRegularSquareBezelStyle;
        self.gradientType = NSGradientNone;
        self.highlightsBy = NSNoCellMask;
        [self setImageDimsWhenDisabled:YES];
        self.imagePosition = NSImageOnly;
        self.imageScaling = NSImageScaleNone;
        [self setTransparent:NO];
        [self setShowsBorderOnlyWhileMouseInside:NO];
        self.showsStateBy = NSContentsCellMask;

        // NSCell
        self.alignment = NSNaturalTextAlignment;
        [self setAllowsEditingTextAttributes:NO];
        [self setAllowsMixedState:NO];
        [self setAllowsUndo:YES];
        self.backgroundStyle = NSBackgroundStyleLight;
        self.controlSize = NSSmallControlSize;
        self.controlTint = NSDefaultControlTint;
        self.focusRingType = NSFocusRingTypeDefault;
        [self setImportsGraphics:NO];
        [self setBezeled:NO];
        [self setBordered:NO];
        self.type = NSTextCellType;
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
    self.image = [[self class] checkboxCellImageWithColor:newColor state:NSOffState];
    self.alternateImage = [[self class] checkboxCellImageWithColor:newColor state:NSOnState];
}

@end
