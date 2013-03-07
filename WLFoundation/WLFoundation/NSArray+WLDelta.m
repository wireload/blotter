//
//  NSArray(WLDelta)
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 15.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import "NSArray+WLDelta.h"


@implementation NSArray (WLDelta)

- (void)WL_indexesOfDeletedObjects:(out NSIndexSet * __autoreleasing *)outDeletedIndexes
          indexesOfInsertedObjects:(out NSIndexSet * __autoreleasing *)outInsertedIndexes
                   relativeToArray:(NSArray *)aRelativeArray
             sortedUsingComparator:(NSComparator)aComparator
{
    if (!aRelativeArray)
        [NSException raise:NSInvalidArgumentException format:@"You cannot compare to nil."];

    if (!aComparator)
        [NSException raise:NSInvalidArgumentException format:@"You must pass a comparator."];

    if ([self count] == 0)
    {
        if (outInsertedIndexes)
            *outInsertedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [aRelativeArray count])];
        if (outDeletedIndexes)
            *outDeletedIndexes = [NSIndexSet indexSet];
        return;
    }
    else if ([aRelativeArray count] == 0)
    {
        if (outInsertedIndexes)
            *outInsertedIndexes = [NSIndexSet indexSet];
        if (outDeletedIndexes)
            *outDeletedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self count])];
        return;
    }

    if (outInsertedIndexes)
        *outInsertedIndexes = [NSMutableIndexSet indexSet];
    if (outDeletedIndexes)
        *outDeletedIndexes = [NSMutableIndexSet indexSet];

    NSUInteger fromObjectIdx = 0, fromArraySize = [self count];
    NSUInteger toObjectIdx = 0, toArraySize = [aRelativeArray count];
    while (fromObjectIdx < fromArraySize && toObjectIdx < toArraySize)
    {
        id fromObject = [self objectAtIndex:fromObjectIdx];
        id toObject = [aRelativeArray objectAtIndex:toObjectIdx];

        NSComparisonResult r = aComparator(fromObject, toObject);
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

- (NSIndexSet *)WL_indexesOfInsertedObjects:(__autoreleasing NSIndexSet **)outInsertedIndexes
                            relativeToArray:(NSArray *)aRelativeArray
                      sortedUsingComparator:(NSComparator)aComparator
{
    if (!aRelativeArray)
        [NSException raise:NSInvalidArgumentException format:@"You cannot compare to nil."];

    if (!aComparator)
        [NSException raise:NSInvalidArgumentException format:@"You must pass a comparator."];

    NSUInteger selfCount = [self count];
    NSUInteger fromArrayCount = [aRelativeArray count];

    if (selfCount == 0)
    {
        NSIndexSet *result = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, fromArrayCount)];
        if (outInsertedIndexes)
            *outInsertedIndexes = [result copy];
        return result;
    }
    else if (fromArrayCount == 0)
    {
        if (outInsertedIndexes)
            *outInsertedIndexes = [NSIndexSet indexSet];
        return [NSIndexSet indexSet];
    }

    if (outInsertedIndexes)
        *outInsertedIndexes = [NSMutableIndexSet indexSet];
    NSMutableIndexSet *selfInsertedIndexes = [NSMutableIndexSet indexSet];

    __block NSRange selfSortedRange = NSMakeRange(0, selfCount);
    [aRelativeArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        NSUInteger i = [self indexOfObject:obj
                             inSortedRange:selfSortedRange
                                   options:NSBinarySearchingInsertionIndex | NSBinarySearchingFirstEqual
                           usingComparator:aComparator];
        if (i >= selfCount || ![obj isEqual:self[i]])
        {
            if (outInsertedIndexes)
                [(NSMutableIndexSet *)*outInsertedIndexes addIndex:idx];
            [selfInsertedIndexes addIndex:[selfInsertedIndexes count] + i];
        }
        else
        {
            selfSortedRange.location = i + 1;
            selfSortedRange.length = selfCount - selfSortedRange.location;
        }
    }];

    return selfInsertedIndexes;
}

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