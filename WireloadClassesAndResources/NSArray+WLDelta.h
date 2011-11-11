//
//  NSArray+WLDelta.h
//  Blotter
//
//  Created by Ilya Kulakov on 02.11.11.
//  Copyright (c) 2011 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef BOOL (^WLUpdateChecker)(id aFromArrayObject, id aToArrayObject);


@interface NSArray (WLDelta)

/*!
 @description   Both arrays must contain unique objects in terms of aSortDescriptors so it can distinguish updated events.
 Indexes are calculated in the following order:
 1. deleted
 2. inserted
 3. updated
 */
- (void)WL_indexesOfDeletedObject:(out NSIndexSet **)outDeletedIndexes
         indexesOfInsertedObjects:(out NSIndexSet **)outInsertedIndexes
          indexesOfUpdatedObjects:(out NSIndexSet **)outUpdatedIndexes
                    toSortedArray:(NSArray *)aToArray
                  sortDescriptors:(NSArray *)aSortDescriptors
                    updateChecker:(WLUpdateChecker)anUpdateChecker;

@end
