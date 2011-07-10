//
//  WLCalendarTasksView.m
//  Blotter
//
//  Created by Ilya Kulakov on 07.07.11.
//  Copyright 2011 WireLoad. All rights reserved.
//

#import "WLCalendarTasksView.h"
#import "NSColor+CGColor.h"
#import "CATextLayer+WLStringSize.h"


static NSString* const _WLRootLayerName = @"root";

static NSString* const _WLTitleLayerName = @"title";

static NSString* const _WLScrollLayerName = @"scroll";

static NSString* const _WLTasksLayerName = @"task";


static NSString* const _WLOrderedSublayersKey = @"orderedSublayers";


@implementation WLCalendarTasksView
@synthesize dataSource;

- (void)awakeFromNib
{
    [self setupLayers];
}

- (void)dealloc
{
    [super dealloc];
}

- (void)viewWillStartLiveResize
{
    [self layer].needsDisplayOnBoundsChange = NO;
    [CATransaction setDisableActions:YES];
    [super viewWillStartLiveResize];
}

- (void)viewDidEndLiveResize
{
    [super viewDidEndLiveResize];
    [self layer].needsDisplayOnBoundsChange = YES;
    [[self layer] setNeedsDisplay];
    [CATransaction setDisableActions:NO];
}

- (void)setupLayers
{
    CALayer *rootLayer = [CALayer layer];
    rootLayer.delegate = self;
    rootLayer.name = _WLRootLayerName;
    rootLayer.needsDisplayOnBoundsChange = YES;
    rootLayer.layoutManager = [CAConstraintLayoutManager layoutManager];
    rootLayer.cornerRadius = 2.0f;
    rootLayer.masksToBounds = YES;
#ifdef DEBUG_LAYERS
    rootLayer.backgroundColor = [[NSColor blackColor] WL_CGColor];
#endif

    CATextLayer *titleLayer = [CATextLayer layer];
    titleLayer.name = _WLTitleLayerName;
    titleLayer.string = @"To Do List";
    [titleLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX
                                                         relativeTo:@"superlayer"
                                                          attribute:kCAConstraintMinX]];
    [titleLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintWidth
                                                         relativeTo:@"superlayer"
                                                          attribute:kCAConstraintWidth]];
    static const CGFloat TitleTopMargin = -5.0f;
    [titleLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY
                                                         relativeTo:@"superlayer"
                                                          attribute:kCAConstraintMaxY
                                                             offset:TitleTopMargin]];
    [titleLayer setActions:[NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNull null],  @"position",
                            [NSNull null],  @"bounds", nil]];
#ifdef DEBUG_LAYERS
    titleLayer.backgroundColor = [[NSColor greenColor] WL_CGColor];
#endif
    [rootLayer addSublayer:titleLayer];

    _tasksLayer = [CALayer layer];
    [_tasksLayer setValue:[NSMutableArray array] forKey:_WLOrderedSublayersKey];
    _tasksLayer.name = _WLTasksLayerName;
    _tasksLayer.layoutManager = self;
    _tasksLayer.masksToBounds = YES;
    static const CGFloat XMargin = 10.0f;
    [_tasksLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinX
                                                          relativeTo:@"superlayer"
                                                           attribute:kCAConstraintMinX
                                                              offset:XMargin]];
    [_tasksLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxX
                                                          relativeTo:@"superlayer"
                                                           attribute:kCAConstraintMaxX
                                                              offset:-XMargin]];
    static const CGFloat YMargin = -15.0f;
    [_tasksLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMaxY
                                                          relativeTo:_WLTitleLayerName
                                                           attribute:kCAConstraintMinY
                                                              offset:YMargin]];
    [_tasksLayer addConstraint:[CAConstraint constraintWithAttribute:kCAConstraintMinY
                                                          relativeTo:@"superlayer"
                                                           attribute:kCAConstraintMinY
                                                              offset:-YMargin]];
    [_tasksLayer setActions:[NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNull null], @"position",
                             [NSNull null], @"bounds",
                             [NSNull null], @"sublayers", nil]];
#ifdef DEBUG_LAYERS
    _tasksLayer.backgroundColor = [[NSColor yellowColor] WL_CGColor];
#endif
    [rootLayer addSublayer:_tasksLayer];

    [self reloadData];

    [self setLayer:rootLayer];
    [self setWantsLayer:YES];
}

- (CATextLayer *)newTaskLayerAtIndex:(NSUInteger)anIndex
{
    CalTask *task = [dataSource tasksView:self taskAtIndex:anIndex];
    CATextLayer *taskLayer = [[CATextLayer layer] retain];
    taskLayer.string = task.title;
    taskLayer.foregroundColor = [[[task calendar] color] WL_CGColor];
    taskLayer.name = task.uid;
    taskLayer.masksToBounds = YES;
    taskLayer.fontSize = 24.0f;
    taskLayer.wrapped = YES;
    taskLayer.truncationMode = kCATruncationEnd;
    CABasicAnimation *orderInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [orderInAnimation setFromValue:[NSNumber numberWithFloat:0.0]];
    [orderInAnimation setToValue:[NSNumber numberWithFloat:1.0]];
    [taskLayer setActions:[NSDictionary dictionaryWithObject:orderInAnimation forKey:kCAOnOrderIn]];
#ifdef DEBUG_LAYERS
    taskLayer.backgroundColor = [[NSColor redColor] WL_CGColor];
#endif
    return taskLayer;
}

- (void)reloadData
{
    _tasksLayer.sublayers = nil;
    [_tasksLayer setValue:[NSMutableArray array] forKey:_WLOrderedSublayersKey];
    for (NSUInteger i=0, size=[dataSource numberOfTasksInTasksView:self]; i<size; ++i)
    {
        [self insertTaskAtIndex:i];
    }
}

- (void)insertTaskAtIndex:(NSUInteger)anIndex
{
    CATextLayer *taskLayer = [self newTaskLayerAtIndex:anIndex];
    [_tasksLayer addSublayer:taskLayer];
    [[_tasksLayer valueForKey:_WLOrderedSublayersKey] insertObject:taskLayer atIndex:anIndex];
    [taskLayer release];
}

- (void)removeTaskAtIndex:(NSUInteger)anIndex
{
    NSMutableArray *orderedTaskLayers = [_tasksLayer valueForKey:_WLOrderedSublayersKey];
    CATextLayer *taskLayer = [orderedTaskLayers objectAtIndex:anIndex];
    [orderedTaskLayers removeObjectAtIndex:anIndex];
    [taskLayer removeFromSuperlayer];
}

- (void)updateTaskAtIndex:(NSUInteger)anIndex
{
    CalTask *task = [dataSource tasksView:self taskAtIndex:anIndex];
    CATextLayer *taskLayer = [[_tasksLayer valueForKey:_WLOrderedSublayersKey] objectAtIndex:anIndex];
    taskLayer.string = task.title;
    taskLayer.foregroundColor = [task.calendar.color WL_CGColor];
    [_tasksLayer setNeedsLayout];
}

- (void)moveTaskAtIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex
{
    if (oldIndex == newIndex)
        return;
    NSMutableArray *orderedTaskLayers = [_tasksLayer valueForKey:_WLOrderedSublayersKey];
    CalTask *movable = [orderedTaskLayers objectAtIndex:oldIndex];
    [orderedTaskLayers removeObjectAtIndex:oldIndex];
    [orderedTaskLayers insertObject:movable atIndex:newIndex];
    [_tasksLayer setNeedsLayout];
}


#pragma mark CALayerDelegate

- (void)displayLayer:(CALayer *)layer
{
    NSParameterAssert([layer.name isEqualToString:_WLRootLayerName]);
#ifndef DEBUG_LAYERS
    NSRect layerBounds = NSRectFromCGRect(layer.bounds);
    NSSize layerSize = [self convertSizeToBase:layerBounds.size];
    NSLog(@"%@", NSStringFromSize(layerSize));
    NSBitmapImageRep *backgroundImageRep = [[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                                    pixelsWide:layerSize.width
                                                                                    pixelsHigh:layerSize.height
                                                                                 bitsPerSample:8
                                                                               samplesPerPixel:4
                                                                                      hasAlpha:YES
                                                                                      isPlanar:NO
                                                                                colorSpaceName:NSCalibratedRGBColorSpace
                                                                                   bytesPerRow:0
                                                                                  bitsPerPixel:0] autorelease];
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:backgroundImageRep];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:context];
    [[NSColor colorWithCalibratedRed:101.0f/255.0f green:161.0f/255.0f blue:165.0f/255.0f alpha:0.13f] set];
    NSRectFill(NSMakeRect(0, 0, layerBounds.size.width, layerBounds.size.height));
    NSColor *startingColor = [NSColor clearColor];
    NSColor *endingColor = [NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:0.15f];
    NSGradient *transparentGradient = [[[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor] autorelease];
    [transparentGradient drawInRect:layerBounds angle:90];
    [NSGraphicsContext restoreGraphicsState];
    layer.contents = (id)[backgroundImageRep CGImage];
#endif
}


#pragma mark CALayoutManager

- (void)layoutSublayersOfLayer:(CATextLayer *)layer
{
    NSParameterAssert([layer.name isEqualToString:_WLTasksLayerName]);
    CGSize layerSize = layer.bounds.size;
    CGFloat top = layerSize.height;
    static const CGFloat TopMargin = 20.0f;
    static const CGFloat MaxHeight = 120.0f;
    for (CATextLayer *taskLayer in [layer valueForKey:_WLOrderedSublayersKey])
    {
        CGFloat preferredHeight = MIN([taskLayer WL_maxStringHeightForWidth:layerSize.width], MaxHeight);
        taskLayer.frame = CGRectMake(0.0f, top - preferredHeight, layerSize.width, preferredHeight);
        top -= preferredHeight + TopMargin;
    }
}

@end
