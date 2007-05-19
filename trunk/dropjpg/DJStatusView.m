//
//  DJStatusView.m
//  DropJPG
//
//  Created by Kevin Wojniak on 1/15/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "DJStatusView.h"


@implementation DJStatusView

- (id)initWithFrame:(NSRect)frameRect
{
	if (![super initWithFrame:frameRect])
		return nil;
	
	_dragOn = NO;
	
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
	
	return self;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	_dragOn = YES;
	[self setNeedsDisplay:YES];
	return NSDragOperationGeneric;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	_dragOn = NO;
	[self setNeedsDisplay:YES];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard *bpoard = [sender draggingPasteboard];
	NSArray *files = (NSArray *)[bpoard propertyListForType:NSFilenamesPboardType];
	NSEnumerator *filesEnum = [files objectEnumerator];
	NSString *file = nil;
	
	_dragOn = NO;
	[self setNeedsDisplay:YES];

	while (file = [filesEnum nextObject])
	{
		NSLog(file);
	}
	
	return YES;
}

- (void)drawRect:(NSRect)rect
{
	if (_dragOn)
		[[NSColor redColor] set];
	else
		[[NSColor whiteColor] set];
	
	NSRectFill([self bounds]);
}

@end
