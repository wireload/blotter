//
//  WLCalSystemCalendar.m
//  WLCalendarStore
//
//  Created by Ilya Kulakov on 29.09.12.
//  Copyright 2012 WireLoad. All rights reserved.
//

#import "WLCalSystemCalendar.h"


@implementation WLCalSystemCalendar
@synthesize allowsContentModifications = _allowsContentModifications;
@synthesize color = _color;
@synthesize title = _title;
@synthesize type = _type;
@synthesize immutable = _immutable;
@synthesize allowedEntityTypes = _allowedEntityTypes;
@synthesize calendarIdentifier = _calendarIdentifier;

// This class exists only for compatibility with deprecated CalCalendar* objects.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (instancetype)initWithStore:(id <WLCalStore>)aStore
                   csCalendar:(CalCalendar *)aCSCalendar
           allowedEntityTypes:(WLCalEntityMask)anAllowedEntityTypes
{
    NSParameterAssert(aCSCalendar != nil);

    if (!(aCSCalendar.uid).length)
        return nil;

    self = [super initWithStore:aStore];

    if (self)
    {
        self->_allowsContentModifications = aCSCalendar.isEditable;

        if (aCSCalendar.color && (id)aCSCalendar.color != [NSNull null])
            self->_color = [aCSCalendar.color copy];
        else
            self->_color = [NSColor blueColor];

        self->_immutable = !aCSCalendar.isEditable;
        self->_title = [aCSCalendar.title copy];

        if (!self->_title)
            self->_title = @"";

        if ([aCSCalendar.type isEqualToString:CalCalendarTypeLocal])
            self->_type = WLCalendarTypeLocal;
        else if ([aCSCalendar.type isEqualToString:CalCalendarTypeCalDAV])
            self->_type = WLCalendarTypeCalDAV;
        else if ([aCSCalendar.type isEqualToString:CalCalendarTypeExchange])
            self->_type = WLCalendarTypeExchange;
        else if ([aCSCalendar.type isEqualToString:CalCalendarTypeSubscription])
            self->_type = WLCalendarTypeSubscription;
        else if ([aCSCalendar.type isEqualToString:CalCalendarTypeBirthday])
            self->_type = WLCalendarTypeBirthday;
        else if ([aCSCalendar.type isEqualToString:CalCalendarTypeIMAP])
            self->_type = WLCalendarTypeIMAP;

        self->_allowedEntityTypes = anAllowedEntityTypes;

        self->_calendarIdentifier = [aCSCalendar.uid copy];
    }

    return self;
}

#pragma clang diagnostic pop


#pragma mark NSObject

- (BOOL)isEqual:(WLCalSystemCalendar *)anObject
{
    if (![super isEqual:anObject])
        return NO;
    else if (self.allowsContentModifications != anObject.allowsContentModifications)
        return NO;
    else if (self.type != anObject.type)
        return NO;
    else if (self.immutable != anObject.immutable)
        return NO;
    else if (self.allowedEntityTypes != anObject.allowedEntityTypes)
        return NO;
    else if (![self.calendarIdentifier isEqual:anObject.calendarIdentifier])
        return NO;
    else if (![self.color isEqual:anObject.color])
        return NO;
    else if ([self.title isEqual:anObject.title])
        return NO;
    else
        return YES;
}

- (NSUInteger)hash
{
    return (self.calendarIdentifier).hash;
}

- (NSString *)description
{
    NSDictionary *d = [self dictionaryWithValuesForKeys:@[@"allowsContentModifications", @"color", @"immutable", @"title", @"type", @"allowedEntityTypes"]];
    return [NSString stringWithFormat:@"%@: %@", super.description, d];
}

@end

#pragma clang diagnostic pop
