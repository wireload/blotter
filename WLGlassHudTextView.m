//
//  WLGlassHudTextField.m
//  Blotter
//
//  Created by Ilya Kulakov on 24.03.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLGlassHudTextView.h"


static const CGFloat _WLTextViewTopOffset = 3.0f;
static const CGFloat _WLTextViewBottomOffset = 7.0f;

NSString* const WLViewSizeDidChangeNotification = @"WLViewSizeDidChangeNotification";
NSString* const WLSizeDiff = @"WLSizeDiff";


@implementation _WLGlassHudTextViewInternal
@synthesize containerView;

- (void)setDrawsBackground:(BOOL)flag
{
    [super setDrawsBackground:flag];
    [containerView setNeedsDisplay:YES];
}

- (BOOL)becomeFirstResponder
{
    BOOL result = [super becomeFirstResponder];
    if (result && [[[self selectedRanges] objectAtIndex:0] rangeValue].length == 0)
        [self setSelectedRange:NSMakeRange([[self string] length], 0)];
    return result;
}

- (BOOL)resignFirstResponder
{
    // TODO: resign first responder may return NO. we probably need to handle this to do not change selection.
    [self setSelectedRange:NSMakeRange(0, 0)];
    return [super resignFirstResponder];
}

@end



@implementation WLGlassHudTextView
@synthesize postsSizeChangedNotifications;

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect])
    {
        NSRect textViewFrame = [self convertRect:frameRect fromView:[self superview]];
        textViewFrame.origin.y += _WLTextViewTopOffset;
        textViewFrame.size.height -= _WLTextViewTopOffset + _WLTextViewBottomOffset;
        textView = [[_WLGlassHudTextViewInternal alloc] initWithFrame:textViewFrame];
        [textView setDelegate:self];
        [textView setBackgroundColor:[NSColor clearColor]];
        textView.containerView = self;
        [self addSubview:textView];
        [textView release];
    }
    return self;
}

- (void)dealloc
{
    self.postsSizeChangedNotifications = NO;
    [super dealloc];
}

- (void)setPostsSizeChangedNotifications:(BOOL)flag
{
    postsSizeChangedNotifications = flag;
    if (!postsSizeChangedNotifications && _textViewFrameObserver != nil)
    {
        [textView setPostsFrameChangedNotifications:NO];
        [[NSNotificationCenter defaultCenter] removeObserver:_textViewFrameObserver];
        _textViewFrameObserver = nil;
    }
    else if (postsSizeChangedNotifications && _textViewFrameObserver == nil)
    {
        _textViewFrameObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSViewFrameDidChangeNotification
                                                                                   object:textView
                                                                                    queue:nil
                                                                               usingBlock:^(NSNotification *arg1)
        {
            _WLGlassHudTextViewInternal *view = [arg1 object];
            if ([view frame].size.height != [view minSize].height)
            {
                CGFloat heightDiff = [view frame].size.height - [self frame].size.height + _WLTextViewTopOffset + _WLTextViewBottomOffset;
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSValue valueWithSize:NSMakeSize(0.0, heightDiff)]
                                                                     forKey:WLSizeDiff];
                [[NSNotificationCenter defaultCenter] postNotificationName:WLViewSizeDidChangeNotification
                                                                    object:self
                                                                  userInfo:userInfo];
            }
            else
                [self setNeedsDisplay:YES];
        }];
        [textView setPostsFrameChangedNotifications:YES];
    }
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    if ([textView drawsBackground])
    {
        NSDrawNinePartImage([self bounds],
                            [NSImage imageNamed:@"glass-hud-textview-top-left"],
                            [NSImage imageNamed:@"glass-hud-textview-top"],
                            [NSImage imageNamed:@"glass-hud-textview-top-right"],
                            [NSImage imageNamed:@"glass-hud-textview-middle-left"],
                            [NSImage imageNamed:@"glass-hud-textview-middle"],
                            [NSImage imageNamed:@"glass-hud-textview-middle-right"],
                            [NSImage imageNamed:@"glass-hud-textview-bottom-left"],
                            [NSImage imageNamed:@"glass-hud-textview-bottom"],
                            [NSImage imageNamed:@"glass-hud-textview-bottom-right"],
                            NSCompositeSourceOver,
                            1.0,
                            YES);
    }
}


#pragma mark Message forwarding

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return ([super respondsToSelector:aSelector] || [textView respondsToSelector:aSelector]);
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return textView;
}


# pragma mark NSTextViewDelegate

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
    if (aSelector == @selector(insertTab:))
    {
        [[self window] selectNextKeyView:self];
        return YES;
    }
    else if (aSelector == @selector(insertBacktab:))
    {
        [[self window] selectPreviousKeyView:self];
        return YES;
    }
    else {
        return NO;
    }
}

@end
