
#import "DrawCircle.h"

#import "DrawEvent.h"
#import "DrawFunctions.h"
#import "DrawStroke.h"
#import "DrawDocument.h"

#import <AJRInterface/AJRInterface.h>

const AJRInspectorIdentifier AJRInspectorIdentifierCircle = @"circle";

@implementation DrawCircle

#pragma mark - Creation

- (void)_establishParametersFromFrame:(NSRect)frame {
    if ((frame.size.width == 0.0) && (frame.size.height == 0.0)) {
        _origin = frame.origin;
        _radius = 0;
    } else {
        _origin.x = frame.origin.x + (frame.size.width / 2.0);
        _origin.y = frame.origin.y + (frame.size.height / 2.0);
        if (frame.size.width > frame.size.height) {
            _radius = frame.size.width;
        } else {
            _radius = frame.size.height;
        }
    }
}

- (id)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self _establishParametersFromFrame:self.frame];

        _startAngle = 0.0;
        _endAngle = 360.0;
        _arcBounds = self.frame;
        _type = DrawCircleTypeCircle;

        if ((frame.size.width != 0.0) && (frame.size.height != 0.0)) {
            [self _createCircle];
        }
    }
    
    return self;
}

#pragma mark - Properties

- (void)setStartAngle:(CGFloat)angle {
    if (angle != _startAngle) {
        [[self.document prepareWithInvocationTarget:self] setStartAngle:_startAngle];
        _startAngle = angle;
        [self _createPath];
    }
}

- (void)setEndAngle:(CGFloat)angle {
    if (angle != _endAngle) {
        [[self.document prepareWithInvocationTarget:self] setEndAngle:_endAngle];
        _endAngle = angle;
        [self _createPath];
    }
}

- (void)setLineAngle:(CGFloat)angle {
    if ((_startAngle != angle) || (_endAngle != angle)) {
        _startAngle = angle;
        _endAngle = angle;
        [self _createPath];
    }
}

- (void)setType:(DrawCircleType)type {
    if (_type != type) {
        __weak DrawCircle *weakSelf = self;
        CGFloat startAngle = _startAngle;
        CGFloat endAngle = _endAngle;
        DrawCircleType undoType = _type;
        [self.document registerUndoWithTarget:self handler:^(id  _Nonnull target) {
            DrawCircle *strongSelf = weakSelf;
            if (strongSelf != nil) {
                strongSelf->_startAngle = startAngle;
                strongSelf->_endAngle = endAngle;
                strongSelf->_type = undoType;
                [strongSelf _createPath];
                [strongSelf setNeedsDisplay];
            }
        }];
        switch (type) {
            case DrawCircleTypeCircle:
                _startAngle = 0;
                _endAngle = 360;
                _type = DrawCircleTypeCircle;
                [self _createPath];
                break;
            case DrawCircleTypePie:
                if (self.isCircle) {
                    _startAngle = 20.0;
                    _endAngle = -20.0;
                }
                _type = DrawCircleTypePie;
                [self _createPath];
                break;
            case DrawCircleTypeChord:
                if (self.isCircle) {
                    _startAngle = 20.0;
                    _endAngle = -20.0;
                }
                _type = DrawCircleTypeChord;
                [self _createPath];
                break;
        }
        [self setNeedsDisplay];
    }
}

#pragma mark - Path Construction

- (void)_createCircle {
    [_path removeAllPoints];
    [_path appendBezierPathWithOvalInRect:_arcBounds];
    [_path closePath];
    _type = DrawCircleTypeCircle;

    [super setFrame:self.path.controlPointBounds];
    [self noteBoundsAreDirty];
    [self setNeedsDisplay];
}

- (void)_createLine {
    [_path removeAllPoints];
    [_path moveToPoint:_origin];
    [_path lineToPoint:AJRPointOnOval(_origin, _arcBounds.size.width / 2.0, _arcBounds.size.height / 2.0, _startAngle)];
    if (_type == DrawCircleTypeCircle) {
        _type = DrawCircleTypePie;
    }
    
    [super setFrame:self.path.controlPointBounds];
    [self noteBoundsAreDirty];
    [self setNeedsDisplay];
}

- (void)_createWedge {
    if (_startAngle == _endAngle) {
        return [self _createLine];
    } else if (self.isCircle) {
        return [self _createCircle];
    } else {
        [_path removeAllPoints];

        if (_type == DrawCircleTypePie) {
            [_path moveToPoint:_origin];
        } else {
            NSPoint start;
            start.x = NSMidX(_arcBounds) + AJRCos(_startAngle) * _arcBounds.size.width / 2.0;
            start.y = NSMidY(_arcBounds) + AJRSin(_startAngle) * _arcBounds.size.height / 2.0;
            [_path moveToPoint:start];
        }
        [_path appendBezierPathWithArcBoundedByRect:_arcBounds startAngle:_startAngle endAngle:_endAngle clockwise:NO];
        [_path closePath];

        if (_type == DrawCircleTypeCircle) {
            _type = DrawCircleTypePie;
        }

        [super setFrame:self.path.controlPointBounds];
        [self noteBoundsAreDirty];
        [self setNeedsDisplay];
    }
}

- (BOOL)isCircle {
    return AJRApproximateEquals(fmod(fabs(_startAngle - _endAngle), 360.0), 0.0, 5);
}

- (void)_createPath {
    if (self.isCircle) {
        [self _createCircle];
    } else {
        if (_startAngle == _endAngle) {
            [self _createLine];
        } else {
            [self _createWedge];
        }
    }
}

- (void)setFrame:(NSRect)frame {
    if (self.editing || self.isCircle) {
        _origin.x = frame.origin.x + frame.size.width / 2.0;
        _origin.y = frame.origin.y + frame.size.height / 2.0;
        [super setFrame:frame];
        _arcBounds = self.frame;
        [self _createPath];
        if (self.frame.size.width > self.frame.size.height) {
            _radius = self.frame.size.width / 2.0;
        } else {
            _radius = self.frame.size.height / 2.0;
        }
    } else {
        NSRect oldFrame = self.frame;
        [super setFrame:frame];
        NSRect newFrame = self.frame;

        // This is probably wrong.
        _arcBounds.origin.x -= (oldFrame.origin.x - newFrame.origin.x);
        _arcBounds.origin.y -= (oldFrame.origin.y - newFrame.origin.y);
        _arcBounds.size.width -= (oldFrame.size.width - newFrame.size.width);
        _arcBounds.size.height -= (oldFrame.size.height - newFrame.size.height);
        AJRPrintf(@"%R, %R\n", newFrame, _arcBounds);
        _origin.x = _arcBounds.size.width / 2.0 + _arcBounds.origin.x;
        _origin.y = _arcBounds.size.height / 2.0 + _arcBounds.origin.y;
    }
}

- (NSPoint)locationForAngle:(double)anAngle {
    NSPoint	point = AJRPolarToEuclidean(_origin, anAngle, _radius);
    
    point.x = ((point.x - _origin.x) * ((_arcBounds.size.width / 2.0) / _radius)) + _origin.x;
    point.y = ((point.y - _origin.y) * ((_arcBounds.size.height / 2.0) / _radius)) + _origin.y;
    
    return point;
}

- (void)drawHandles {
    if (!self.editing) {
        return [super drawHandles];
    }
    
    if (!self.ignore) {
        [self drawHandleAtPoint:_origin];
        [self drawHandleAtPoint:[self locationForAngle:_startAngle]];
        if (_startAngle != _endAngle) {
            [self drawHandleAtPoint:[self locationForAngle:_endAngle]];
        }
    }
}

- (DrawHandle)setHandle:(DrawHandle)handle toLocation:(NSPoint)point {
    if (handle.type == DrawHandleTypeIndexed) {
        if (handle.elementIndex == DrawCircleHandleFirst) {
            _startAngle = AJRArctan(point.y - _origin.y, point.x - _origin.x);
            _endAngle = _startAngle;
            _radius = AJRDistanceBetweenPoints(point, _origin);
            [self _createLine];
            [self setFrame:self.bounds];
            return handle;
        } else if (handle.elementIndex == DrawCircleHandleStartAngle) {
            _startAngle = AJRArctan(point.y - _origin.y, point.x - _origin.x);
            if ((_startAngle >= _endAngle - .5) && (_startAngle <= _endAngle + .5)) {
                _endAngle = _startAngle + 360.0;
            } else if (_endAngle > 360.0) {
                _endAngle -= 360.0;
            }
            [self _createWedge];
            return handle;
        } else if (handle.elementIndex == DrawCircleHandleEndAngle) {
            _endAngle = AJRArctan(point.y - _origin.y, point.x - _origin.x);
            if ((_endAngle >= _startAngle - .5) && (_endAngle <= _startAngle + .5)) {
                _startAngle = _endAngle - 360.0;
            } else if (_startAngle < 0.0) {
                _startAngle += 360.0;
            }
            [self _createWedge];
            return handle;
        } else if (handle.elementIndex == DrawCircleHandleOrigin) {
            NSPoint delta = {point.x - _origin.x, point.y - _origin.y};

            _origin = point;
            _arcBounds.origin.x += delta.x;
            _arcBounds.origin.y += delta.y;
            NSRect frame = self.frame;
            frame.origin.x += delta.x;
            frame.origin.y += delta.y;
            [self setFrame:frame];
            NSRect bounds = self.bounds;
            bounds.origin.x += delta.x;
            bounds.origin.y += delta.y;
            [self setBounds:bounds];

            [_path translateByDelta:delta];

            return handle;
        }
    }
    
    return [super setHandle:handle toLocation:point];
}

- (DrawHandle)handleForPoint:(NSPoint)aPoint {
    if (self.editing) {
        if ([self isPoint:aPoint inHandleAt:_origin]) {
            return DrawHandleMake(DrawHandleTypeIndexed, DrawCircleHandleOrigin, 0);
        } else if ([self isPoint:aPoint inHandleAt:[self locationForAngle:_startAngle]]) {
            return DrawHandleMake(DrawHandleTypeIndexed, DrawCircleHandleStartAngle, 0);
        } else if ([self isPoint:aPoint inHandleAt:[self locationForAngle:_endAngle]]) {
            return DrawHandleMake(DrawHandleTypeIndexed, DrawCircleHandleEndAngle, 0);
        }
        return DrawHandleMake(DrawHandleTypeMissed, 0, 0);
    }
    return [super handleForPoint:aPoint];
}

- (BOOL)trackMouse:(DrawEvent *)event fromHandle:(DrawHandle)handle {
    BOOL rVal = [super trackMouse:event fromHandle:handle];
    
    if (handle.type == DrawHandleTypeIndexed) {
        _arcBounds = AJRNormalizeRect((NSRect){{_origin.x - _radius, _origin.y - _radius}, {_radius * 2.0, _radius * 2.0}});
    }
    
    return rVal;
}

- (BOOL)trackMouse:(DrawEvent *)event {
    if (_startAngle == _endAngle) {
        [self trackMouse:event fromHandle:DrawHandleMake(DrawHandleTypeIndexed, 0, 0)];
        _arcBounds = AJRNormalizeRect((NSRect){{_origin.x - _radius, _origin.y - _radius}, {_radius * 2.0, _radius * 2.0}});
    }
    return [super trackMouse:event fromHandle:DrawHandleMake(DrawHandleTypeBottomRight, 0, 0)];
}

- (NSPoint)intersectionWithLineEndingAtPoint:(NSPoint)aPoint found:(BOOL *)found {
    CGFloat angle;
    
    if ((aPoint.y - _origin.y == 0) && (aPoint.x - _origin.x == 0)) {
        return _origin;
    } else {
        angle = AJRArctan((aPoint.y - _origin.y) / (_arcBounds.size.height / 2.0), (aPoint.x - _origin.x) / (_arcBounds.size.width / 2.0));
    }
    
    if (fabs(_startAngle - _endAngle) != 360.0) {
        return [super intersectionWithLineEndingAtPoint:aPoint found:found];
    }
    
    *found = YES;
    return [self locationForAngle:angle];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    DrawCircle 	*new = [super copyWithZone:zone];
    
    new->_origin = _origin;
    new->_radius = _radius;
    new->_startAngle = _startAngle;
    new->_endAngle = _endAngle;
    new->_arcBounds = _arcBounds;
    new->_type = _type;
    
    return new;
}

#pragma mark - NSCoding

- (void)decodeWithXMLCoder:(AJRXMLCoder *)coder {
    [super decodeWithXMLCoder:coder];
    [coder decodeFloatForKey:@"startAngle" setter:^(float value) {
        self->_startAngle = value;
    }];
    [coder decodeFloatForKey:@"endAngle" setter:^(float value) {
        self->_endAngle = value;
    }];
    [coder decodeStringForKey:@"type" setter:^(NSString * _Nonnull string) {
        self->_type = DrawCircleTypeFromString(string);
    }];
    [coder decodeRectForKey:@"arcBounds" setter:^(CGRect rect) {
        self->_arcBounds = rect;
    }];
}

- (id)finalizeXMLDecodingWithError:(NSError * _Nullable __autoreleasing *)error {
    if ([super finalizeXMLDecodingWithError:error]) {
        if (_type == DrawCircleTypeCircle) {
            // We'll have explicitly encoded arcBounds if we're not a circle.
            _arcBounds = self.frame;
        }
        _origin.x = NSMidX(_arcBounds);
        _origin.y = NSMidY(_arcBounds);
        [self _establishParametersFromFrame:self.frame];
        [self _createPath];
    }
    return self;
}

- (void)encodeWithXMLCoder:(AJRXMLCoder *)encoder {
    [super encodeWithXMLCoder:encoder];
    
    [encoder encodeFloat:_startAngle forKey:@"startAngle"];
    [encoder encodeFloat:_endAngle forKey:@"endAngle"];
    if (_type != DrawCircleTypeCircle) {
        // Only encode if we're not a circle, as that's expected to be the most common.
        [encoder encodeString:DrawStringFromDrawCircleType(_type) forKey:@"type"];
        [encoder encodeRect:_arcBounds forKey:@"arcBounds"];
    }
}

+ (NSString *)ajr_nameForXMLArchiving {
    return @"circle";
}

- (BOOL)isEqualToCircle:(DrawCircle *)circle {
    return (self.class == circle.class
            && [super isEqualToGraphic:circle]
            && _startAngle == circle->_startAngle
            && _endAngle == circle->_endAngle);
}

- (BOOL)isEqual:(id)other {
    return self == other || ([other isKindOfClass:[DrawCircle class]] && [self isEqualToCircle:other]);
}

#pragma mark - Inspectors

- (NSArray<AJRInspectorIdentifier> *)inspectorIdentifiers {
    NSMutableArray<AJRInspectorIdentifier> *identifiers = [[super inspectorIdentifiers] mutableCopy];
    [identifiers addObject:AJRInspectorIdentifierCircle];
    return identifiers;
}

@end

NSString *DrawStringFromDrawCircleType(DrawCircleType type) {
    switch (type) {
        case DrawCircleTypeCircle: return @"circle";
        case DrawCircleTypePie:    return @"pie";
        case DrawCircleTypeChord:  return @"chord";
    }
    return @"circle";
}

DrawCircleType DrawCircleTypeFromString(NSString *type) {
    if ([type isEqualToString:@"circle"]) {
        return DrawCircleTypeCircle;
    } else if ([type isEqualToString:@"pie"]) {
        return DrawCircleTypePie;
    } else if ([type isEqualToString:@"chord"]) {
        return DrawCircleTypeChord;
    }
    return DrawCircleTypeCircle;
}
