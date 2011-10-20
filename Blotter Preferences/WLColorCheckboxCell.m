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

    NSImage *checkboxImage = [[[[imagesCache objectForKey:aColor] objectForKey:[NSNumber numberWithInteger:aState]] retain] autorelease];
    if (checkboxImage == nil)
    {
        if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_6)
        {
            NSRect checkboxRect = NSMakeRect(0.0f, 0.0f, 14.0f, 16.0f);
            NSImage *overlayImage = [[NSImage alloc] initWithSize:checkboxRect.size];
            [overlayImage lockFocus];
            [aColor set];
            [NSBezierPath fillRect:checkboxRect];
            [overlayImage unlockFocus];
            
            NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"chkbxColormask_10_6" ofType:@"png"];
            NSImage *colormaskImage = [[NSImage alloc] initWithContentsOfFile:path];
            
            path = [[NSBundle bundleForClass:[self class]] pathForResource:@"chkbxBackground_10_6" ofType:@"png"];
            NSImage *backgroundImage = [[NSImage alloc] initWithContentsOfFile:path];
            
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
            if (aState == NSOnState) {
                path = [[NSBundle bundleForClass:[self class]] pathForResource:@"chkbxCheck_10_6" ofType:@"png"];
                NSImage *checkImage = [[NSImage alloc] initWithContentsOfFile:path];
                [checkImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceOver fraction:1.0];
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
            
            NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"chkbxColormask_10_7" ofType:@"png"];
            NSImage *colormaskImage = [[NSImage alloc] initWithContentsOfFile:path];
            
            [colormaskImage lockFocus];
            [overlayImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceIn fraction:1.0];
            [colormaskImage unlockFocus];
            [overlayImage release];
            
            checkboxImage = [[[NSImage alloc] initWithSize:checkboxRect.size] autorelease];
            [checkboxImage lockFocus];
            [colormaskImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceOver fraction:1.0];
            [colormaskImage release];
            switch (aState) {
                case NSOnState:
                    path = [[NSBundle bundleForClass:[self class]] pathForResource:@"chkbxCheck_10_7" ofType:@"png"];
                    NSImage *checkImage = [[NSImage alloc] initWithContentsOfFile:path];
                    [checkImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceOver fraction:1.0];
                    [checkImage release];
                    break;
                case NSOffState:
                    path = [[NSBundle bundleForClass:[self class]] pathForResource:@"chkbxBackground_10_7" ofType:@"png"];
                    NSImage *backgroundImage = [[NSImage alloc] initWithContentsOfFile:path];
                    [backgroundImage drawInRect:checkboxRect fromRect:checkboxRect operation:NSCompositeSourceOver fraction:1.0];
                    [backgroundImage release];
                    break;
                default:
                    break;
            }
            [checkboxImage unlockFocus];
        }

        NSMutableDictionary *imagesPair = [imagesCache objectForKey:aColor];
        if (imagesPair == nil) {
            imagesPair = [NSMutableDictionary dictionary];
            [imagesCache setObject:imagesPair forKey:aColor];
        }
        [imagesPair setObject:checkboxImage forKey:[NSNumber numberWithInteger:aState]];
    }
    return checkboxImage;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
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
