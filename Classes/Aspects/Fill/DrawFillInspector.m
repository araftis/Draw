
#import "DrawFillInspector.h"

#import "DrawColorFill.h"
#import "DrawGraphic.h"

#import <AJRInterface/AJRInterface.h>
#import <AJRFoundation/AJRFoundation.h>

NSString *DrawFillKey = @"DrawFillKey";

@implementation DrawFillInspector

+ (void)initialize
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:
	 [NSDictionary dictionaryWithObjectsAndKeys:
	  // The Compose Defaults
	  @"Standard", DrawFillKey,
	  nil
	  ]
	 ];
}

- (id)init
{
	if ((self = [super init])) {
		fills = [[NSMutableArray alloc] init];
	}
	return self;
}

- (NSString *)title
{
	return @"Fill";
}

- (void)addFill:(Class)aClass
{
	AJRPrintf(@"Fill: %@\n", aClass);
	[fills addObject:aClass];
}

- (Class)inspectedClass
{
	return [DrawFill class];
}

- (DrawAspectPriority)aspectPriority
{
	return DrawAspectPriorityBeforeChildren;
}

- (DrawAspect *)aspectWithGraphic:(DrawGraphic *)graphic
{
	return [[[self fillClass] alloc] initWithGraphic:graphic];
}

- (void)update
{
	NSUserDefaults	*defaults = [NSUserDefaults standardUserDefaults];
	NSSet			*colors = [self inspectedValuesForKeyPath:@"color"];
	
	if ([colors count] == 1) {
		[fillColorWell setColor:[colors anyObject]];
		
		[defaults setColor:[colors anyObject] forKey:DrawFillColorKey];
	} else if ([colors count] > 1) {
	} else {
		NSUInteger	tag = [self tagForFillNamed:[defaults stringForKey:DrawFillKey]];
		
		if (tag == NSNotFound) {
			tag = [self tagForFillNamed:@"Standard"];
			[defaults setObject:@"Standard" forKey:DrawFillKey];
		}
		
		[fillColorWell setColor:[defaults colorForKey:DrawFillColorKey]];
		[[fillTypeMatrix cellAtRow:0 column:0] selectItemWithTag:tag];
	}
}

- (void)setFillColor:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setColor:[sender color] forKey:DrawFillColorKey];
	[self setInspectedValue:[sender color] forKeyPath:@"color" creationCallback:NULL];
}

- (void)selectFillType:(id)sender
{
}

- (NSUInteger)tagForFillNamed:(NSString *)name
{
	NSInteger		x;
	
	for (x = 0; x < (const NSInteger)[fills count]; x++) {
		if ([[(Class)[fills objectAtIndex:x] name] isEqualToString:name]) return x;
	}
	
	return NSNotFound;
}

- (Class)fillClassForName:(NSString *)name
{
	NSInteger		x;
	
	for (x = 0; x < (const NSInteger)[fills count]; x++) {
		if ([[(Class)[fills objectAtIndex:x] name] isEqualToString:name]) return [fills objectAtIndex:x];
	}
	
	return Nil;
}

- (void)setFillTypeMatrix:(NSMatrix *)aMatrix
{
//   AJRToolCell		*cell;
//   NSMutableArray	*images = [[NSMutableArray alloc] init];
//   NSInteger				x;
//
//   [aMatrix setCellClass:[AJRToolCell class]];
//
//   for (x = 0; x < (const NSInteger)[fills count]; x++) {
//      [images addObject:[[fills objectAtIndex:x] image]];
//   }
//   
//   cell = [[AJRToolCell alloc] initWithImageArray:images];
//   [cell setTriggerOnMouseDown:YES];
//   [cell setPopDirection:AJRPopVertical];
//   [cell setHighlightsBy:NSNoCellMask];
//   [cell setShowsStateBy:NSNoCellMask];
//
//   [aMatrix putCell:cell atRow:0 column:0];
//
//   [images release];
//   
//   fillTypeMatrix = aMatrix;
}

- (Class)fillClass
{
	Class	 class = [self fillClassForName:[[NSUserDefaults standardUserDefaults] stringForKey:DrawFillKey]];
	
	if (!class) {
		class = [self fillClassForName:@"Standard"];
	}
	
	return class;
}

@end
