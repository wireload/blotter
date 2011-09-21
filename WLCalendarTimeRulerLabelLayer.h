//
//  WLCalendarTextLayer.h
//  Blotter
//
//  Created by Ilya Kulakov on 24.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>


/*!
 @discussion Draws only first line.
 */
@interface WLCalendarTimeRulerLabelLayer : CALayer

@property (copy) NSAttributedString *string;

@end
