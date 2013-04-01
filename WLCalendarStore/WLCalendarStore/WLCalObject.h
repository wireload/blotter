//
//  WLCalObject
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 24.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WLCalendarStore/WLCalStore.h>


@protocol WLCalObject <NSObject>

/*!
    @brief  A calendar store used to create the object.
 */
@property (readonly) NSObject <WLCalStore> *store;

- (instancetype)initWithStore:(NSObject <WLCalStore> *)aStore;

@end
