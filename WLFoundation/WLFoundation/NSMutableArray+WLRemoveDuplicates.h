//
//  NSMutableArray+WLRemoveDuplicates.h
//  WLFoundation
//
//  Created by Ilya Kulakov on 26.10.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSMutableArray (WLRemoveDuplicates)

- (void)WL_removeDuplicatesInSortedArrayUsingComparator:(NSComparator)aComparator;

@end
