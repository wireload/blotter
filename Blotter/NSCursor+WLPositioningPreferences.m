//
//  NSCursor+WLPositioningPreferences.m
//  Blotter Preferences
//
//  Created by Alexander Ljungberg on 31/10/2011.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import "NSCursor+WLPositioningPreferences.h"


@implementation NSCursor (WLPositioningPreferences)

+ (NSCursor *)WL_cursorFromImage:(NSString *)aFilename
{
    NSImage *i = [NSImage imageNamed:aFilename];
    return [[NSCursor alloc] initWithImage:i hotSpot:NSMakePoint(i.size.width / 2, i.size.height / 2)];
}

+ (NSCursor *)WL_resizeDownLeftCursor {
    static dispatch_once_t onceToken;
    static NSCursor *DownLeftCursor = nil;
    dispatch_once(&onceToken, ^{
        DownLeftCursor = [self WL_cursorFromImage:@"cursor-resize-northeastsouthwest"];
    });
    return DownLeftCursor;
}

+ (NSCursor *)WL_resizeDownRightCursor {
    static dispatch_once_t onceToken;
    static NSCursor *DownRightCursor = nil;
    dispatch_once(&onceToken, ^{
        DownRightCursor = [self WL_cursorFromImage:@"cursor-resize-northwestsoutheast"];
    });
    return DownRightCursor;
}

+ (NSCursor *)WL_resizeLeftRightCursor {
    static dispatch_once_t onceToken;
    static NSCursor *UpLeftCursor = nil;
    dispatch_once(&onceToken, ^{
        UpLeftCursor = [self WL_cursorFromImage:@"cursor-resize-eastwest"];
    });
    return UpLeftCursor;
}

+ (NSCursor *)WL_resizeUpDownCursor {
    static dispatch_once_t onceToken;
    static NSCursor *UpLeftCursor = nil;
    dispatch_once(&onceToken, ^{
        UpLeftCursor = [self WL_cursorFromImage:@"cursor-resize-northsouth"];
    });
    return UpLeftCursor;
}

+ (NSCursor *)WL_resizeUpLeftCursor {
    static dispatch_once_t onceToken;
    static NSCursor *UpLeftCursor = nil;
    dispatch_once(&onceToken, ^{
        UpLeftCursor = [self WL_cursorFromImage:@"cursor-resize-northwestsoutheast"];
    });
    return UpLeftCursor;
}

+ (NSCursor *)WL_resizeUpRightCursor {
    static dispatch_once_t onceToken;
    static NSCursor *UpRightCursor = nil;
    dispatch_once(&onceToken, ^{
        UpRightCursor = [self WL_cursorFromImage:@"cursor-resize-northeastsouthwest"];
    });
    return UpRightCursor;
}

@end
