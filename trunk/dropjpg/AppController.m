#import "AppController.h"
#import "NSFileManagerAdditions.h"
#import "DJStatusView.h"


@interface AppController (Private)
- (void)convertFileToJPEG:path destination:(NSString *)destination;
- (NSString *)safeNameForFile:(NSString *)file;
- (void)setSampleImage:(NSData *)sampleImage;
- (void)updateSampleImageData;
@end

@implementation AppController

+ (void)initialize
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithFloat:1.0], @"DJImageQuality",
		[NSArchiver archivedDataWithRootObject:[NSColor whiteColor]], @"DJBackgroundColor",
		[NSNumber numberWithBool:NO], @"DJDeleteOriginal",
		[NSNumber numberWithBool:NO], @"DJQuitAfterConversion",
		[NSNumber numberWithBool:NO], @"DJShowInFinder",
		[NSNumber numberWithBool:NO], @"DJAskDestination",
		[NSNumber numberWithBool:NO], @"DJSetIcon",
		nil]];
}

- (id)init
{
	if (![super init])
		return nil;
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
															  forKeyPath:@"values.DJImageQuality"
																 options:0
																 context:NULL];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
															  forKeyPath:@"values.DJBackgroundColor"
																 options:0
																 context:NULL];
	
	[self updateSampleImageData];
	
	return self;
}

- (void)dealloc
{
	[_sampleData release];
	[_statusItem release];
	[super dealloc];
}

- (void)setupStatusItem
{
	//_statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:22] retain];
	//[_statusItem setView:[[[DJStatusView alloc] init] autorelease]];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[self setupStatusItem];
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
	NSEnumerator *filesEnum = [filenames objectEnumerator];
	NSString *filename = nil, *dest = nil;
	BOOL isDir = NO;
	NSFileManager *fm = [NSFileManager defaultManager];

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DJAskDestination"])
	{
		NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		[openPanel setCanChooseFiles:NO];
		[openPanel setCanChooseDirectories:YES];
		[openPanel setAllowsMultipleSelection:NO];
		if ([openPanel runModalForDirectory:nil file:nil types:nil] == NSCancelButton)
			return;
		dest = [openPanel filename];
	}

	while (filename = [filesEnum nextObject])
	{
		if ([fm fileExistsAtPath:filename isDirectory:&isDir] && isDir)
		{
			// convert all images in a directory
			NSEnumerator *dirEnum = [[fm directoryContentsAtPath:filename] objectEnumerator];
			NSString *file = nil;
			while (file = [dirEnum nextObject])
				[self convertFileToJPEG:[filename stringByAppendingPathComponent:file] destination:(dest ? dest : filename)];
		}
		else
		{
			// convert a single file
			[self convertFileToJPEG:filename destination:(dest ? dest : [filename stringByDeletingLastPathComponent])];
		}
	}

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DJQuitAfterConversion"])
		[NSApp terminate:nil];
}

- (NSData *)jpegDataForImage:(NSImage *)image
{
	NSImage *newImage = nil;
	NSRect newImageRect = NSZeroRect;
	NSDictionary *properties = nil;
	NSBitmapImageRep *bitmap = nil;
	NSUserDefaults *defaults = nil;
	NSData *tiffData = nil;

	defaults = [NSUserDefaults standardUserDefaults];
	properties = [NSDictionary dictionaryWithObject:[defaults objectForKey:@"DJImageQuality"]
											 forKey:NSImageCompressionFactor];

	// render the image onto a new image with a background color
	NSBitmapImageRep *rep = [[image representations] objectAtIndex:0];
	NSSize imageSize = NSMakeSize([rep pixelsWide], [rep pixelsHigh]);
	newImage = [[[NSImage alloc] initWithSize:imageSize] autorelease];
	newImageRect = NSMakeRect(0, 0, imageSize.width, imageSize.height);
	[newImage lockFocus];
	[(NSColor *)[NSUnarchiver unarchiveObjectWithData:[defaults objectForKey:@"DJBackgroundColor"]] set];
	NSRectFill(newImageRect);
	[image setScalesWhenResized:YES];
	[image setSize:imageSize];
	[image drawInRect:newImageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	[newImage unlockFocus];
	
	// get the jpeg data from the image by first converting to tiff
	tiffData = [newImage TIFFRepresentationUsingCompression:NSTIFFCompressionNone factor:0.0];
	bitmap = [[[NSBitmapImageRep alloc] initWithData:tiffData] autorelease];
	return [bitmap representationUsingType:NSJPEGFileType properties:properties];
}

- (void)convertFileToJPEG:path destination:(NSString *)destination
{
	NSImage *image = nil;
	NSUserDefaults *defaults = nil;
	NSString *jpgPath = nil;
	NSData *jpegData = nil;
	
	image = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
	if (!image)
		return;
	
	defaults = [NSUserDefaults standardUserDefaults];
	
	jpgPath = [self safeNameForFile:[destination stringByAppendingPathComponent:
		[NSString stringWithFormat:@"%@.jpg", [[path lastPathComponent] stringByDeletingPathExtension]]]];

	jpegData = [self jpegDataForImage:image];
	[jpegData writeToFile:jpgPath atomically:YES];
	
	// set the file icon
	if ([defaults boolForKey:@"DJSetIcon"])
		[[NSWorkspace sharedWorkspace] setIcon:[[[NSImage alloc] initWithData:jpegData] autorelease] forFile:jpgPath options:nil];

	// delete the original file (move to trash)
	if ([defaults boolForKey:@"DJDeleteOriginal"])
		[[NSFileManager defaultManager] trashPath:path showAlerts:NO];
	
	// show in finder
	if ([defaults boolForKey:@"DJShowInFinder"])
		[[NSWorkspace sharedWorkspace] openFile:destination];
}

// makes sure a file isn't written over
- (NSString *)safeNameForFile:(NSString *)file
{
	NSFileManager *fm = [NSFileManager defaultManager];
	
	if (![fm fileExistsAtPath:file])
		return file;
	
	int i;
	NSString *pathExtension = [file pathExtension];
	NSString *pathWithoutExtension = [file stringByDeletingPathExtension];
	NSString *checkPath;
	
	i = 1;
	do
	{
		checkPath = [NSString stringWithFormat:@"%@ %d.%@", pathWithoutExtension, i, pathExtension];
		i++;
	} while ([fm fileExistsAtPath:checkPath]);
	return checkPath;
}

#pragma mark -
#pragma mark Actions

- (IBAction)sendFeedback:(id)sender
{
	NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
	NSString *appVersion = [infoPlist objectForKey:@"CFBundleVersion"];
	NSString *appName = [infoPlist objectForKey:@"CFBundleName"];
	NSString *email = @"kainjow@kainjow.com";
	NSString *urlString = [[NSString stringWithFormat:@"mailto:%@?subject=%@ %@ Feedback", email, appName, appVersion] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSURL *emailURL = [NSURL URLWithString:urlString];
	if (emailURL)
		[[NSWorkspace sharedWorkspace] openURL:emailURL];
}

#pragma mark -
#pragma mark Preferences

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self updateSampleImageData];
}

- (void)updateSampleImageData
{
	[self setSampleImage:[self jpegDataForImage:[NSImage imageNamed:@"pippy"]]];
}

- (void)setSampleImage:(NSData *)sampleImage
{
	if (_sampleData != sampleImage)
	{
		[_sampleData release];
		_sampleData = [sampleImage retain];
	}
}

- (NSData *)sampleImage
{
	return _sampleData;
}

@end
