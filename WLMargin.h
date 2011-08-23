//
//  WLMargin.h
//  Blotter
//
//  Created by Ilya Kulakov on 23.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef struct
{
    CGPoint topLeft;
    CGPoint bottomRight;
} WLMargin;

NS_INLINE CGFloat WLMarginGetMaxY(WLMargin m)
{
    return m.topLeft.y + m.bottomRight.y;
}

NS_INLINE CGFloat WLMarginGetMaxX(WLMargin m)
{
    return m.topLeft.x + m.bottomRight.x;
}