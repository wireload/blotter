//
//  NSArray+WLDelta.m
//  Blotter
//
//  Created by Ilya Kulakov on 02.11.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import "NSArray+WLDelta.h"


@implementation NSArray (WLDelta)

- (void)WL_indexesOfDeletedObject:(out NSIndexSet **)outDeletedIndexes
         indexesOfInsertedObjects:(out NSIndexSet **)outInsertedIndexes
          indexesOfUpdatedObjects:(out NSIndexSet **)outUpdatedIndexes
                    toSortedArray:(NSArray *)aToArray
                  sortDescriptors:(NSArray *)aSortDescriptors
                    updateChecker:(WLUpdateChecker)anUpdateChecker
{
    NSParameterAssert(aSortDescriptors != nil);
    NSParameterAssert((outUpdatedIndexes != nil && anUpdateChecker != nil) ||
                      (outUpdatedIndexes == nil && anUpdateChecker == nil));

    NSComparisonResult (^Comparator)(id, id) = ^(id aObject, id bObject)
    {
        NSComparisonResult result = NSOrderedSame;
        for (NSSortDescriptor *descriptor in aSortDescriptors)
        {
            result = [descriptor compareObject:aObject toObject:bObject];
            if(result != NSOrderedSame)
            {
                if ([descriptor ascending] == NO)
                    result *= -1;
                break;
            }
        }
        return result;
    };

    if ([self count] == 0)
    {
        if (outInsertedIndexes != NULL)
            *outInsertedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [aToArray count])];
        if (outDeletedIndexes != NULL)
            *outDeletedIndexes = [NSIndexSet indexSet];
        if (outUpdatedIndexes != NULL)
            *outUpdatedIndexes = [NSIndexSet indexSet];
        return;
    }
    else if ([aToArray count] == 0)
    {
        if (outInsertedIndexes != NULL)
            *outInsertedIndexes = [NSIndexSet indexSet];
        if (outDeletedIndexes != NULL)
            *outDeletedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self count])];
        if (outUpdatedIndexes != NULL)
            *outUpdatedIndexes = [NSIndexSet indexSet];
        return;
    }

    if (outInsertedIndexes != NULL)
        *outInsertedIndexes = [NSMutableIndexSet indexSet];
    if (outDeletedIndexes != NULL)
        *outDeletedIndexes = [NSMutableIndexSet indexSet];
    if (outUpdatedIndexes != NULL)
        *outUpdatedIndexes = [NSMutableIndexSet indexSet];

    NSUInteger fromObjectIdx = 0, fromArraySize = [self count];
    NSUInteger toObjectIdx = 0, toArraySize = [aToArray count];
    while (fromObjectIdx < fromArraySize && toObjectIdx < toArraySize)
    {
        id fromObject = [self objectAtIndex:fromObjectIdx];
        id toObject = [aToArray objectAtIndex:toObjectIdx];

        NSComparisonResult r = Comparator(fromObject, toObject);
        switch (r) {
            case NSOrderedAscending:
            {
                if (outDeletedIndexes != NULL)
                    [(NSMutableIndexSet *)*outDeletedIndexes addIndex:fromObjectIdx];
                ++fromObjectIdx;
                break;
            }
            case NSOrderedDescending:
            {
                if (outInsertedIndexes != NULL)
                    [(NSMutableIndexSet *)*outInsertedIndexes addIndex:toObjectIdx];
                ++toObjectIdx;
                break;
            }
            case NSOrderedSame:
            {
                if (outUpdatedIndexes != NULL && anUpdateChecker != NULL && anUpdateChecker(fromObject, toObject))
                {
                    [(NSMutableIndexSet *)*outUpdatedIndexes addIndex:toObjectIdx];
                }
                ++toObjectIdx;
                ++fromObjectIdx;
                break;
            }
        }
    }

    if (fromArraySize < toArraySize && outInsertedIndexes != NULL)
        [(NSMutableIndexSet *)*outInsertedIndexes addIndexesInRange:NSMakeRange(toObjectIdx, toArraySize - toObjectIdx)];
    else if (fromArraySize > toArraySize && outDeletedIndexes != NULL)
        [(NSMutableIndexSet *)*outDeletedIndexes addIndexesInRange:NSMakeRange(fromObjectIdx, fromArraySize - fromObjectIdx)];
}

@end
