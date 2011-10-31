//
//  NSCursor+ResizeAdditions.h
//  Blotter Preferences
//
//  Created by Alexander Ljungberg on 31/10/2011.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface NSCursor (ResizeAdditions)

+ (NSCursor *)resizeUpLeftCursor;
+ (NSCursor *)resizeUpRightCursor;
+ (NSCursor *)resizeDownLeftCursor;
+ (NSCursor *)resizeDownRightCursor;

@end
