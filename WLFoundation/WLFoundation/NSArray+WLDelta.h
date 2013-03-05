//
//  NSArray(WLDelta)
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 15.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef BOOL (^WLUpdateChecker)(id aFromArrayObject, id aToArrayObject);


@interface NSArray (WLDelta)

/*!
    @brief      Computes difference between 2 sorted arrays.
    @param      outDeletedIndexes Points to indexes of deleted objects in the receiver. Can be NULL.
    @param      outInsertedIndexes Points to indexes of inserted objects in aRelativeArray. Can be NULL.
    @param      aRelativeArray Array to compare. If nil, NSInvalidArgumentException is thrown.
    @param      aComparator Comparator used to sort both self and aRelativeArray.
    @discussion Throws an exception if either aRelativeArray or aComparator is nil.
 */
- (void)WL_indexesOfDeletedObject:(out NSIndexSet * __autoreleasing *)outDeletedIndexes
         indexesOfInsertedObjects:(out NSIndexSet * __autoreleasing *)outInsertedIndexes
                  relativeToArray:(NSArray *)aRelativeArray
            sortedUsingComparator:(NSComparator)aComparator;

/*!
    @brief      Computes indexes of objects that are considered inserted in the receiver and their position in the receiver.
    @param      outInsertedIndexes Points to indexes of objects in aRelativeArray that are considered as inserted in the receiver.
    @param      aRelativeArray Array to compare. If nil, NSInvalidArgumentException is thrown.
    @param      aComparator Comparator used to sort both the receiver and aRelativeArray.
    @result     Indexes of objects that are considered inserted in the receiver.
    @discussion Throws an exception if either aRelativeArray or comparator is nil.
 */
- (NSIndexSet *)WL_indexesOfInsertedObjects:(out __autoreleasing NSIndexSet **)outInsertedIndexes
                            relativeToArray:(NSArray *)aRelativeArray
                      sortedUsingComparator:(NSComparator)aComparator;

/*!
    //TODO: REWRITE ME
    @description   Both arrays must contain unique objects in terms of aSortDescriptors so it can distinguish updated events.
 */
- (void)WL_indexesOfDeletedObject:(out NSIndexSet **)outDeletedIndexes
         indexesOfInsertedObjects:(out NSIndexSet **)outInsertedIndexes
          indexesOfUpdatedObjects:(out NSIndexSet **)outUpdatedIndexes
                    toSortedArray:(NSArray *)aToArray
                  sortDescriptors:(NSArray *)aSortDescriptors
                    updateChecker:(WLUpdateChecker)anUpdateChecker;

@end
