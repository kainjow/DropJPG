//
//  AppController.m
//  DropJPG
//
//  Copyright 2009 Kevin Wojniak. All rights reserved.
//

#import "AppController.h"
#import "UserDefaults.h"
#import "Converter.h"
#import "PrefsController.h"

@implementation AppController
{
    Converter *converter;
    PrefsController *prefsController;
}

+ (void)initialize
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithFloat:1.0], DJImageQuality,
		[NSArchiver archivedDataWithRootObject:[NSColor whiteColor]], DJBackgroundColor,
		[NSNumber numberWithBool:NO], DJDeleteOriginal,
		[NSNumber numberWithBool:NO], DJQuitAfterConversion,
		[NSNumber numberWithBool:NO], DJShowInFinder,
		[NSNumber numberWithBool:NO], DJAskDestination,
		nil]];
}

- (void)application:(NSApplication *)__unused sender openFiles:(NSArray *)filenames
{
	NSURL *destURL = nil;
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

	if ([ud boolForKey:DJAskDestination])
	{
		NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		[openPanel setCanChooseFiles:NO];
		[openPanel setCanChooseDirectories:YES];
		[openPanel setAllowsMultipleSelection:NO];
		if ([openPanel runModal] == NSFileHandlingPanelCancelButton)
			return;
		destURL = [openPanel URL];
	}
	
	if (!converter)
		converter = [[Converter alloc] init];
	[converter setBackgroundColor:[NSUnarchiver unarchiveObjectWithData:[ud objectForKey:DJBackgroundColor]]];
	converter.imageQuality = [ud floatForKey:DJImageQuality];
	converter.moveOriginalToTrash = [ud boolForKey:DJDeleteOriginal];
	converter.showInFinder = [ud boolForKey:DJShowInFinder];

	dispatch_block_t completionHandler = ^{
        NSUserNotification *notif = [[NSUserNotification alloc] init];
        notif.title = NSLocalizedString(@"Conversion complete.", "");
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notif];
        
		if ([[NSUserDefaults standardUserDefaults] boolForKey:DJQuitAfterConversion])
			[NSApp terminate:nil];		
	};
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDir;
	for (NSString *filename in filenames)
	{
		NSURL *fileURL = [NSURL fileURLWithPath:filename];
		if ([fm fileExistsAtPath:filename isDirectory:&isDir] && isDir)
		{
			// convert all images in a directory
			NSURL *directory = (destURL ? destURL : fileURL);
			NSArray *dirFiles = [fm contentsOfDirectoryAtPath:filename error:nil];
			for (NSString *file in dirFiles)
				[converter convertImageAtURL:[fileURL URLByAppendingPathComponent:file] toDirectory:directory completionHandler:completionHandler];
		}
		else
		{
			// convert a single file
			[converter convertImageAtURL:fileURL toDirectory:(destURL ? destURL : [fileURL URLByDeletingLastPathComponent]) completionHandler:completionHandler];
		}
	}
}

#pragma mark -
#pragma mark Actions

- (IBAction)sendFeedback:(id)__unused sender
{
	NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
	NSString *appVersion = [infoPlist objectForKey:(NSString *)kCFBundleVersionKey];
	NSString *appName = [[NSProcessInfo processInfo] processName];
	NSString *email = @"kainjow@kainjow.com";
	NSString *urlString = [[NSString stringWithFormat:@"mailto:%@?subject=%@ %@ Feedback", email, appName, appVersion] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSURL *emailURL = [NSURL URLWithString:urlString];
	if (emailURL)
		[[NSWorkspace sharedWorkspace] openURL:emailURL];
}

- (IBAction)openPrefs:(id)__unused sender
{
	if (!prefsController)
		prefsController = [[PrefsController alloc] init];
	[prefsController showWindow:nil];
}

@end
