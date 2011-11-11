//
//  WLCopyCompositingFilterKernel.h
//  Blotter
//
//  Created by Ilya Kulakov on 23.09.11.
//  Copyright 2011 WireLoad. All rights reserved.
//


#import <QuartzCore/QuartzCore.h>


/*
 @abstract      Implements NSCompositeCopy for Core Image.
 @discussion    Alpha of inputBackgroundImage MUST NOT be greater than alpha of inputImage.
 */
@interface WLCopyCompositingFilter : CIFilter {
    CIImage *inputImage;
    CIImage *inputBackgroundImage;
}

@end
