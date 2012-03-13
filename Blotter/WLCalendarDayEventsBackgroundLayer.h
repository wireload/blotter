//
//  WLCalendarDayEventsBackgroundLayer.h
//  Blotter
//
//  Created by Ilya Kulakov on 07/03/2012.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>


@interface WLCalendarDayEventsBackgroundLayer : CALayer
{
    NSString *title;
    BOOL isTitleHighlighted;
    struct
    {
        CGSize _preferredFrameSizeOut;
        CGSize _preferredFrameSizeWithinBoundingSizeOut;
        CGSize _cachedBoundingSizeIn;
    } _titleCache;
    BOOL _needsUpdateTitleCache;
}

@property (nonatomic, copy) NSString *title;

@property CGRect titleFrame;

@property (nonatomic) BOOL isTitleHighlighted;

- (CGSize)preferredTitleFrameSizeWithBoundingSize:(CGSize)aBoundingSize;

@end


@interface NSDictionary (WLCalendarDayEventsBackgroundLayer)

+ (NSDictionary *)WL_titleAttributes;

+ (NSDictionary *)WL_highlightedTitleAttributes;

@end
