//
//  WLGlassHudTextField.m
//  Blotter
//
//  Created by Ilya Kulakov on 24.04.12.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLGlassHudTextView.h"


static const CGFloat _WLTextViewTopOffset = 3.0;
static const CGFloat _WLTextViewBottomOffset = 7.0;

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
    // Move cursor to the end
    BOOL isBecome = [super becomeFirstResponder];
    if (isBecome)
    {
        if ([[[self selectedRanges] objectAtIndex:0] rangeValue].length == 0)
            [self setSelectedRange:NSMakeRange([[self string] length], 0)];
        [self setTextColor:[NSColor blackColor]];
    }
    return isBecome;
}

- (BOOL)resignFirstResponder
{
    [self setSelectedRange:NSMakeRange(0, 0)];
    [self setTextColor:[NSColor whiteColor]];
    return [super resignFirstResponder];
}

@end


@implementation WLGlassHudTextView
@synthesize postsSizeChangedNotifications;

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self != nil)
    {
        NSRect textViewFrame = [self convertRect:frameRect fromView:[self superview]];
        textViewFrame.origin.y += _WLTextViewTopOffset;
        textViewFrame.size.height -= _WLTextViewTopOffset + _WLTextViewBottomOffset;
        _textView = [[_WLGlassHudTextViewInternal alloc] initWithFrame:textViewFrame];
        [_textView setDelegate:self];
        [_textView setBackgroundColor:[NSColor clearColor]];
        [_textView setAllowsUndo:YES];
        [_textView setRichText:NO];
        [_textView setImportsGraphics:NO];
        [_textView setAllowsImageEditing:NO];
        [_textView setTextColor:[NSColor whiteColor]];
        _textView.containerView = self;
        [self addSubview:_textView];
        [_textView release];
    }
    return self;
}

- (void)awakeFromNib
{
    [_textView setNextKeyView:[self nextKeyView]];
    [self setNextKeyView:_textView];
}

- (BOOL)acceptsFirstResponder
{
    return NO;
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
        [_textView setPostsFrameChangedNotifications:NO];
        [[NSNotificationCenter defaultCenter] removeObserver:_textViewFrameObserver];
        _textViewFrameObserver = nil;
    }
    else if (postsSizeChangedNotifications && _textViewFrameObserver == nil)
    {
        _textViewFrameObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSViewFrameDidChangeNotification
                                                                                   object:_textView
                                                                                    queue:nil
                                                                               usingBlock:^(NSNotification *arg1)
        {
            _WLGlassHudTextViewInternal *view = [arg1 object];
            CGFloat heightDiff = [view frame].size.height - [self frame].size.height + _WLTextViewTopOffset + _WLTextViewBottomOffset;
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSValue valueWithSize:NSMakeSize(0.0, heightDiff)]
                                                                 forKey:WLSizeDiff];
            [[NSNotificationCenter defaultCenter] postNotificationName:WLViewSizeDidChangeNotification
                                                                object:self
                                                              userInfo:userInfo];
        }];
        [_textView setPostsFrameChangedNotifications:YES];
    }
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    if ([_textView drawsBackground])
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

- (NSSize)textViewSize
{
    return [_textView frame].size;
}

- (void)selectAll:(id)sender
{
    [_textView selectAll:sender];
    [[self window] makeFirstResponder:_textView];
}


#pragma mark Message forwarding

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return ([super respondsToSelector:aSelector] || [_textView respondsToSelector:aSelector]);
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return _textView;
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
