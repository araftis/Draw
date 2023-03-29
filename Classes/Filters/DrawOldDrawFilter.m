/*
 DrawOldDrawFilter.m
 Draw

 Copyright © 2022, AJ Raftis and Draw authors
 All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
 * Neither the name of Draw nor the names of its contributors may be
   used to endorse or promote products derived from this software without
   specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL AJ RAFTIS BE LIABLE FOR ANY DIRECT, INDIRECT,
 INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "DrawOldDrawFilter.h"

#import "DrawCircle.h"
#import "DrawImage.h"
#import "DrawPage.h"
#import "DrawPen.h"
#import "DrawDocument.h"
#import <Draw/Draw-Swift.h>

#import <AJRFoundation/AJRFoundation.h>
#import <AJRInterface/AJRInterface.h>

@implementation DrawOldDrawFilter

- (NSRect)frameFromGraphic:(NSDictionary *)graphic key:(NSString *)key {
    NSString *string = [graphic objectForKey:key];
    NSRect frame;
    NSArray *coordinates;

    coordinates = [string componentsSeparatedByString:@" "];
    if ([coordinates count] != 4) {
        AJRPrintf(@"%@: WARNING: Found a graphic with corrupt or no %@.\n", [self class], key);
        return NSZeroRect;
    }

    frame.origin.x = [[coordinates objectAtIndex:0] floatValue];
    frame.origin.y = [[coordinates objectAtIndex:1] floatValue];
    frame.size.width = [[coordinates objectAtIndex:2] floatValue];
    frame.size.height = [[coordinates objectAtIndex:3] floatValue];

    return frame;
}

- (NSRect)frameFromGraphic:(NSDictionary *)graphic {
    return [self frameFromGraphic:graphic key:@"Bounds"];
}

- (NSColor *)colorFromPropertyList:(id)plist {
    if ([plist isKindOfClass:[NSDictionary class]]) {
        NSString *colorSpaceName = [plist objectForKey:@"ColorSpace"];
        if ([colorSpaceName isEqualToString:@"NSCalibratedWhiteColorSpace"]) {
            return [NSColor colorWithCalibratedWhite:[[plist objectForKey:@"White"] floatValue]
                                               alpha:[[plist objectForKey:@"Alpha"] floatValue]];
        } else if ([colorSpaceName isEqualToString:@"NSCalibratedRGBColorSpace"]) {
            return [NSColor colorWithCalibratedRed:[[plist objectForKey:@"Red"] floatValue]
                                             green:[[plist objectForKey:@"Green"] floatValue]
                                              blue:[[plist objectForKey:@"Blue"] floatValue]
                                             alpha:[[plist objectForKey:@"Alpha"] floatValue]];
        } else if ([colorSpaceName isEqualToString:@"NSDeviceWhiteColorSpace"]) {
            return [NSColor colorWithDeviceWhite:[[plist objectForKey:@"White"] floatValue]
                                           alpha:[[plist objectForKey:@"Alpha"] floatValue]];
        } else if ([colorSpaceName isEqualToString:@"NSDeviceRGBColorSpace"]) {
            return [NSColor colorWithDeviceRed:[[plist objectForKey:@"Red"] floatValue]
                                         green:[[plist objectForKey:@"Green"] floatValue]
                                          blue:[[plist objectForKey:@"Blue"] floatValue]
                                         alpha:[[plist objectForKey:@"Alpha"] floatValue]];
        } else if ([colorSpaceName isEqualToString:@"NSDeviceCMYKColorSpace"]) {
            return [NSColor colorWithDeviceCyan:[[plist objectForKey:@"Cyan"] floatValue]
                                        magenta:[[plist objectForKey:@"Magenta"] floatValue]
                                         yellow:[[plist objectForKey:@"Yellow"] floatValue]
                                          black:[[plist objectForKey:@"Black"] floatValue]
                                          alpha:[[plist objectForKey:@"Alpha"] floatValue]];
        } else if ([colorSpaceName isEqualToString:@"NSNamedColorSpace"]) {
            return [NSColor colorWithCatalogName:[plist objectForKey:@"CId"]
                                       colorName:[plist objectForKey:@"NId"]];
        } else if ([colorSpaceName isEqualToString:@"Unknown"]) {
            return [NSKeyedUnarchiver ajr_unarchivedObjectWithData:[plist objectForKey:@"Data"] error:NULL];
        } else { // should never happen, maybe raise?
            return nil;
        }
    } else if ([plist isKindOfClass:[NSData class]]) {
        return plist ? [NSKeyedUnarchiver ajr_unarchivedObjectWithData:plist error:NULL] : nil;
    }

    return [NSColor blackColor];
}

- (void)initializeGraphic:(DrawGraphic *)graphic fromDictionary:(NSDictionary *)source {
    NSString *fillType = [source objectForKey:@"Filled"];
    DrawFill *fill = nil;
    DrawStroke *stroke = nil;
    NSString *value;

    fill = [[DrawFill alloc] initWithGraphic:graphic color:[self colorFromPropertyList:[source objectForKey:@"FillColor"]]];
    if ([fillType isEqualToString:@"Non-ZeroWindingRule"]) {
        [fill setWindingRule:AJRWindingRuleNonZero];
    } else {
        [fill setWindingRule:AJRWindingRuleEvenOdd];
    }
    if (fill) {
        [graphic addAspect:fill withPriority:DrawAspectPriorityBeforeChildren];
    }

    value = [source objectForKey:@"LineWidth"];
    if (![[source objectForKey:@"Class"] isEqualToString:@"TextGraphic"]) {
        stroke = [[DrawStroke alloc] initWithGraphic:graphic];
        [stroke setColor:[self colorFromPropertyList:[source objectForKey:@"LineColor"]]];
        if (value) {
            [stroke setWidth:[value floatValue]];
        } else {
            [stroke setWidth:0.0];
        }
        [stroke setLineCap:[[source objectForKey:@"LineCap"] intValue]];
        [stroke setLineJoin:[[source objectForKey:@"LineJoin"] intValue]];
        [graphic addAspect:stroke withPriority:DrawAspectPriorityBeforeChildren];
    }
}

- (DrawGraphic *)addRectangle:(NSDictionary *)rectangle {
    DrawRectangle *graphic;

    graphic = [[DrawRectangle alloc] initWithFrame:[self frameFromGraphic:rectangle]];
    [self initializeGraphic:graphic fromDictionary:rectangle];
    [[_view page] addGraphic:graphic];


    return graphic;
}

- (DrawGraphic *)addCircle:(NSDictionary *)rectangle {
    DrawCircle *graphic;

    graphic = [[DrawCircle alloc] initWithFrame:[self frameFromGraphic:rectangle]];
    [self initializeGraphic:graphic fromDictionary:rectangle];
    [[_view page] addGraphic:graphic];


    return graphic;
}

- (DrawGraphic *)addImage:(NSDictionary *)image {
    DrawRectangle *graphic;
    DrawImage *imageAspect;
    NSImage *imageFile;
    NSString *value;

    graphic = [[DrawRectangle alloc] initWithFrame:[self frameFromGraphic:image]];

    imageAspect = [[DrawImage alloc] initWithGraphic:graphic];
    [imageAspect setImageAlignment:NSImageAlignCenter];
    [imageAspect setImageScaling:NSImageScaleAxesIndependently];
    imageFile = [NSKeyedUnarchiver ajr_unarchivedObjectWithData:[NSData dataWithContentsOfURL:[_url URLByAppendingPathComponent:[image objectForKey:@"ImageFileName"]]] error:NULL];
    if (imageFile) {
        [imageFile setSize:[graphic frame].size];
        [imageAspect setImage:imageFile];
        [graphic addAspect:imageAspect withPriority:DrawAspectPriorityBeforeChildren];
        [[_view page] addGraphic:graphic];
    }

    value = [image objectForKey:@"OriginalSize"];
    if (value) {
        NSSize		size;
        NSArray		*parts = [value componentsSeparatedByString:@" "];

        size.width = [[parts objectAtIndex:0] floatValue];
        size.height = [[parts objectAtIndex:1] floatValue];
        [imageFile setNaturalSize:size];
    }

    return graphic;
}

- (DrawGraphic *)addText:(NSDictionary *)graphic {
    DrawRectangle *rectangle;
    DrawText *text;
    NSAttributedString *string;

    rectangle = [[DrawRectangle alloc] initWithFrame:[self frameFromGraphic:graphic]];

    if ([[graphic objectForKey:@"IsFormEntry"] hasPrefix:@"Y"]) {
        text = [[DrawFormEntry alloc] initWithGraphic:rectangle];
    } else {
        text = [[DrawText alloc] initWithGraphic:rectangle];
    }
    string = [[NSAttributedString alloc] initWithRTF:[graphic objectForKey:@"TheText"] documentAttributes:NULL];
    if (!string) {
    }
    [text setAttributedString:string];
    [text setLineFragmentPadding:5.0];

    [rectangle addAspect:text withPriority:DrawAspectPriorityAfterBackground];

    [[_view page] addGraphic:rectangle];

    return rectangle;
}

- (DrawGraphic *)addPen:(NSDictionary *)graphic {
    DrawPen *pen;
    NSInteger count;
    NSInteger index;
    NSArray *points;
    NSPoint point;
    NSRect frame, bounds;

    frame = [self frameFromGraphic:graphic key:@"BoundingBox"];
    bounds = [self frameFromGraphic:graphic key:@"Bounds"];
    pen = [[DrawPen alloc] initWithFrame:bounds];
    [self initializeGraphic:pen fromDictionary:graphic];

    count = [[graphic objectForKey:@"NumberOfPoints"] intValue];
    points = [graphic objectForKey:@"Points"];
    for (index = 0; index <= count; index++) {
        if (index == 0) {
            point.x = [[points objectAtIndex:index * 2 + 0] floatValue] - (frame.origin.x - bounds.origin.x);
            point.y = ((frame.origin.y - [[points objectAtIndex:index * 2 + 1] floatValue]) + bounds.origin.y) + (frame.origin.y - bounds.origin.y);
            [pen appendMoveToPoint:point];
        } else {
            point.x += [[points objectAtIndex:index * 2 + 0] floatValue];
            point.y += [[points objectAtIndex:index * 2 + 1] floatValue];
            [pen appendLineToPoint:point];
        }
    }
    [pen setClosed:YES];

    [[_view page] addGraphic:pen];

    return pen;
}

- (DrawGraphic *)addLine:(NSDictionary *)graphic {
    DrawPen *pen;
    NSRect frame;

    frame = [self frameFromGraphic:graphic];
    pen = [[DrawPen alloc] initWithFrame:frame];
    [self initializeGraphic:pen fromDictionary:graphic];
    [pen setClosed:NO];
    [[_view page] addGraphic:pen];

    return pen;
}

- (void)readPrintInfo {
    NSPrintInfo *printInfo = nil;
    NSData *value;

    value = [_dictionary objectForKey:@"PrintInfo"];
    if (value) {
        @try {
            printInfo = [NSKeyedUnarchiver ajr_unarchivedObjectWithData:value error:NULL];
        } @catch (NSException *localException) {
            AJRPrintf(@"Warning: Unable to read printInfo: %@\n", localException);
        }
    }
    if (!value) {
        printInfo = [[NSPrintInfo sharedPrintInfo] copy];
    }

    [_view setPrintInfo:printInfo];

    _pageRectangle.origin.x = 0.0;
    _pageRectangle.origin.y = 0.0;
    _pageRectangle.size = [printInfo paperSize];
}

- (void)readGraphics {
    NSDictionary *viewDictionary = [_dictionary objectForKey:@"View"];
    NSArray *graphics = [viewDictionary objectForKey:@"Graphics"];
    NSInteger x;
    NSDictionary *graphicDictionary;
    NSString *type;
    DrawGraphic *graphic;

    [_view setGridColor:[NSColor colorWithCalibratedWhite:[[viewDictionary objectForKey:@"GridGray"] floatValue] alpha:1.0]];
    [_view setGridSpacing:[[viewDictionary objectForKey:@"GridSize"] floatValue]];
    [_view setGridVisible:[[viewDictionary objectForKey:@"GridVisible"] hasPrefix:@"Y"]];

    for (x = [graphics count] - 1; x >= 0; x--) {
        graphicDictionary = [graphics objectAtIndex:x];
        type = [graphicDictionary objectForKey:@"Class"];

        if ([type isEqualToString:@"Rectangle"]) {
            graphic = [self addRectangle:graphicDictionary];
        } else if ([type isEqualToString:@"Image"]) {
            graphic = [self addImage:graphicDictionary];
        } else if ([type isEqualToString:@"TextGraphic"]) {
            graphic = [self addText:graphicDictionary];
        } else if ([type isEqualToString:@"Circle"]) {
            graphic = [self addCircle:graphicDictionary];
        } else if ([type isEqualToString:@"Pen"]) {
            graphic = [self addPen:graphicDictionary];
        } else if ([type isEqualToString:@"Scribble"]) {
            graphic = [self addPen:graphicDictionary];
        } else if ([type isEqualToString:@"Line"]) {
            graphic = [self addLine:graphicDictionary];
        } else {
            AJRPrintf(@"%@: WARNING: Unknown graphic class: %@\n", [self class], type);
            graphic = nil;
        }
        if (graphic && [[graphicDictionary objectForKey:@"Selected"] hasPrefix:@"Y"]) {
            [_selection addObject:graphic];
        }
    }
}

- (BOOL)readDocument:(DrawDocument *)document fromURL:(NSURL *)URL error:(NSError **)error {
    BOOL isDirectory;

    _view = document;
    _url = URL;
    _selection = [[NSMutableSet alloc] init];

    [[NSFileManager defaultManager] fileExistsAtPath:[_url path] isDirectory:&isDirectory];
    if (isDirectory) {
        _dictionary = [[NSDictionary alloc] initWithContentsOfURL:[_url URLByAppendingPathComponent:@"document.draw"]];
    } else {
        _dictionary = [[NSDictionary alloc] initWithContentsOfURL:_url];
    }

    [self readPrintInfo];
    [self readGraphics];

    for (id object in _selection) {
        [document addGraphicsToSelection:@[object]];
    }

    _dictionary = nil;
    _selection = nil;
    _view = nil;
    _url = nil;

    return YES;
}

@end
