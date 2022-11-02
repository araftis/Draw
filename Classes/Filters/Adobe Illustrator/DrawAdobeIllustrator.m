/*
 DrawAdobeIllustrator.m
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

#import "DrawAdobeIllustrator.h"

#import "DrawPage.h"
#import "DrawPen.h"
#import "DrawRectangle.h"
#import "DrawDocument.h"
#import <Draw/Draw-Swift.h>

#import <AJRFoundation/AJRFoundation.h>
#import <AJRInterfaceFoundation/AJRInterfaceFoundation.h>

@implementation DrawAdobeIllustrator

- (id)init {
    if ((self = [super init])) {
        stack = [[NSMutableArray alloc] init];
        groupStack = [[NSMutableArray alloc] init];
        separators = [NSCharacterSet characterSetWithCharactersInString:@" ])"];
    }
    return self;
}


- (void)readProlog {
    NSString *line;
    
    while (YES) {
        line = [file readLineReturningError:NULL];
        if (!line) break;
        if ([line hasPrefix:@"%%EndProlog"]) break;
    }
}

- (void)readSetup {
    NSString *line;
    
    while (1) {
        line = [file readLineReturningError:NULL];
        if (!line) break;
        if ([line hasPrefix:@"%%EndSetup"]) break;
    }
}

- (void)readHeader {
    NSString *line;
    
    while (1) {
        line = [file readLineReturningError:NULL];
        if (!line) break;
        if ([line hasPrefix:@"%%BoundingBox:"]) {
            NSArray *parts = [line componentsSeparatedByString:@" "];
            NSPrintInfo *printInfo;
            
            boundingBox.origin.x = [[parts objectAtIndex:1] floatValue];
            boundingBox.origin.y = [[parts objectAtIndex:2] floatValue];
            boundingBox.size.width = [[parts objectAtIndex:3] floatValue] - boundingBox.origin.x;
            boundingBox.size.height = [[parts objectAtIndex:4] floatValue] - boundingBox.origin.y;
            
            printInfo = [view printInfo];
            [printInfo setPaperSize:boundingBox.size];
        }
        if ([line hasPrefix:@"%%EndComments"]) break;
    }
}

- (NSArray *)arrayFromString:(NSString *)aString {
    NSRange range, subrange;
    NSInteger length = [aString length];
    unichar character;
    NSMutableArray *array = [NSMutableArray array];
    
    range.location = 0;
    range.length = length - range.location;
    
    while (range.location < length) {
        character = [aString characterAtIndex:range.location];
        if (character == '-' || (character >= '0' && character <= '9')) {
            NSNumber *value = nil;
            subrange = [aString rangeOfCharacterFromSet:separators options:0 range:range];
            if (subrange.location == NSNotFound) {
                value = [NSNumber numberWithDouble:[[aString substringFromIndex:range.location] doubleValue]];
                range.location = length;
                range.length = 0;
            } else {
                value = [NSNumber numberWithDouble:[[aString substringWithRange:subrange] doubleValue]];
                range.location = subrange.location + subrange.length;
                range.length = length - range.location;
            }
            [array addObject:value];
        } else if (character == '[') {
            subrange = [aString rangeOfString:@"]" options:0 range:range];
            if (subrange.location == NSNotFound) {
                [NSException raise:@"Stupid Programmer Exception" format:@"Don't handle multiline arrays!"];
            }
            
            [array addObject:[self arrayFromString:[aString substringWithRange:(NSRange){range.location + 1, subrange.location - (range.location + 1)}]]];
        } else if (character == '(') {
            NSInteger		start = range.location + 1;
            NSInteger		opens = 0;
            while (range.location < length) {
                subrange = [aString rangeOfString:@"(" options:0 range:range];
                if (subrange.location == NSNotFound) break;
                opens++;
                range.location = subrange.location;
                range.length = length - range.location;
            }
            while ((range.location < length) && (opens >= 0)) {
                subrange = [aString rangeOfString:@")" options:0 range:range];
                if (subrange.location == NSNotFound) break;
                opens--;
                range.location = subrange.location;
                range.length = length - range.location;
            }
            
            if (subrange.location == NSNotFound) {
                [stack addObject:[aString substringWithRange:(NSRange){start, range.location}]];
            } else {
                [stack addObject:[aString substringWithRange:(NSRange){start, (subrange.location + subrange.length) - start}]];
            }
        }
    }
    
    return array;
}

- (NSColor *)namedColor:(NSString *)name {
    return nil;
}

- (void)createGraphicWithFill:(BOOL)fillFlag stroke:(BOOL)strokeFlag {
    DrawPen *pen;
    DrawColorFill *fill = nil;
    DrawStroke *stroke = nil;
    DrawRectangle *group;
    
    pen = [[DrawPen alloc] initWithFrame:[path controlPointBounds] path:path];
    if (fillFlag) {
        if (aiFlags.winding) {
            fill = [[DrawColorFill alloc] initWithGraphic:pen];
            [fill setColor:fillColor];
            [fill setWindingRule:AJRWindingRuleEvenOdd];
        } else {
            fill = [[DrawColorFill alloc] initWithGraphic:pen];
            [fill setColor:fillColor];
            [fill setWindingRule:AJRWindingRuleNonZero];
        }
        [pen addAspect:fill withPriority:DrawAspectPriorityBeforeChildren];
    }
    
    if (strokeFlag) {
        stroke = [[DrawStroke alloc] initWithGraphic:pen];
        [stroke setColor:strokeColor];
        [stroke setWidth:lineWidth];
        [stroke setLineCap:lineCap];
        [stroke setLineJoin:lineJoin];
        [stroke setMiterLimit:miterLimit];
        [pen addAspect:stroke withPriority:DrawAspectPriorityBeforeChildren];
    }
    
    group = [groupStack lastObject];
    if (group) {
        [group addSubgraphic:pen];
    } else {
        [[view page] addGraphic:pen];
    }
    
    path = nil;
}

- (void)createText {
    DrawRectangle	*rectangle;
    DrawText	*text;
    NSRect			textRect;
    
    textRect.origin = textOrigin;
    textRect.size = [string size];
    textRect.size.width += 1.0;
    textRect.origin.y -= textRect.size.height;
    
    rectangle = [[DrawRectangle alloc] initWithFrame:textRect];
    text = [[DrawText alloc] initWithGraphic:rectangle text:string];
    [rectangle addAspect:text withPriority:DrawAspectPriorityAfterBackground];
    
    [[view page] addGraphic:rectangle];
    
    path = nil;
}

- (NSPoint)pointForStackLocation:(NSInteger)offset {
    CGFloat		x = [[stack objectAtIndex:[stack count] - offset] intValue];
    CGFloat		y = [[stack objectAtIndex:[stack count] - (offset - 1)] intValue];
    NSPoint	point;
    
    point.x = x - boundingBox.origin.x;
    point.y = boundingBox.size.height - (y - boundingBox.origin.y);
#if !defined(WIN32) && !defined(MacOSX)
    if ((point.x == NAN) || (point.y == NAN)) {
        AJRPrintf(@"WARNING: point at offset %d has a NaN\n", offset);
    }
#endif
    AJRPrintf(@"%@\n", NSStringFromPoint(point));
    
    return point;
}

- (void)processCommand:(NSString *)command {
    if ([command isEqualToString:@"d"]) {
        dashPhase = [[stack lastObject] doubleValue]; [stack removeLastObject];
        dashArray = [stack lastObject]; [stack removeLastObject];
    } else if ([command isEqualToString:@"A"]) {
        aiFlags.locked = [[stack lastObject] boolValue]; [stack removeLastObject];
    } else if ([command isEqualToString:@"i"]) {
        flatness = [[stack lastObject] doubleValue]; [stack removeLastObject];
    } else if ([command isEqualToString:@"D"]) {
        aiFlags.winding = [[stack lastObject] boolValue]; [stack removeLastObject];
    } else if ([command isEqualToString:@"j"]) {
        lineJoin = [[stack lastObject] intValue]; [stack removeLastObject];
    } else if ([command isEqualToString:@"J"]) {
        lineCap = [[stack lastObject] intValue]; [stack removeLastObject];
    } else if ([command isEqualToString:@"M"]) {
        miterLimit = [[stack lastObject] doubleValue]; [stack removeLastObject];
    } else if ([command isEqualToString:@"w"]) {
        lineWidth = [[stack lastObject] doubleValue]; [stack removeLastObject];
    } else if ([command isEqualToString:@"g"]) {
        fillColor = [NSColor colorWithCalibratedWhite:[[stack lastObject] doubleValue] alpha:1.0];
        [stack removeLastObject];
    } else if ([command isEqualToString:@"G"]) {
        strokeColor = [NSColor colorWithCalibratedWhite:[[stack lastObject] doubleValue] alpha:1.0];
        [stack removeLastObject];
    } else if ([command isEqualToString:@"k"]) {
        fillColor = [NSColor colorWithDeviceCyan:[[stack objectAtIndex:[stack count] - 4] doubleValue]
                                         magenta:[[stack objectAtIndex:[stack count] - 3] doubleValue]
                                          yellow:[[stack objectAtIndex:[stack count] - 2] doubleValue]
                                           black:[[stack objectAtIndex:[stack count] - 1] doubleValue]
                                           alpha:1.0];
        [stack removeLastObject]; [stack removeLastObject]; [stack removeLastObject]; [stack removeLastObject];
    } else if ([command isEqualToString:@"K"]) {
        strokeColor = [NSColor colorWithDeviceCyan:[[stack objectAtIndex:[stack count] - 4] doubleValue]
                                           magenta:[[stack objectAtIndex:[stack count] - 3] doubleValue]
                                            yellow:[[stack objectAtIndex:[stack count] - 2] doubleValue]
                                             black:[[stack objectAtIndex:[stack count] - 1] doubleValue]
                                             alpha:1.0];
        [stack removeLastObject]; [stack removeLastObject]; [stack removeLastObject]; [stack removeLastObject];
    } else if ([command isEqualToString:@"x"]) {
        NSColor		*temp;
        [stack removeLastObject];
        temp = [self namedColor:[stack lastObject]];
        if (temp) {
            fillColor = temp;
            [stack removeLastObject];
        } else {
            fillColor = [NSColor colorWithDeviceCyan:[[stack objectAtIndex:[stack count] - 4] doubleValue]
                                             magenta:[[stack objectAtIndex:[stack count] - 3] doubleValue]
                                              yellow:[[stack objectAtIndex:[stack count] - 2] doubleValue]
                                               black:[[stack objectAtIndex:[stack count] - 1] doubleValue]
                                               alpha:1.0];
        }
        [stack removeLastObject]; [stack removeLastObject]; [stack removeLastObject]; [stack removeLastObject];
    } else if ([command isEqualToString:@"X"]) {
        NSColor		*temp;
        [stack removeLastObject];
        temp = [self namedColor:[stack lastObject]];
        if (temp) {
            strokeColor = temp;
            [stack removeLastObject];
        } else {
            strokeColor = [NSColor colorWithDeviceCyan:[[stack objectAtIndex:[stack count] - 4] doubleValue]
                                               magenta:[[stack objectAtIndex:[stack count] - 3] doubleValue]
                                                yellow:[[stack objectAtIndex:[stack count] - 2] doubleValue]
                                                 black:[[stack objectAtIndex:[stack count] - 1] doubleValue]
                                                 alpha:1.0];
        }
        [stack removeLastObject]; [stack removeLastObject]; [stack removeLastObject]; [stack removeLastObject];
    } else if ([command isEqualToString:@"p"]) {
        AJRPrintf(@"We don't handle patterns yet. See page 27 of Adobe Illustrator 3.0 spec.\n");
    } else if ([command isEqualToString:@"P"]) {
        AJRPrintf(@"We don't handle patterns yet. See page 28 of Adobe Illustrator 3.0 spec.\n");
    } else if ([command isEqualToString:@"O"]) {
        aiFlags.overprintFill = [[stack lastObject] boolValue]; [stack removeLastObject];
    } else if ([command isEqualToString:@"R"]) {
        aiFlags.overprintStroke = [[stack lastObject] boolValue]; [stack removeLastObject];
    } else if ([command isEqualToString:@"u"]) {
        DrawRectangle		*group;
        group = [[DrawRectangle alloc] initWithFrame:NSZeroRect];
        [group removeAllAspects];
        [groupStack addObject:group];
    } else if ([command isEqualToString:@"U"]) {
        DrawRectangle		*group = [groupStack lastObject];
        DrawRectangle		*previousGroup;
        
        [groupStack removeLastObject];
        previousGroup = [groupStack lastObject];
        
        if (previousGroup) {
            [previousGroup addSubgraphic:group];
        } else {
            [[view page] addGraphic:group];
        }
    } else if ([command isEqualToString:@"m"]) {
        if (!path) {
            path = [[AJRBezierPath alloc] init];
        }
        [path moveToPoint:[self pointForStackLocation:2]];
        [stack removeLastObject]; [stack removeLastObject];
    } else if ([command isEqualToString:@"l"]) {
        [path lineToPoint:[self pointForStackLocation:2]];
        [stack removeLastObject]; [stack removeLastObject];
    } else if ([command isEqualToString:@"L"]) {
        [path lineToPoint:[self pointForStackLocation:2]];
        [stack removeLastObject]; [stack removeLastObject];
    } else if ([command isEqualToString:@"c"]) {
        [path curveToPoint:[self pointForStackLocation:2] controlPoint1:[self pointForStackLocation:6] controlPoint2:[self pointForStackLocation:4]];
        [stack removeLastObject]; [stack removeLastObject];
        [stack removeLastObject]; [stack removeLastObject];
        [stack removeLastObject]; [stack removeLastObject];
    } else if ([command isEqualToString:@"C"]) {
        [path curveToPoint:[self pointForStackLocation:2] controlPoint1:[self pointForStackLocation:6] controlPoint2:[self pointForStackLocation:4]];
        [stack removeLastObject]; [stack removeLastObject];
        [stack removeLastObject]; [stack removeLastObject];
        [stack removeLastObject]; [stack removeLastObject];
    } else if ([command isEqualToString:@"v"]) {
        AJRPrintf(@"We don't handle two point beziers yet. See page 31 of Adobe Illustrator 3.0 spec.\n");
    } else if ([command isEqualToString:@"V"]) {
        AJRPrintf(@"We don't handle two point beziers yet. See page 31 of Adobe Illustrator 3.0 spec.\n");
    } else if ([command isEqualToString:@"y"]) {
        AJRPrintf(@"We don't handle two point beziers yet. See page 31 of Adobe Illustrator 3.0 spec.\n");
    } else if ([command isEqualToString:@"Y"]) {
        AJRPrintf(@"We don't handle two point beziers yet. See page 31 of Adobe Illustrator 3.0 spec.\n");
    } else if ([command isEqualToString:@"N"]) {
        AJRPrintf(@"We don't handle hidden paths yet. See page 31 of Adobe Illustrator 3.0 spec.\n");
    } else if ([command isEqualToString:@"n"]) {
        AJRPrintf(@"We don't handle hidden paths yet. See page 31 of Adobe Illustrator 3.0 spec.\n");
    } else if ([command isEqualToString:@"F"]) {
        [self createGraphicWithFill:YES stroke:NO];
    } else if ([command isEqualToString:@"f"]) {
        [path closePath];
        [self createGraphicWithFill:YES stroke:NO];
    } else if ([command isEqualToString:@"S"]) {
        [self createGraphicWithFill:NO stroke:YES];
    } else if ([command isEqualToString:@"s"]) {
        [path closePath];
        [self createGraphicWithFill:NO stroke:YES];
    } else if ([command isEqualToString:@"B"]) {
        [self createGraphicWithFill:YES stroke:YES];
    } else if ([command isEqualToString:@"b"]) {
        [path closePath];
        [self createGraphicWithFill:YES stroke:YES];
    } else if ([command isEqualToString:@"q"]) {
        AJRPrintf(@"We don't handle masks yet. See page 34 of Adobe Illustrator 3.0 spec.\n");
    } else if ([command isEqualToString:@"Q"]) {
        AJRPrintf(@"We don't handle masks yet. See page 34 of Adobe Illustrator 3.0 spec.\n");
    } else if ([command isEqualToString:@"H"]) {
        AJRPrintf(@"We don't handle masks yet. See page 34 of Adobe Illustrator 3.0 spec.\n");
    } else if ([command isEqualToString:@"h"]) {
        AJRPrintf(@"We don't handle masks yet. See page 34 of Adobe Illustrator 3.0 spec.\n");
    } else if ([command isEqualToString:@"W"]) {
        AJRPrintf(@"We don't handle masks yet. See page 34 of Adobe Illustrator 3.0 spec.\n");
    } else if ([command isEqualToString:@"*u"]) {
        AJRPrintf(@"We don't handle compound paths yet. See page 33 of Adobe Illustrator 3.0 spec.\n");
    } else if ([command isEqualToString:@"*U"]) {
        AJRPrintf(@"We don't handle compound paths yet. See page 33 of Adobe Illustrator 3.0 spec.\n");
    } else if ([command isEqualToString:@"To"]) {
        textType = [[stack lastObject] intValue]; [stack removeLastObject];
        
        paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopyWithZone:nil];
        
        if (!attributes) {
            attributes = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                          [NSFont userFontOfSize:12.0], NSFontAttributeName,
                          fillColor, NSForegroundColorAttributeName,
                          [NSNumber numberWithInt:0], NSSuperscriptAttributeName,
                          [NSNumber numberWithFloat:0.0], NSBaselineOffsetAttributeName,
                          [NSNumber numberWithFloat:0.0], NSKernAttributeName,
                          [NSNumber numberWithInt:1], NSLigatureAttributeName,
                          paragraphStyle, NSParagraphStyleAttributeName,
                          nil];
        }
        string = [[NSMutableAttributedString alloc] initWithString:@"" attributes:attributes];
    } else if ([command isEqualToString:@"TO"]) {
        [self createText];
        textType = -1;
    } else if ([command isEqualToString:@"Tp"]) {
        textOffset = [[stack lastObject] floatValue]; [stack removeLastObject];
        textOrigin = [self pointForStackLocation:2];
        [stack removeLastObject];
        [stack removeLastObject];
        [stack removeLastObject];
        [stack removeLastObject];
        [stack removeLastObject];
        [stack removeLastObject];
    } else if ([command isEqualToString:@"TP"]) {
    } else if ([command isEqualToString:@"Tm"]) {
        AJRPrintf(@"Tm: 44\n");
        [stack removeLastObject];
    } else if ([command isEqualToString:@"Td"]) {
        [[string mutableString] appendString:@"\n"];
        [stack removeLastObject]; [stack removeLastObject];
    } else if ([command isEqualToString:@"T*"]) {
        [[string mutableString] appendString:@"\n"];
    } else if ([command isEqualToString:@"TR"]) {
        AJRPrintf(@"TR: 45\n");
    } else if ([command isEqualToString:@"Tr"]) {
        textRenderingType = [[stack lastObject] intValue]; [stack removeLastObject];
    } else if ([command isEqualToString:@"Tf"]) {
        NSString		*fontName;
        CGFloat			fontSize;
        NSFont		*font;
        
        fontSize = [[stack lastObject] floatValue]; [stack removeLastObject];
        fontName = [stack lastObject]; [stack removeLastObject];
        
        font = [NSFont fontWithName:[fontName substringFromIndex:2] size:fontSize];
        if (font) {
            [attributes setObject:font forKey:NSFontAttributeName];
        }
        
    } else if ([command isEqualToString:@"Ta"]) {
        NSInteger	alignment = [[stack lastObject] intValue];
        
        switch (alignment) {
            case 0:
                [paragraphStyle setAlignment:NSTextAlignmentLeft];
                break;
            case 1:
                [paragraphStyle setAlignment:NSTextAlignmentCenter];
                break;
            case 2:
                [paragraphStyle setAlignment:NSTextAlignmentRight];
                break;
            case 3:
                [paragraphStyle setAlignment:NSTextAlignmentJustified];
                break;
            case 4:
                [paragraphStyle setAlignment:NSTextAlignmentNatural];
                break;
        }
        
        [stack removeLastObject];
    } else if ([command isEqualToString:@"Tl"]) {
        CGFloat	paragraphLeading;
        CGFloat lineLeading;
        
        paragraphLeading = [[stack lastObject] floatValue]; [stack removeLastObject];
        lineLeading = [[stack lastObject] floatValue]; [stack removeLastObject];
        
        [paragraphStyle setLineSpacing:lineLeading];
        [paragraphStyle setParagraphSpacing:paragraphLeading];
    } else if ([command isEqualToString:@"Tt"]) {
        CGFloat		base = [@"-" sizeWithAttributes:attributes].width;
        CGFloat		value;
        
        value = [[stack lastObject] doubleValue] / 1000.0; [stack removeLastObject];
        [attributes setObject:[NSNumber numberWithDouble:value * base] forKey:NSKernAttributeName];
    } else if ([command isEqualToString:@"TW"]) {
        AJRPrintf(@"TW: Ignoring (46)\n");
        [stack removeLastObject];
        [stack removeLastObject];
        [stack removeLastObject];
    } else if ([command isEqualToString:@"Tw"]) {
        AJRPrintf(@"Tw: Ignoring (46)\n");
        [stack removeLastObject];
    } else if ([command isEqualToString:@"TC"]) {
        AJRPrintf(@"TC: Ignoring (46)\n");
        [stack removeLastObject];
        [stack removeLastObject];
        [stack removeLastObject];
    } else if ([command isEqualToString:@"Tc"]) {
        AJRPrintf(@"Tc: Ignoring (47)\n");
        [stack removeLastObject];
    } else if ([command isEqualToString:@"Ts"]) {
        AJRPrintf(@"Ts: Ignoring (47)\n");
        [stack removeLastObject];
    } else if ([command isEqualToString:@"Ti"]) {
        NSInteger	tailIndent;
        NSInteger	firstLineIndent;
        NSInteger	headIndent;
        
        tailIndent = [[stack lastObject] floatValue]; [stack removeLastObject];
        firstLineIndent = [[stack lastObject] floatValue]; [stack removeLastObject];
        headIndent = [[stack lastObject] floatValue]; [stack removeLastObject];
        
        [paragraphStyle setFirstLineHeadIndent:firstLineIndent];
        [paragraphStyle setHeadIndent:headIndent];
        [paragraphStyle setTailIndent:-tailIndent];
    } else if ([command isEqualToString:@"Tz"]) {
        double		percent;
        
        percent = [[stack lastObject] floatValue]; [stack removeLastObject];
        [attributes setObject:[NSNumber numberWithFloat:[@" " sizeWithAttributes:attributes].width * (100.0 - percent)] forKey:NSKernAttributeName];
    } else if ([command isEqualToString:@"TA"]) {
        [stack removeLastObject];
        AJRPrintf(@"TA: Ignoring (47)\n");
    } else if ([command isEqualToString:@"Tq"]) {
        [stack removeLastObject];
        AJRPrintf(@"Tq: Ignoring (48)\n");
    } else if ([command isEqualToString:@"Tx"]) {
        NSAttributedString	*substring;
        NSString					*text;
        
        text = [stack lastObject];
        
        substring = [[NSAttributedString alloc] initWithString:text attributes:attributes];
        [string appendAttributedString:substring];
        [stack removeLastObject];
    } else if ([command isEqualToString:@"Tj"]) {
        NSAttributedString	*substring;
        NSString					*text;
        
        text = [stack lastObject];
        
        substring = [[NSAttributedString alloc] initWithString:text attributes:attributes];
        [string appendAttributedString:substring];
        [stack removeLastObject];
    } else if ([command isEqualToString:@"Tk"]) {
        [stack removeLastObject];
        [stack removeLastObject];
        AJRPrintf(@"Tq: Ignoring (48)\n");
    } else if ([command isEqualToString:@"TK"]) {
        [stack removeLastObject];
        [stack removeLastObject];
        AJRPrintf(@"Tq: Ignoring (48)\n");
    } else if ([command isEqualToString:@"T+"]) {
        AJRPrintf(@"Tq: Ignoring (48)\n");
    } else if ([command isEqualToString:@"T-"]) {
        AJRPrintf(@"Tq: Ignoring (48)\n");
    } else {
        AJRPrintf(@"We don't know %@\n", command);
        [stack removeAllObjects];
    }
}

- (void)processLine:(NSString *)line {
    NSRange		range, subrange;
    NSInteger			length = [line length];
    unichar		character;
    
    range.location = 0;
    range.length = length - range.location;
    
    while (range.location < length) {
        character = [line characterAtIndex:range.location];
        if (character == '-' || (character >= '0' && character <= '9')) {
            NSNumber		*value;
            subrange = [line rangeOfCharacterFromSet:separators options:0 range:range];
            if (subrange.location == NSNotFound) {
                value = [NSNumber numberWithDouble:[[line substringFromIndex:range.location] doubleValue]];
                range.location = length;
                range.length = 0;
            } else {
                value = [NSNumber numberWithDouble:[[line substringWithRange:(NSRange){range.location, subrange.location - range.location}] doubleValue]];
                range.location = subrange.location + subrange.length;
                range.length = length - range.location;
            }
            [stack addObject:value];
        } else if (character == '[') {
            subrange = [line rangeOfString:@"]" options:0 range:range];
            if (subrange.location == NSNotFound) {
                [NSException raise:@"Stupid Programmer Exception" format:@"Don't handle multiline arrays!"];
            }
            
            [stack addObject:[self arrayFromString:[line substringWithRange:(NSRange){range.location + 1, subrange.location - (range.location + 1)}]]];
            
            range.location = subrange.location + subrange.length + 1;
            range.length = length - range.location;
        } else if (character == '(') {
            NSInteger		start = range.location + 1;
            NSInteger		opens = 0;
            range.location++;
            range.length--;
            while (range.location < length) {
                subrange = [line rangeOfString:@"(" options:0 range:range];
                if (subrange.location == NSNotFound) break;
                opens++;
                range.location = subrange.location;
                range.length = length - range.location;
            }
            while ((range.location < length) && (opens >= 0)) {
                subrange = [line rangeOfString:@")" options:0 range:range];
                if (subrange.location == NSNotFound) break;
                opens--;
                range.location = subrange.location;
                range.length = length - range.location;
            }
            
            if (subrange.location == NSNotFound) {
                [stack addObject:[line substringWithRange:(NSRange){start, range.location}]];
            } else {
                [stack addObject:[line substringWithRange:(NSRange){start, (subrange.location + subrange.length) - start - 1}]];
            }
            
            range.location += 2;
            range.length -= 2;
        } else if (character == '/') {
            NSString		*value;
            subrange = [line rangeOfCharacterFromSet:separators options:0 range:range];
            if (subrange.location == NSNotFound) {
                value = [line substringFromIndex:range.location];
                range.location = length;
                range.length = 0;
            } else {
                value = [line substringWithRange:(NSRange){range.location, subrange.location - range.location}];
                range.location = subrange.location + subrange.length;
                range.length = length - range.location;
            }
            [stack addObject:value];
        } else if ((character == ' ') || (character == '\t')) {
            range.location++;
            range.length--;
        } else {
            NSString		*command = [line substringFromIndex:range.location];
            
            subrange = [line rangeOfCharacterFromSet:separators options:0 range:range];
            if (subrange.location == NSNotFound) {
                command = [line substringFromIndex:range.location];
                range.location = length;
                range.length = 0;
            } else {
                command = [line substringWithRange:(NSRange){range.location, subrange.location - range.location}];
                range.location = subrange.location + subrange.length;
                range.length = length - range.location;
            }
            
            [self processCommand:command];
            
            [stack removeAllObjects];
        }
    }
}

- (void)readPageTrailer {
}

- (void)readTrailer {
    NSString		*line;
    
    while (1) {
        line = [file readLineReturningError:NULL];
        if (!line) break;
        if ([line hasPrefix:@"%%EOF"]) break;
    }
}

- (void)readFile {
    NSString		*line;
    
    while (1) {
        line = [file readLineReturningError:NULL];
        if (!line) break;
        if ([line hasPrefix:@"%!"]) [self readHeader];
        else if ([line hasPrefix:@"%%BeginProlog"]) [self readProlog];
        else if ([line hasPrefix:@"%%BeginSetup"]) [self readSetup];
        else if ([line hasPrefix:@"%%PageTrailer"]) [self readPageTrailer];
        else if ([line hasPrefix:@"%%Trailer"]) [self readTrailer];
        else [self processLine:line];
    }
}

- (BOOL)readDocument:(DrawDocument *)document fromURL:(NSURL *)url error:(NSError **)error {
    NSError *localError = nil;

    file = [NSFileHandle fileHandleForReadingFromURL:url error:&localError];
    if (file) {
        view = document;

        [view setPrintInfo:[[NSPrintInfo sharedPrintInfo] copy]];
        [self readFile];

        file = nil;
        view = nil;
    }

    return AJRAssertOrPropagateError(localError == nil, error, localError);
}

- (BOOL)writeDocument:(DrawDocument *)view toURL:(NSURL *)path error:(NSError **)error {
    return NO;
}

@end
