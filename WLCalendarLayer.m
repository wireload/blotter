//
//  WLCalendarLayer.m
//  Blotter
//
//  Created by Ilya Kulakov on 16.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarLayer.h"
#import "NSColor+CGColor.h"


@implementation WLCalendarLayer
@dynamic contentsBackgroundOpacity;
@dynamic contentsBackgroundColor;

+ (id<CAAction>)defaultActionForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"contentsBackgroundOpacity"])
        return [CABasicAnimation animationWithKeyPath:@"contentsBackgroundOpacity"];
    else if ([aKey isEqualToString:@"contentsBackgroundColor"])
        return [CABasicAnimation animationWithKeyPath:@"contentsBackgroundColor"];
    else
        return [super defaultValueForKey:aKey];
}

+ (id)defaultValueForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"contentsBackgroundOpacity"])
        return [NSNumber numberWithFloat:1.0f];
    else if ([aKey isEqualToString:@"contentsBackgroundColor"])
        return (id)[[NSColor clearColor] WL_CGColor];
    else
        return [super defaultValueForKey:aKey];
}

+ (BOOL)needsDisplayForKey:(NSString *)aKey
{
    if ([aKey isEqualToString:@"contentsBackgroundOpacity"])
        return YES;
    else if ([aKey isEqualToString:@"contentsBackgroundColor"])
        return YES;
    else
        return [super needsDisplayForKey:aKey];
}

- (id<CAAction>)actionForKey:(NSString *)aKey
{
    id<CAAction> action = [super actionForKey:aKey];
    if ([aKey isEqualToString:@"contentsBackgroundOpacity"])
        [(CABasicAnimation *)action setFromValue:[[self presentationLayer] valueForKeyPath:@"contentsBackgroundOpacity"]];
    else if ([aKey isEqualToString:@"contentsBackgroundColor"])
        [(CABasicAnimation *)action setFromValue:[[self presentationLayer] valueForKeyPath:@"contentsBackgroundColor"]];
    return action;
}

@end
