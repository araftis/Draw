/* DrawOldDrawFilter.h created by alex on Mon 09-Nov-1998 */

#import <Draw/DrawFilter.h>

@interface DrawOldDrawFilter : DrawFilter
{
	NSDictionary	*_dictionary;
	DrawDocument	*_view;
	NSURL			*_url;
	NSRect			_pageRectangle;
	NSMutableSet	*_selection;
}

@end
