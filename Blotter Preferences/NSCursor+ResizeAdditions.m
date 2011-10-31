//
//  NSCursor+ResizeAdditions.m
//  Blotter Preferences
//
//  Created by Alexander Ljungberg on 31/10/2011.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import "NSCursor+ResizeAdditions.h"
#import "GeneralPrefController.h"

static NSCursor *_upLeftCursor = nil;
static NSCursor *_upRightCursor = nil;
static NSCursor *_downLeftCursor = nil;
static NSCursor *_downRightCursor = nil;

@implementation NSCursor (ResizeAdditions)

+ (NSCursor *)cursorFromImage:(NSString *)filename
{
    NSString *path = [[NSBundle bundleForClass:[GeneralPrefController class]] pathForResource:filename ofType:@"png"];
    NSImage *cursorImage = [[NSImage alloc] initWithContentsOfFile:path];
    NSCursor *result = [[NSCursor alloc] initWithImage:cursorImage hotSpot:NSMakePoint([cursorImage size].width / 2, [cursorImage size].height / 2)];
    [cursorImage release];
    return [result autorelease];
}

+ (NSCursor *)WL_resizeUpLeftCursor {
    if (_upLeftCursor == nil) {
        _upLeftCursor = [[self cursorFromImage:@"Resize-Cursor-Up-Left"] retain];
    }
    return _upLeftCursor;    
}

+ (NSCursor *)WL_resizeUpRightCursor {
    if (_upRightCursor == nil) {
        _upRightCursor = [[self cursorFromImage:@"Resize-Cursor-Up-Right"] retain];
    }
    return _upRightCursor;    
}

+ (NSCursor *)WL_resizeDownLeftCursor {
    if (_downLeftCursor == nil) {
        _downLeftCursor = [[self cursorFromImage:@"Resize-Cursor-Down-Left"] retain];
    }
    return _downLeftCursor;    
}

+ (NSCursor *)WL_resizeDownRightCursor {
    if (_downRightCursor == nil) {
        _downRightCursor = [[self cursorFromImage:@"Resize-Cursor-Down-Right"] retain];
    }
    return _downRightCursor;    
}


@end
