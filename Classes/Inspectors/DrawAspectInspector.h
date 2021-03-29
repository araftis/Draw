
#import <Draw/DrawInspector.h>

@interface DrawAspectInspector : DrawInspector

/*!
 This overrides the method defined on DrawInspector to first call super, and to then call setTemplateValue:forKeyPath:creationCallback:.
 */
- (void)setInspectedValue:(id)value forKeyPath:(NSString *)keyPath creationCallback:(DrawAspectCreationCallback)creationCallback;

- (void)setTemplateValue:(id)value forKeyPath:(NSString *)keyPath creationCallback:(DrawAspectCreationCallback)creationCallback;
- (void)setTemplateFloat:(CGFloat)value forKeyPath:(NSString *)keyPath creationCallback:(DrawAspectCreationCallback)creationCallback;
- (void)setTemplateDouble:(double)value forKeyPath:(NSString *)keyPath creationCallback:(DrawAspectCreationCallback)creationCallback;
- (void)setTemplateInteger:(NSInteger)value forKeyPath:(NSString *)keyPath creationCallback:(DrawAspectCreationCallback)creationCallback;
- (void)setTemplateBool:(BOOL)value forKeyPath:(NSString *)keyPath creationCallback:(DrawAspectCreationCallback)creationCallback;

- (void)removeInspectedAspectFromSelection;

@end
