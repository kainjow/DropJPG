//
//  NSFileManagerAdditions.m
//  DropJPG
//
//  Created by Kevin Wojniak on 9/22/09.
//  Copyright 2009 Kevin Wojniak. All rights reserved.
//

#import "NSFileManagerAdditions.h"

@implementation NSFileManager (DJAdditions)

- (NSURL *)makeUniqueURL:(NSURL *)URL
{
	if (![URL isFileURL])
		return URL;
	
	NSString *path = [URL path];
	if (![self fileExistsAtPath:path])
		return URL;
	
	NSString *pathExtension = [path pathExtension];
	NSString *pathWithoutExtension = [path stringByDeletingPathExtension];
	NSUInteger i = 1;
	do {
		path = [NSString stringWithFormat:@"%@ %lu.%@", pathWithoutExtension, (unsigned long)i++, pathExtension];
	} while ([self fileExistsAtPath:path]);
	return [NSURL fileURLWithPath:path];
}

@end