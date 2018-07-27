//
//  WLAboutPreferences.h
//  Blotter Preferences
//
//  Created by Ilya Kulakov on 20.03.12.
//  Copyright (c) 2012 WireLoad. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WLFoundation/WLFoundation.h>
#import "IKPreferencesRepresentation.h"


@interface WLAboutPreferences : WLViewController <IKPreferencesRepresentation>
{
    IBOutlet NSTextField *_versionView;
    IBOutlet NSTextField *_copyrightView;
}

- (IBAction)showHelp:(id)aSender;

- (IBAction)showGetSupport:(id)aSender;

- (IBAction)showRateThisApp:(id)aSender;

- (IBAction)showFollowUsOnTwitter:(id)aSender;

@end
