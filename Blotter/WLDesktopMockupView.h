//
//  WLDesktopMockupView.h
//  Blotter
//
//  Created by Ilya Kulakov on 3/13/20.
//  Copyright © 2020 WireLoad. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>


NS_ASSUME_NONNULL_BEGIN

/*!
 Mockup of the desktop with wallpaper for preferences panes.
 */
@interface WLDesktopMockupView : WLLayerBackedView

- (NSImageView *)makeDesktopView;

- (NSImageView *)makeShadowView;

@end

NS_ASSUME_NONNULL_END
