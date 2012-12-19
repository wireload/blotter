//
//  WLViewController.h
//  Blotter
//
//  Created by Ilya Kulakov on 10.12.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface WLViewController : NSViewController

/*!
    @brief      Determines, whether -view property of the controller is non-nil.

    @discussion Does not cause the view to load.
 */
@property (readonly) BOOL isViewLoaded;

@end
