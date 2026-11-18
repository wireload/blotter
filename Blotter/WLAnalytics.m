//
//  WLAnalytics.m
//  Blotter
//
//  Created by Ilya Kulakov on 11/12/18.
//  Copyright 2018 WireLoad. All rights reserved.
//

#import <WLFoundation/WLFoundation.h>

#import "WLAnalytics.h"

#import "WLLogNames.h"
#import "MixpanelProtocol.h"
#import "NSUserDefaults+WLApplicationDefaults.h"


const CGFloat WLAnalyticsDefaultSampleRate = 1.0;


@implementation WLAnalytics
{
    NSXPCConnection *_connection;
}

+ (WLAnalytics *)sharedAnalytics
{
    static WLAnalytics *analytics = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        analytics = [[self alloc] initWithSampleRate:WLAnalyticsDefaultSampleRate];
    });
    return analytics;
}

- (instancetype)initWithSampleRate:(CGFloat)aSampleRate
{
    NSAssert(aSampleRate >= 0 && aSampleRate <= 1.0, @"Sample rate must be within [0, 1].");

    if (self = [super init])
    {
        _connection = [self makeConnection];
    }

    return self;
}

- (void)dealloc
{
    [_connection invalidate];
}

#pragma mark Methods

- (NSXPCConnection *)makeConnection
{
    NSXPCConnection *connection = [[NSXPCConnection alloc] initWithServiceName:@"net.wireload.blotter.mac.mixpanel"];
    connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(MixpanelProtocol)];
    [connection resume];
    return connection;
}

- (NSDictionary *)parseAppProperties
{
    static NSDictionary *appProperties = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *bundleInfo = NSBundle.mainBundle.infoDictionary;
        appProperties = [NSMutableDictionary dictionary];
        [appProperties setValue:bundleInfo[@"CFBundleVersion"] forKey:@"$app_version"];
        [appProperties setValue:bundleInfo[@"CFBundleShortVersionString"] forKey:@"$app_release"];
        [appProperties setValue:bundleInfo[@"CFBundleVersion"] forKey:@"$app_build_number"];
        [appProperties setValue:bundleInfo[@"CFBundleShortVersionString"] forKey:@"$app_version_string"];
        NSOperatingSystemVersion osVersion = NSProcessInfo.processInfo.operatingSystemVersion;
        [appProperties setValue:[NSString stringWithFormat:@"%ld.%ld", osVersion.majorVersion, osVersion.minorVersion] forKey:@"General OS Version"];

        NSWorkspace *workspace = NSWorkspace.sharedWorkspace;
        [appProperties setValue:@(workspace.accessibilityDisplayShouldDifferentiateWithoutColor) forKey:@"Accessibility Differentiate Without Color"];
        [appProperties setValue:@(workspace.accessibilityDisplayShouldIncreaseContrast) forKey:@"Accessibility Increase Contrast"];
        [appProperties setValue:@(workspace.accessibilityDisplayShouldReduceTransparency) forKey:@"Accessibility Reduce Transparency"];


        if (@available(macOS 10.12, *))
        {
            [appProperties setValue:@(workspace.accessibilityDisplayShouldInvertColors) forKey:@"Accessibility Invert Colors"];
            [appProperties setValue:@(workspace.accessibilityDisplayShouldReduceMotion) forKey:@"Accessibility Reduce Motion"];
        }

        if (@available(macOS 10.13, *))
        {
            [appProperties setValue:@(workspace.isSwitchControlEnabled) forKey:@"Accessibility Switch Control"];
            [appProperties setValue:@(workspace.isVoiceOverEnabled) forKey:@"Accessibility VoiceOver Control"];
        }

        appProperties = [appProperties copy];
    });

    return appProperties;
}

- (NSDictionary *)parseReceipt
{
// https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html#//apple_ref/doc/uid/TP40010573-CH106-SW1
    static const long PURCHASE_DATE_FIELD = 18; // reverse-engineered
    static const long PURCHASE_APP_VERSION_FIELD = 19;

    static const size_t RECEIPT_OFFSET = 62; // reverse-engineered
    static const size_t STR_BYTES_OFFSET = 2;

#ifdef DEBUG
    NSURL *receiptURL = [NSURL fileURLWithPath:@"/Applications/Blotter.app/Contents/_MASReceipt/receipt"];
#else
    NSURL *receiptURL = NSBundle.mainBundle.appStoreReceiptURL;
#endif

    __auto_type log = [WLLog logForName:WLLogNameBlotterAnalytics];
    NSError *error = nil;
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL
                                                options:NSDataReadingUncached
                                                  error:&error];
    if (!receiptData)
    {
        [log logError:@"Unable to read receipt file: %@", error.localizedDescription];
        return @{};
    }
    else if (receiptData.length <= RECEIPT_OFFSET)
    {
        [log logError:@"Receipt file is of unexpected format."];
        return @{};
    }

    WLReceipt_t *receipt = NULL;
    asn_dec_rval_t parseResult = ber_decode(0, &asn_DEF_WLReceipt, (void **)&receipt, receiptData.bytes + RECEIPT_OFFSET, receiptData.length - RECEIPT_OFFSET);

    @try
    {
        if (parseResult.code != RC_OK && parseResult.consumed == 0)
            return @{};

        NSString *purchaseVersion = nil;
        NSString *purchaseDate = nil;

        for (int i = 0; i < receipt->list.count; ++i)
        {
            WLReceiptAttribute_t *entry = receipt->list.array[i];

            switch (entry->type)
            {
                case PURCHASE_DATE_FIELD:
                {
                    if (entry->value.size > (int)STR_BYTES_OFFSET)
                        purchaseDate = [[NSString alloc] initWithBytes:entry->value.buf + STR_BYTES_OFFSET
                                                                length:(NSUInteger)entry->value.size - STR_BYTES_OFFSET
                                                              encoding:NSASCIIStringEncoding];
                    break;
                }
                case PURCHASE_APP_VERSION_FIELD:
                {
                    if (entry->value.size > (int)STR_BYTES_OFFSET)
                        purchaseVersion = [[NSString alloc] initWithBytes:entry->value.buf + STR_BYTES_OFFSET
                                                                   length:(NSUInteger)entry->value.size - STR_BYTES_OFFSET
                                                                 encoding:NSUTF8StringEncoding];
                    break;
                }
                default:
                    break;
            }

            if (purchaseVersion && purchaseDate)
                break;
        }

        NSMutableDictionary *result = [NSMutableDictionary dictionary];

        if (purchaseDate)
        {
            NSDateFormatter *RFC3339DateFormatter = [[NSDateFormatter alloc] init];
            RFC3339DateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
            RFC3339DateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
            RFC3339DateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];

            [result setObject:[RFC3339DateFormatter dateFromString:purchaseDate] forKey:@"Purchase Date"];
        }

        if (purchaseVersion)
            [result setObject:purchaseVersion forKey:@"Purchase Version"];

        return [result copy];
    }
    @finally
    {
        asn_DEF_WLReceipt.free_struct(&asn_DEF_WLReceipt, receipt, 0);
    }
}

- (void)reportLaunchedToMixpanelIfNeeded
{
    if (![NSUserDefaults.standardUserDefaults WL_shareAnalytics])
        return;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *appProperties = [self parseAppProperties];
        NSMutableDictionary *systemProperties = [appProperties mutableCopy];
        NSLocale *locale = NSLocale.currentLocale;
        systemProperties[@"Locale"] = locale.localeIdentifier;

        if (@available(macOS 10.12, *))
            systemProperties[@"Calendar"] = locale.calendarIdentifier;
        else
            systemProperties[@"Calendar"] = NSCalendar.currentCalendar.calendarIdentifier;

        @try
        {
            [systemProperties addEntriesFromDictionary:[self parseReceipt]];
        }
        @catch (NSException *e)
        {
            [[WLLog logForName:WLLogNameBlotterAnalytics] logError:@"Unable to parse the receipt: %@", e.reason];
        }

        id<MixpanelProtocol> remoteObjectProxy = [_connection remoteObjectProxyWithErrorHandler:^(NSError *anError) {
            [[WLLog logForName:WLLogNameMixpanel] logError:@"Unable to report launched to Mixpanel: %@", anError.localizedDescription];
        }];
        [remoteObjectProxy peopleSet:systemProperties withReply:^{}];
        [remoteObjectProxy track:@"Launched" withProperties:appProperties andReply:^{}];
    });
}

- (void)reportDailyToMixpanelIfNeeded
{
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;

    if (![d WL_shareAnalytics])
        return;

    static NSCalendar *posixCalendar = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        posixCalendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        posixCalendar.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        posixCalendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    });

    NSDate *now = NSDate.date;
    NSDate *lastReportedAt = [d objectForKey:WLLastReportedDailyEventAt];

    if (lastReportedAt && [posixCalendar isDate:now inSameDayAsDate:lastReportedAt])
        return;

    [d setObject:now forKey:WLLastReportedDailyEventAt];
    NSDictionary *appProperties = [self parseAppProperties];
    id<MixpanelProtocol> remoteObjectProxy = [_connection remoteObjectProxyWithErrorHandler:^(NSError *anError) {
        [[WLLog logForName:WLLogNameMixpanel] logError:@"Unable to report daily to Mixpanel: %@", anError.localizedDescription];
    }];
    [remoteObjectProxy track:@"Daily" withProperties:appProperties andReply:^{}];
}

- (void)reportAction:(NSString *)anActionName
{
    if (![NSUserDefaults.standardUserDefaults WL_shareAnalytics])
        return;

    NSDictionary *appProperties = [self parseAppProperties];
    id<MixpanelProtocol> remoteObjectProxy = [_connection remoteObjectProxyWithErrorHandler:^(NSError *anError) {
        [[WLLog logForName:WLLogNameMixpanel] logError:@"Unable to report %@ to Mixpanel: %@", anActionName, anError.localizedDescription];
    }];
    [remoteObjectProxy track:anActionName withProperties:appProperties andReply:^{}];
}

@end
