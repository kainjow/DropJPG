//
//  PrefsController.m
//  DropJPG
//
//  Created by Kevin Wojniak on 9/22/09.
//  Copyright 2009 Kevin Wojniak. All rights reserved.
//

#import "PrefsController.h"
#import "Converter.h"
#import "UserDefaults.h"

@implementation PrefsController
{
    CGImageRef original;
    NSImage *sampleImage;
}

@synthesize sampleImage;

- (id)init
{
	return [super initWithWindowNibName:@"Prefs" owner:self];
}

- (void)updateSampleImageData
{
	if (!original)
	{
		NSURL *imageURL = [[NSBundle mainBundle] URLForImageResource:@"sample.png"];
		if (imageURL)
		{
			CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef)imageURL, NULL);
			if (imageSource)
			{
				original = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
				CFRelease(imageSource);
			}
		}
	}
	
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	Converter *converter = [[Converter alloc] init];
	[converter setBackgroundColor:[NSUnarchiver unarchiveObjectWithData:[ud objectForKey:DJBackgroundColor]]];
	converter.imageQuality = [ud floatForKey:DJImageQuality];
	self.sampleImage = [converter convertSampleImage:original];
}

- (void)awakeFromNib
{
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
															  forKeyPath:@"values."DJImageQuality
																 options:0
																 context:NULL];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
															  forKeyPath:@"values."DJBackgroundColor
																 options:0
																 context:NULL];
	
	[self updateSampleImageData];
	
}	

- (void)observeValueForKeyPath:(NSString *)__unused keyPath ofObject:(id)__unused object change:(NSDictionary *)__unused change context:(void *)__unused context
{
	[self updateSampleImageData];
}

@end
