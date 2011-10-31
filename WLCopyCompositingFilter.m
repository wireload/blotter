//
//  WLCopyCompositingFilterKernel.m
//  Blotter
//
//  Created by Ilya Kulakov on 23.09.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCopyCompositingFilter.h"


static CIKernel *kernel = nil;


@implementation WLCopyCompositingFilter

+ (void)initialize
{
    if (self == [WLCopyCompositingFilter class])
    {
        [CIFilter registerFilterName:@"WLCopyCompositing"
                         constructor:(id)self
                     classAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                       @"WLCopyCompositing",                                    kCIAttributeFilterDisplayName,
                                       [NSArray arrayWithObject:kCICategoryCompositeOperation], kCIAttributeFilterCategories,
                                       nil]
         ];
    }
}


- (id)init
{
    if(kernel == nil)
    {
        // Assuming that alpha of backgroundImage isn't greater than alpha of image.
        NSString *kernelCode = @"\
        kernel vec4 coreImageKernel(sampler image, sampler backgroundImage)\
        {\
        vec4 srcColor = sample(image, samplerCoord(image));\
        vec4 destColor = sample(backgroundImage, samplerCoord(backgroundImage));\
        destColor.a -= srcColor.a;\
        destColor.a = max(0.0, destColor.a);\
        return srcColor + destColor;\
        }";
        NSArray *kernels = [CIKernel kernelsWithString:kernelCode];
        kernel = [[kernels objectAtIndex:0] retain];
    }
    return [super init];
}


#pragma mark CIFilter

+ (CIFilter *)filterWithName: (NSString *)name
{
    return [[self new] autorelease];
}

- (CIImage *)outputImage
{
    CISampler *src = [CISampler samplerWithImage:inputImage];
    CISampler *dst = [CISampler samplerWithImage:inputBackgroundImage];
    return [self apply:kernel
             arguments:[NSArray arrayWithObjects:src, dst, nil]
               options:[NSDictionary dictionaryWithObject:[src definition] forKey:kCIApplyOptionDefinition]];
}

@end
