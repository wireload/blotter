//
//  DesktopView.h
//  Deskboard
//
//  Created by Alexander Ljungberg on 01/11/2010.
//  Copyright 2010 SlevenBits. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebView.h>

#import "MGTemplateEngine.h"

#import "BLFadeController.h"

@interface DesktopView : NSView {
    WebView             *webContentView;
    MGTemplateEngine    *templateEngine;
    BLFadeController    *fadeController;
}

- (void)refresh;
- (NSString *)calendarHtml;

@end
