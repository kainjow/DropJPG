//
//  Converter.h
//  DropJPG
//
//  Created by Kevin Wojniak on 9/22/09.
//  Copyright 2009 Kevin Wojniak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Converter : NSObject

- (void)setBackgroundColor:(NSColor *)color;

@property CGFloat imageQuality;
@property BOOL moveOriginalToTrash;
@property BOOL showInFinder;

- (void)convertImageAtURL:(NSURL *)imageURL toDirectory:(NSURL *)directoryURL completionHandler:(void (^)())handler;

- (NSImage *)convertSampleImage:(CGImageRef)image;

@end
