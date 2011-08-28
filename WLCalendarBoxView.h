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
}

@property (copy) NSString *title;

@property (nonatomic, retain) NSView *contentView;


- (NSDictionary *)_titleAttributes;

- (NSRect)_contentFrame;

@end
