//
//  WLCalendarDateViewController.h
//  Blotter
//
//  Created by Ilya Kulakov on 08.08.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WireloadClassesAndResources/WireloadClassesAndResources.h>
#import "WLCalendarDateView.h"


@interface WLCalendarDateViewController : NSViewController {
    NSCache *_cache;
}

- (WLCalendarDateView *)view;

- (WLCalendarController *)representedObject;

- (void)reloadViewData;


@property (nonatomic, retain) NSDateFormatter *_dateFormatter;

@end
