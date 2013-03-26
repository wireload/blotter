//
//  NSImage+WLHiDPIDrawing.h
//  WLFoundation
//
//  Created by Ilya Kulakov on 26.03.13.
//  Copyright (c) 2013 Wireload. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*!
    @brief  Definition of the dpi-independent drawing block.
 */
typedef BOOL (^WLImageDrawingHandler)(NSRect aDestinationRect);


@interface NSImage (WLHiDPIDrawing)

/*!
    @brief  Backward compatible version of +[NSImage imageWithSize:flipped:drawingHandler:] that was introduced in 10.8
 */
+ (NSImage *)WL_imageWithSize:(NSSize)aSize flipped:(BOOL)anIsFlipped drawingHandler:(WLImageDrawingHandler)aDrawingHandler;

@end
