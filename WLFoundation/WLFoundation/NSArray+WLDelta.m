//
//  NSArray(WLDelta)
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 15.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import "NSArray+WLDelta.h"


@implementation NSArray (WLDelta)

- (void)WL_indexesOfDeletedObject:(out NSIndexSet * __autoreleasing *)outDeletedIndexes
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

- (NSIndexSet *)WL_indexesOfObjects:(__autoreleasing NSIndexSet **)outIndexes
                    relativeToArray:(NSArray *)aRelativeArray
              sortedUsingComparator:(NSComparator)aComparator
{
    if (!aRelativeArray)
        [NSException raise:NSInvalidArgumentException format:@"You cannot compare to nil."];

    if (!aComparator)
        [NSException raise:NSInvalidArgumentException format:@"You must pass a comparator."];

    if (([self count] == 0 || [aRelativeArray count] == 0) || // if either array is empty, they have no equal objects
        (aComparator(self[0], [aRelativeArray lastObject]) == NSOrderedDescending) || // first object in the receiver is greater than last object from aFromArray => no equal objects
        (aComparator([self lastObject], aRelativeArray[0]) == NSOrderedAscending)) // last object in the receiver is less than first object from aFromArray => no equal objects
    {
        if (outIndexes)
            *outIndexes = [NSIndexSet indexSet];
        return [NSIndexSet indexSet];
    }

    if (outIndexes)
        *outIndexes = [NSMutableIndexSet indexSet];
    NSMutableIndexSet *indexesInSelf = [NSMutableIndexSet indexSet];

    NSUInteger count = [self count];
    __block NSRange sortedRange = NSMakeRange(0, count);
    [aRelativeArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        NSUInteger i = [self indexOfObject:obj
                             inSortedRange:sortedRange
                                   options:NSBinarySearchingFirstEqual
                           usingComparator:aComparator];
        if (i != NSNotFound)
        {
            sortedRange.length -= i + 1 - sortedRange.location;
            sortedRange.location = i + 1;

            if (i >= count)
                *stop = YES;
        }
    }];

    return indexesInSelf;
}

@end