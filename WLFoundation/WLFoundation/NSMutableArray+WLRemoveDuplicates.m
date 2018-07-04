//
//  NSMutableArray+WLRemoveDuplicates.m
//  WLFoundation
//
//  Created by Ilya Kulakov on 26.10.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import "NSMutableArray+WLRemoveDuplicates.h"


@implementation NSMutableArray (WLRemoveDuplicates)

- (void)WL_removeDuplicatesInSortedArrayUsingComparator:(NSComparator)aComparator
{
    NSMutableIndexSet *duplicateIndexes = [NSMutableIndexSet indexSet];

    for (NSUInteger i = 0, size = self.count; i < size;)
    {
        NSUInteger lastDuplicateIndex = [self indexOfObject:self[i]
                                              inSortedRange:NSMakeRange(i + 1, size - (i + 1))
                                                    options:NSBinarySearchingLastEqual
                                            usingComparator:aComparator];

        if (lastDuplicateIndex != NSNotFound)
        {
            [duplicateIndexes addIndexesInRange:NSMakeRange(i + 1, lastDuplicateIndex - i)];
            i = lastDuplicateIndex + 1;
        }
        else
            i += 1;
    }

    [self removeObjectsAtIndexes:duplicateIndexes];
}

@end
