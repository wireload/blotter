//
//  CATextLayer+WLStringSize.m
//  Blotter
//
//  Created by Ilya Kulakov on 08.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <objc/runtime.h>
#import "CATextLayer+WLStringSize.h"


@implementation CATextLayer (WLStringSize)

- (CGFloat)WL_maxStringHeightForWidth:(CGFloat)width {
    NSAttributedString *string = nil;
    if ([self.string isKindOfClass:[NSAttributedString class]])
        string = self.string;
    else
    {
        NSString *fontName = nil;
        CFTypeID fontType = CFGetTypeID(self.font);
        if (fontType == CTFontGetTypeID())
            fontName = [(id)CTFontCopyName(self.font, kCTFontFamilyNameKey) autorelease];
        else if (fontType == CGFontGetTypeID())
            fontName = [(id)CGFontCopyFullName((CGFontRef)self.font) autorelease];
        else if (object_getClass(self.font) == [NSFont class])
            fontName = [(NSFont *)self.font fontName];
        NSFont *stringFont = [NSFont fontWithName:fontName size:self.fontSize];
        NSDictionary *attributes = [NSDictionary dictionaryWithObject:stringFont forKey:NSFontAttributeName];
        string = [[[NSAttributedString alloc] initWithString:self.string attributes:attributes] autorelease];
    }
    // http://rhult.github.com/height-for-width-catextlayer.html
    CTTypesetterRef typesetter = CTTypesetterCreateWithAttributedString((CFAttributedStringRef)string);

    CFIndex offset = 0, length;
    CGFloat y = 0;
    do {
        length = CTTypesetterSuggestLineBreak(typesetter, offset, width);
        CTLineRef line = CTTypesetterCreateLine(typesetter, CFRangeMake(offset, length));

        CGFloat ascent, descent, leading;
        CTLineGetTypographicBounds(line, &ascent, &descent, &leading);

        CFRelease(line);

        offset += length;
        y += ascent + descent + leading;
    } while (offset < [string length]);

    CFRelease(typesetter);

    return ceil(y);
}

@end
