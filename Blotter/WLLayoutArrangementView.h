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

@interface WLDividerRange : NSObject <NSCopying>

@property CGFloat min;
@property CGFloat max;
@property CGFloat current;

@end


@interface WLLayoutArrangementView : NSSplitView

/*!
 Sizes of all arranged subviews expressed in terms of receiver's distributable area.
 */
@property (readonly) NSArray<NSNumber *> *arrangedSubviewsSizeRatios;

/*!
 Size of the receiver along adjustable axis excluding all auxiliary elements such as dividers.
 */
@property (readonly) CGFloat distributableSize;

/*!
 Position of a given divider in view's coordinate system.
 */
- (CGFloat)positionOfDividerAtIndex:(NSInteger)anIndex;

/*!
 Layout with given constraints.

 @param aPreferredSizeRatios Preferred sizes of the arranged subviews expressed in terms of receiver's sizable area.

 @param aCollapsibleSizeRatios Min sizes of the arranged subviews expressed in terms of receiver's sizable area.

 @return
 Position range for dividers such as that min and max correspond to the smallest and largest sizes a subview can take
 before being collapsed.

 @discussion
 Since fractional values are used, rounding errors are unavoidable. Thus for edge cases the caller should check
 current divider positions against returned ranges to detrmine.
 */
- (NSArray<WLDividerRange *> *)layoutWithPreferredSizes:(NSArray<NSNumber *> *)aPreferredSizeRatios
                                       collapsibleSizes:(NSArray<NSNumber *> *)aCollapsibleSizeRatios;

/*!
 Apply layout and position dividers accordingly.
 */
- (void)adjustSubviewsWithLayout:(NSArray<WLDividerRange *> *)aLayout;

/*!
 Convert layout expressed as divider ranges with respect to the current state to aView.

 @param aBounds Rect in aView's coordinates for layout.

 @param aMinSizes Sizes in aView's coordinates for views that have the least possible size before being collapsed.

 @param aSpacings Spacing in aView's coordiates between adjacent views.
 */
- (NSArray<NSNumber *> *)convertLayout:(NSArray<WLDividerRange *> *)aLayout
                                toView:(NSView *)aView
                               forRect:(NSRect)aBounds
                              minSizes:(NSArray<NSNumber *> *)aMinSizes
                              spacings:(NSArray<NSNumber *> *)aSpacings;

@end


@interface WLLayoutArrangementPaneAuxView : WLLayerBackedView
@end

NS_ASSUME_NONNULL_END
