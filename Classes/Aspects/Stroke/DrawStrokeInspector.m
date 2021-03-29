
#import "DrawStrokeInspector.h"

#import "DrawFunctions.h"
#import "DrawStroke.h"
#import "DrawStrokeDash.h"
#import "DrawStrokeRibbonInspector.h"
#import "DrawThicknessControl.h"

#import <AJRFoundation/AJRFoundation.h>
#import <AJRInterface/AJRInterface.h>

@implementation DrawStrokeInspector

+ (void)initialize {
    [[NSUserDefaults standardUserDefaults] registerDefaults:
     [NSDictionary dictionaryWithObjectsAndKeys:
      // The Compose Defaults
      @"Line", DrawStrokeKey,
      nil
      ]
     ];
}

- (id)init {
    self = [super init];

    strokes = [[NSMutableArray alloc] init];

    return self;
}


- (NSString *)title {
    return @"Stroke";
}

- (void)addStroke:(Class)aClass {
    AJRPrintf(@"Stroke: %@\n", aClass);
    [strokes addObject:aClass];
}

- (NSString *)aspectKey {
    return DrawStrokeAspectKey;
}

- (DrawAspectPriority)aspectPriority {
    return DrawAspectPriorityForeground;
}

- (Class)inspectedClass {
    return [DrawStroke class];
}

- (DrawStrokeDash *)_syncDashPopUpWithString:(NSString *)string {
    NSMutableArray *dashStrings = (NSMutableArray *)[DrawStrokeDash defaultDashes];
    NSInteger x;
    DrawStrokeDash *newDash;

    for (x = 0; x < (const NSInteger)[dashStrings count]; x++) {
        if ([[[dashStrings objectAtIndex:x] description] isEqualToString:string]) {
            [[dashes cellAtRow:0 column:0] selectItemWithTag:x];
            return [dashStrings objectAtIndex:x];
        }
    }

    newDash = [[DrawStrokeDash alloc] initWithString:string];

    [dashStrings addObject:newDash];
    [[NSUserDefaults standardUserDefaults] setObject:[[dashStrings componentsJoinedByString:@","] componentsSeparatedByString:@","] forKey:DrawStrokeDashesKey];

    //	[[dashes cellAtRow:0 column:0] addItemWithImage:[newDash image]];
    [[dashes cellAtRow:0 column:0] selectItemWithTag:x];

    return newDash;
}

- (void)update {
    NSArray *selection = [self selection];
    DrawStroke *stroke = nil;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [self view];

    if ([selection count]) {
        stroke = nil; //(DrawStroke *)[[selection objectAtIndex:0] aspectForKey:[self aspectKey]];
    }

    if (stroke) {
        NSString *strokeName = [[stroke class] name];

        [colorWell setColor:[stroke color]];
        [thickness setFloatValue:[stroke width]];
        [thicknessText setFloatValue:[stroke width]];
        [[joinType cellAtRow:0 column:0] selectItemWithTag:[stroke lineJoin]];
        [[lineCap cellAtRow:0 column:0] selectItemWithTag:[stroke lineCap]];
        [[strokeType cellAtRow:0 column:0] selectItemWithTag:[self tagForStrokeNamed:strokeName]];
        [miterLimitText setFloatValue:[stroke miterLimit]];
        [miterLimitSlider setFloatValue:[stroke miterLimit]];
        [self _syncDashPopUpWithString:[stroke dash] ? [[stroke dash] description] : @""];

        [defaults setColor:[stroke color] forKey:DrawStrokeColorKey];
        [defaults setFloat:[stroke width] forKey:DrawStrokeWidthKey];
        [defaults setFloat:[stroke miterLimit] forKey:DrawStrokeMiterLimitKey];
        [defaults setInteger:[stroke lineJoin] forKey:DrawStrokeLineJoinKey];
        [defaults setInteger:[stroke lineCap] forKey:DrawStrokeLineCapKey];
        [defaults setObject:strokeName forKey:DrawStrokeKey];
        [defaults setObject:[stroke dash] ? [[stroke dash] description] : @"" forKey:DrawStrokeDashKey];
    } else {
        NSUInteger tag = [self tagForStrokeNamed:[defaults stringForKey:DrawStrokeKey]];

        if (tag == NSNotFound) {
            tag = [self tagForStrokeNamed:@"Line"];
            [defaults setObject:@"Line" forKey:DrawStrokeKey];
        }

        [colorWell setColor:[defaults colorForKey:DrawStrokeColorKey]];
        [thickness setFloatValue:[defaults floatForKey:DrawStrokeWidthKey]];
        [thicknessText setFloatValue:[defaults floatForKey:DrawStrokeWidthKey]];
        [[joinType cellAtRow:0 column:0] selectItemWithTag:[defaults integerForKey:DrawStrokeLineJoinKey]];
        [[lineCap cellAtRow:0 column:0] selectItemWithTag:[defaults integerForKey:DrawStrokeLineCapKey]];
        [[strokeType cellAtRow:0 column:0] selectItemWithTag:tag];
        [miterLimitText setFloatValue:[defaults floatForKey:DrawStrokeMiterLimitKey]];
        [miterLimitSlider setFloatValue:[defaults floatForKey:DrawStrokeMiterLimitKey]];
        [self _syncDashPopUpWithString:[defaults stringForKey:DrawStrokeDashKey]];
    }
}

- (void)setStrokeColor:(id)sender {
    [[NSUserDefaults standardUserDefaults] setColor:[sender color] forKey:DrawStrokeColorKey];
    [self setInspectedValue:[sender color] forKeyPath:@"color" creationCallback:DrawStrokeCreationBlock];
}

- (void)setStrokeThickness:(id)sender {
    CGFloat value = [sender floatValue];

    if (sender == thickness) {
        [thicknessText setFloatValue:[sender floatValue]];
    } else {
        if (value < 0.0) {
            value = 0.0;
            [thicknessText setFloatValue:value];
        }
        [thickness setFloatValue:value];
    }

    [[NSUserDefaults standardUserDefaults] setFloat:value forKey:DrawStrokeWidthKey];
    [self setInspectedFloat:value forKeyPath:@"width" creationCallback:DrawStrokeCreationBlock];
}

- (void)selectStrokeType:(id)sender {
    NSInteger tag = [[sender selectedCell] tag];
    NSInteger x;
    Class StrokeClass = [strokes objectAtIndex:tag];
    DrawStroke *newStroke, *oldStroke;
    NSArray *selection = [self selection];
    DrawGraphic *graphic;

    for (x = 0; x < (const NSInteger)[selection count]; x++) {
        graphic = [selection objectAtIndex:x];
        newStroke = [[StrokeClass alloc] initWithGraphic:graphic];
        oldStroke = nil; //(DrawStroke *)[[graphic aspectForKey:DrawStrokeAspectKey] retain];
        [graphic removeAspect:oldStroke];
        [newStroke setColor:[oldStroke color]];
        [graphic addAspect:newStroke withPriority:DrawAspectPriorityForeground];
    }

    [[NSUserDefaults standardUserDefaults] setObject:[StrokeClass name] forKey:DrawStrokeKey];
}

- (void)selectJoinType:(id)sender {
    NSInteger value = [[sender selectedCell] tag];

    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:DrawStrokeLineJoinKey];
    [self setInspectedInteger:value forKeyPath:@"lineJoin" creationCallback:DrawStrokeCreationBlock];
}

- (void)selectLineCap:(id)sender {
    NSInteger value = [[sender selectedCell] tag];

    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:DrawStrokeLineCapKey];
    [self setInspectedInteger:value forKeyPath:@"lineCap" creationCallback:DrawStrokeCreationBlock];
}

- (void)setJoinType:(NSMatrix *)aMatrix {
//	AJRToolCell		*cell;
//
//	[aMatrix setCellClass:[AJRToolCell class]];
//
//	cell = [[AJRToolCell alloc] initWithImages:[NSImage imageNamed:@"joinMiter"], [NSImage imageNamed:@"joinRound"], [NSImage imageNamed:@"joinBevel"], nil];
//	[cell setTriggerOnMouseDown:YES];
//	[cell setPopDirection:AJRPopVertical];
//	[cell setHighlightsBy:NSNoCellMask];
//	[cell setShowsStateBy:NSNoCellMask];
//
//	[aMatrix putCell:cell atRow:0 column:0];
//
//	joinType = aMatrix;
}

- (void)setLineCap:(NSMatrix *)aMatrix {
//	AJRToolCell		*cell;
//
//	[aMatrix setCellClass:[AJRToolCell class]];
//
//	cell = [[AJRToolCell alloc] initWithImages:[NSImage imageNamed:@"capButt"], [NSImage imageNamed:@"capRound"], [NSImage imageNamed:@"capSquare"], nil];
//	[cell setTriggerOnMouseDown:YES];
//	[cell setPopDirection:AJRPopVertical];
//	[cell setHighlightsBy:NSNoCellMask];
//	[cell setShowsStateBy:NSNoCellMask];
//
//	[aMatrix putCell:cell atRow:0 column:0];
//
    lineCap = aMatrix;
}

- (DrawAspect *)aspectWithGraphic:(DrawGraphic *)graphic {
    return [[[self strokeClass] alloc] initWithGraphic:graphic];
}

- (NSUInteger)tagForStrokeNamed:(NSString *)name {
    NSInteger x;

    for (x = 0; x < (const NSInteger)[strokes count]; x++) {
        if ([[(Class)[strokes objectAtIndex:x] name] isEqualToString:name]) return x;
    }

    return NSNotFound;
}

- (Class)strokeClassForName:(NSString *)name {
    NSInteger x;

    for (x = 0; x < (const NSInteger)[strokes count]; x++) {
        if ([[(Class)[strokes objectAtIndex:x] name] isEqualToString:name]) return [strokes objectAtIndex:x];
    }

    return Nil;
}

- (void)setStrokeType:(NSMatrix *)aMatrix {
//	AJRToolCell *cell;
//	NSMutableArray *images = [[NSMutableArray alloc] init];
//	NSInteger x;
//
//	[aMatrix setCellClass:[AJRToolCell class]];
//
//	for (x = 0; x < (const NSInteger)[strokes count]; x++) {
//		[images addObject:[[strokes objectAtIndex:x] image]];
//	}
//
//	cell = [[AJRToolCell alloc] initWithImageArray:images];
//	[cell setTriggerOnMouseDown:YES];
//	[cell setPopDirection:AJRPopVertical];
//	[cell setHighlightsBy:NSNoCellMask];
//	[cell setShowsStateBy:NSNoCellMask];
//
//	[aMatrix putCell:cell atRow:0 column:0];
//
//	[images release];
//
//	strokeType = aMatrix;
//
//	if ([strokes count] == 0) {
//		[strokeType setEnabled:NO];
//		[[strokeType cellAtRow:0 column:0] setEnabled:NO];
//	}
}

- (void)setDashes:(NSMatrix *)aMatrix {
//	AJRToolCell *cell;
//	NSMutableArray *images = [[NSMutableArray alloc] init];
//	NSInteger x;
//	NSArray *work = [DrawStroke dashes];
//
//	[aMatrix setCellClass:[AJRToolCell class]];
//
//	for (x = 0; x < (const NSInteger)[work count]; x++) {
//		[images addObject:[[work objectAtIndex:x] image]];
//	}
//
//	cell = [[AJRToolCell alloc] initWithImageArray:images];
//	[cell setTriggerOnMouseDown:YES];
//	[cell setPopDirection:AJRPopVertical];
//	[cell setHighlightsBy:NSNoCellMask];
//	[cell setShowsStateBy:NSNoCellMask];
//
//	[aMatrix putCell:cell atRow:0 column:0];
//
//	[images release];
//
//	dashes = aMatrix;
}

- (void)setStokeMiterLimit:(id)sender {
    CGFloat value;

    if (sender == miterLimitText) {
        value = [miterLimitText floatValue];
        if (value < 1.0) {
            value = 1.0;
        } else if (value > 200.0) {
            value = 200.0;
        }
        [miterLimitText setFloatValue:value];
        [miterLimitSlider setFloatValue:value];
    } else {
        value = (CGFloat)[miterLimitSlider intValue];
        [miterLimitText setFloatValue:value];
    }

    [[NSUserDefaults standardUserDefaults] setFloat:value forKey:DrawStrokeMiterLimitKey];
    [self setInspectedFloat:value forKeyPath:@"miterLimit" creationCallback:DrawStrokeCreationBlock];
}

- (void)selectDash:(id)sender {
    DrawStrokeDash *value = [[DrawStrokeDash defaultDashes] objectAtIndex:[[sender selectedCell] tag]];

    [[NSUserDefaults standardUserDefaults] setObject:[value description] forKey:DrawStrokeDashKey];
    [self setInspectedValue:value forKeyPath:@"dash" creationCallback:DrawStrokeCreationBlock];
}

- (Class)strokeClass {
    Class class = [self strokeClassForName:[[NSUserDefaults standardUserDefaults] stringForKey:DrawStrokeKey]];

    if (!class) {
        class = [self strokeClassForName:@"Line"];
    }

    return class;
}

- (void)_updateDashPreview {
    NSRect bounds = [newDashPreview bounds];
    NSImage *image;

    image = [NSImage ajr_imageWithSize:bounds.size scales:@[@(1.0), @(2.0)] flipped:NO colorSpace:nil commands:^(CGFloat scale) {
        AJRBezierPath *path;

        [[NSColor controlBackgroundColor] set];
        NSRectFill(bounds);
        [[NSColor blackColor] set];
        path = [[AJRBezierPath alloc] init];
        [self->_workDash addToPath:path];
        [path setLineWidth:1.0];
        [path moveToPoint:(NSPoint){9.0, 9.0}];
        [path relativeLineToPoint:(NSPoint){bounds.size.width - 18.0, 0.0}];
        [path stroke];

        [NSAffineTransform scaleBy:3.0];
        [path removeAllPoints];
        [path moveToPoint:(NSPoint){3.0, 9.0}];
        [path relativeLineToPoint:(NSPoint){(bounds.size.width / 3.0) - 6.0, 0.0}];
        [path stroke];
    }];
    newDashPreview.image = image;
}

- (void)createNewDashPattern:(id)sender {
    if (!_workDash) {
        _workDash = [[DrawStrokeDash alloc] initWithString:@""];
    } else {
        [_workDash setStringValue:@""];
    }

    [newDashWindow center];
    [newDashTextField setStringValue:@""];
    [self _updateDashPreview];
    [newDashWindow orderFront:self];

    if ([NSApp runModalForWindow:newDashWindow] == NSModalResponseOK) {
        DrawStrokeDash		*dash = [self _syncDashPopUpWithString:[newDashTextField stringValue]];

        [[NSUserDefaults standardUserDefaults] setObject:[dash description] forKey:DrawStrokeDashKey];
        [self setInspectedValue:dash forKeyPath:@"dash" creationCallback:DrawStrokeCreationBlock];
    }

    [newDashWindow orderOut:self];
}

- (void)ok:(id)sender {
    [NSApp stopModalWithCode:NSModalResponseOK];
}

- (void)cancel:(id)sender {
    [NSApp stopModalWithCode:NSModalResponseCancel];
}

- (void)controlTextDidChange:(NSNotification *)notification {
    [_workDash setStringValue:[newDashTextField stringValue]];
    [self _updateDashPreview];
}

@end
