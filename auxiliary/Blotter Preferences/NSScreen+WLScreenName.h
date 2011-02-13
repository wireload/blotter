//
//  NSScreen+WLAdditions.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 12.02.11.
//  Copyright 2011 Wireload. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSScreen (WLScreenName)

- (NSString *)WL_localizedScreenName;

- (NSString *)WL_localizedScreenSizeString;

@end
