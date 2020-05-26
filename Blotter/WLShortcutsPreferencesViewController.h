//
//  WLShortcutsPreferencesViewController.h
//  Blotter
//
//  Created by Ilya Kulakov on 7/28/19.
//  Copyright © 2019 WireLoad. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <ShortcutRecorder/ShortcutRecorder.h>
#import <WLFoundation/WLFoundation.h>

#import "WLPreferencesViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface WLShortcutsPreferencesViewController : WLPreferencesViewController <SRRecorderControlDelegate, SRShortcutValidatorDelegate>
@end

NS_ASSUME_NONNULL_END
