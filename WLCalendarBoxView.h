//
//  WLCalendarBoxView.h
//  Blotter
//
//  Created by Ilya Kulakov on 26.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>


/*
   +-----------------------+
   | Title                 |
   |                       |
   +-----------------------+
   |                       |
   +-----------------------+
   | Content               |
   |                       |
   |                       |
   |                       |
   |                       |
   +-----------------------+
*/

@interface WLCalendarBoxView : NSView {
    NSString *title;
    NSView *contentView;
    BOOL showSoftTopAndBottomEdges;
}

@property (copy) NSString *title;

@property (nonatomic, retain) NSView *contentView;

@property (nonatomic) BOOL showSoftTopAndBottomEdges;


- (NSDictionary *)_titleAttributes;

- (NSRect)_titleFrame;

- (NSRect)_contentFrame;

@end
