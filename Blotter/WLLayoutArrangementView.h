//
//  WLLayoutView.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 12.11.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <WLFoundation/WLFoundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface WLLayoutArrangementView : NSSplitView

/*!
 Position of a given divider in view's coordinate system.
 */
- (CGFloat)positionOfDividerAtIndex:(NSInteger)anIndex;

@end


@interface WLLayoutArrangementPaneAuxView : WLLayerBackedView
@end

NS_ASSUME_NONNULL_END
