//
//  NSCursor+ResizeAdditions.m
//  Blotter Preferences
//
//  Created by Alexander Ljungberg on 31/10/2011.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import "NSCursor+ResizeAdditions.h"
#import "GeneralPrefController.h"


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
    static dispatch_once_t onceToken;
    static NSCursor *UpLeftCursor = nil;
    dispatch_once(&onceToken, ^{
        UpLeftCursor = [[self cursorFromImage:@"Resize-Cursor-Up-Left"] retain];
    });
    return UpLeftCursor;
}

+ (NSCursor *)WL_resizeUpRightCursor {
    static dispatch_once_t onceToken;
    static NSCursor *UpRightCursor = nil;
    dispatch_once(&onceToken, ^{
        UpRightCursor = [[self cursorFromImage:@"Resize-Cursor-Up-Right"] retain];
    });
    return UpRightCursor;
}

+ (NSCursor *)WL_resizeDownLeftCursor {
    static dispatch_once_t onceToken;
    static NSCursor *DownLeftCursor = nil;
    dispatch_once(&onceToken, ^{
        DownLeftCursor = [[self cursorFromImage:@"Resize-Cursor-Down-Left"] retain];
    });
    return DownLeftCursor;
}

+ (NSCursor *)WL_resizeDownRightCursor {
    static dispatch_once_t onceToken;
    static NSCursor *DownRightCursor = nil;
    dispatch_once(&onceToken, ^{
        DownRightCursor = [[self cursorFromImage:@"Resize-Cursor-Down-Right"] retain];
    });
    return DownRightCursor;
}


@end
