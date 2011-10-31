//
//  NSCursor+ResizeAdditions.h
//  Blotter Preferences
//
//  Created by Alexander Ljungberg on 31/10/2011.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface NSCursor (WLResizeAdditions)

+ (NSCursor *)WL_resizeUpLeftCursor;
+ (NSCursor *)WL_resizeUpRightCursor;
+ (NSCursor *)WL_resizeDownLeftCursor;
+ (NSCursor *)WL_resizeDownRightCursor;

@end
