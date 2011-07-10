//
//  CATextLayer+WLStringSize.h
//  Blotter
//
//  Created by Ilya Kulakov on 08.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>


@interface CATextLayer (WLStringSize)

- (CGFloat)WL_maxStringHeightForWidth:(CGFloat)width;

@end
