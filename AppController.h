/* AppController */

#import <Cocoa/Cocoa.h>

@interface AppController : NSObject
{
	NSStatusItem *_statusItem;
	
	NSData *_sampleData;
}

- (IBAction)sendFeedback:(id)sender;

@end
