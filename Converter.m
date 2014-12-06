//
//  Converter.m
//  DropJPG
//
//  Created by Kevin Wojniak on 9/22/09.
//  Copyright 2009 Kevin Wojniak. All rights reserved.
//

#import "Converter.h"
#import "NSFileManagerAdditions.h"


@implementation Converter

@synthesize imageQuality, moveOriginalToTrash, showInFinder;

- (id)init
{
	if (self = [super init])
	{
		queue = [[NSOperationQueue alloc] init];
		[queue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
	}
	
	return self;
}

- (void)finalize
{
	if (bgColor)
		CGColorRelease(bgColor);
	[super finalize];
}

- (void)setBackgroundColor:(NSColor *)color
{
	if (bgColor)
		CGColorRelease(bgColor);
	NSColor *rgbColor = [color colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]];
    CGFloat r, g, b, a;
    [rgbColor getRed:&r green:&g blue:&b alpha:&a];
	bgColor = CGColorCreateGenericRGB(r, g, b, a);
}

- (CFDataRef)copyJpegDataForImage:(CGImageRef)image hasAlpha:(BOOL)hasAlpha
{
	CFMutableDataRef data = NULL;
	CGSize imageSize;
	CGColorSpaceRef colorSpace = NULL;
	CGContextRef ctx = NULL;
	CGRect imageRect;
	CGImageRef finalImage = NULL;
	CGImageDestinationRef imgDest = NULL;
	CFMutableDictionaryRef properties = NULL;

	imageSize = CGSizeMake((CGFloat)CGImageGetWidth(image), (CGFloat)CGImageGetHeight(image));	
	colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	if (!colorSpace)
		goto bail;
	
	ctx = CGBitmapContextCreate(NULL, (size_t)imageSize.width, (size_t)imageSize.height, 8, 0, colorSpace, kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);
	if (!ctx)
		goto bail;
	
	imageRect = CGRectMake(0.0, 0.0, imageSize.width, imageSize.height);
	CGContextSetFillColorWithColor(ctx, bgColor);
	CGContextFillRect(ctx, imageRect);
	CGContextDrawImage(ctx, imageRect, image);
	
	finalImage = CGBitmapContextCreateImage(ctx);
	if (!finalImage)
		goto bail;
	
	data = CFDataCreateMutable(NULL, 0);
	if (!data)
		goto bail;
	imgDest = CGImageDestinationCreateWithData(data, kUTTypeJPEG, 1, NULL);
	if (!imgDest)
		goto bail;
	properties = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	if (!properties)
		goto bail;
	
	CFDictionaryAddValue(properties, kCGImageDestinationLossyCompressionQuality, [NSNumber numberWithFloat:imageQuality]);
	CGImageDestinationAddImage(imgDest, finalImage, properties);
	if (!CGImageDestinationFinalize(imgDest))
		goto bail;
	
bail:
	if (colorSpace)
		CGColorSpaceRelease(colorSpace);
	if (ctx)
		CGContextRelease(ctx);
	if (finalImage)
		CGImageRelease(finalImage);
	if (imgDest)
		CFRelease(imgDest);
	if (properties)
		CFRelease(properties);
	
	return data;
}

- (BOOL)doConvertImageAtURL:(NSURL *)imageURL toDirectory:(NSURL *)directoryURL
{
	CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)imageURL, NULL);
	if (!imageSource)
		return NO;
	
	BOOL hasAlpha = NO;
	CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
	if (properties)
	{
		CFNumberRef hasAlphaProp = CFDictionaryGetValue(properties, CFSTR("HasAlpha"));
		if (hasAlphaProp)
			CFNumberGetValue(hasAlphaProp, kCFNumberCharType, &hasAlpha);
		CFRelease(properties);
	}
	
	CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
	CFRelease(imageSource);
	if (!image)
		return NO;
		
	CFDataRef jpgData = [self copyJpegDataForImage:image hasAlpha:hasAlpha];
	CGImageRelease(image);
	if (!jpgData)
		return NO;
	
	NSString *fileName = [NSString stringWithFormat:@"%@.jpg", [[imageURL lastPathComponent] stringByDeletingPathExtension]];
	NSURL *jpgURL = [directoryURL URLByAppendingPathComponent:fileName];
	jpgURL = [[NSFileManager defaultManager] makeUniqueURL:jpgURL];
	
    BOOL wrote = [(NSData*)jpgData writeToURL:jpgURL atomically:YES];
	CFRelease(jpgData);
	if (!wrote)
		return NO;
	
	if (moveOriginalToTrash)
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			[[NSWorkspace sharedWorkspace] recycleURLs:[NSArray arrayWithObject:imageURL] completionHandler:NULL];
		}];
	
	if (showInFinder)
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			[[NSWorkspace sharedWorkspace] selectFile:[jpgURL path] inFileViewerRootedAtPath:nil];
		}];
}

- (NSImage *)convertSampleImage:(CGImageRef)image
{
	CFDataRef jpgData = [self copyJpegDataForImage:image hasAlpha:YES];
	if (!jpgData)
		return nil;
	
	NSImage *img = [[[NSImage alloc] initWithData:(NSData *)jpgData] autorelease];
	CFRelease(jpgData);
	return img;
}

- (BOOL)convertImageAtURL:(NSURL *)imageURL toDirectory:(NSURL *)directoryURL completionHandler:(void (^)())handler
{
	[queue addOperationWithBlock:^{
		[self doConvertImageAtURL:imageURL toDirectory:directoryURL];
		
		if ([queue operationCount] == 1 && handler) // will be 1 if this is the last operation
			[[NSOperationQueue mainQueue] addOperationWithBlock:^{
				handler();
			}];
	}];
}

@end
