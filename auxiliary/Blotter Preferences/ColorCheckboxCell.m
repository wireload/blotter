//
//  ColorCheckboxCell.m
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 07.01.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import "ColorCheckboxCell.h"


@implementation ColorCheckboxCell

+ (NSImage *)checkboxImageCellWithColor:(NSColor *)aColor state:(NSInteger)aState {
    static NSCache *imagesCache = nil;
    if (imagesCache == nil) {
        imagesCache = [NSCache new];
        [imagesCache setName:@"CheckboxImagesCache"];
    }

    NSImage *checkboxImage = [[imagesCache objectForKey:aColor] objectForKey:[NSNumber numberWithInteger:aState]];
    if (checkboxImage == nil) {
        NSSize checkboxSize = NSMakeSize(14, 16);
        NSRect checkboxRect = NSMakeRect(0, 0, checkboxSize.width, checkboxSize.height);

        NSImage *overlayImage = [[NSImage alloc] initWithSize:checkboxSize];
        [overlayImage lockFocus];
        [aColor set];
        [NSBezierPath fillRect:checkboxRect];
        [overlayImage unlockFocus];

        NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"chkbxColormask" ofType:@"png"];
        NSImage *colormaskImage = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];

        path = [[NSBundle bundleForClass:[self class]] pathForResource:@"chkbxBackground" ofType:@"png"];
        NSImage *backgroundImage = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];

        [colormaskImage lockFocus];
        [overlayImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceIn fraction:1.0];
        [colormaskImage unlockFocus];
        [overlayImage release];

        checkboxImage = [[[NSImage alloc] initWithSize:checkboxSize] autorelease];
        [checkboxImage lockFocus];
        [colormaskImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceOver fraction:1.0];
        [backgroundImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceOver fraction:1.0];
        if (aState == NSOnState) {
            path = [[NSBundle bundleForClass:[self class]] pathForResource:@"chkbxCheck" ofType:@"png"];
            NSImage *checkImage = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
            [checkImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceOver fraction:1.0];
        }
        [checkboxImage unlockFocus];

        NSMutableDictionary *imagesPair = [imagesCache objectForKey:aColor];
        if (imagesPair == nil) {
            imagesPair = [NSMutableDictionary dictionary];
            [imagesCache setObject:imagesPair forKey:aColor];
        }
        [imagesPair setObject:checkboxImage forKey:[NSNumber numberWithInteger:aState]];
    }

    return checkboxImage;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
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

- (void)setButtonColor:(NSColor *)newColor {
    [self setImage:[[self class] checkboxImageCellWithColor:newColor state:NSOffState]];
    [self setAlternateImage:[[self class] checkboxImageCellWithColor:newColor state:NSOnState]];
}

@end
