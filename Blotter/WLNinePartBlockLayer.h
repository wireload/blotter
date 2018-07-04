//
//  WLNinePartBlockLayer.h
//  Blotter Preferences
//
//  Created by Alexander Ljungberg on 28/10/2011.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>


@interface WLNinePartBlockLayer : WLBlockLayer <CALayerDelegate>
{
    CGImageRef _contents;
    NSArray *_sublayers;
}

/*!
 +--+--------------------------------+--+
 |  |                                |  |
 +--|--------------------------------|--+
 |  |                                |  |
 |  |                                |  |
 |  |                                |  |
 |  |                                |  |
 |  |                                |  |
 |  |                                |  |
 |  |                                |  |
 |  |                                |  |
 |  |                                |  |
 |  |                                |  |
 |  |                                |  |
 |  |                                |  |
 |  |                                |  |
 |  |                                |  |
 |  |                                |  |
 +-----------------------------------|--+ ^
 |  |                                |  | | edgeSize
 +--+--------------------------------+--+ +-->
 */
@property CGSize edgeSize;

@end
