//
//  WLNinePartBlockLayer.h
//  Blotter Preferences
//
//  Created by Alexander Ljungberg on 28/10/2011.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import "WLBlockLayer.h"



@interface WLNinePartBlockLayer : WLBlockLayer {
    CGImageRef _contents;
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
