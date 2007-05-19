//
//  NSFileManagerAdditions.m
//  TRKit
//

#import "NSFileManagerAdditions.h"
#import <assert.h>
#import <unistd.h>
#import <inttypes.h>
#import <pwd.h>
#import <grp.h>
#import <dirent.h>
#import <paths.h>
#import <sys/param.h>
#import <sys/mount.h> // is where the statfs struct is defined
#import <sys/attr.h>
#import <sys/vnode.h>
#import <sys/stat.h>

static __inline__ int RandomIntBetween(int a, int b)
{
    int range = b - a < 0 ? b - a - 1 : b - a + 1; 
    int value = (int)(range * ((float)random() / (float) LONG_MAX));
    return value == range ? a : a + value;
}

@implementation NSFileManager (TRAdditions)

- (BOOL)trashPath:(NSString *)source showAlerts:(BOOL)flag
{
	BOOL isRemovable, isWritable, isUnmountable, success, isLocal, useDiskTrash;
	NSString * description, * type, * device;
	NSString * standardizedSource = [source stringByStandardizingPath];
	int err;
	struct statfs sfsb;
	const char * volPath = [source UTF8String];
	NSWorkspace * workspace = [NSWorkspace sharedWorkspace];
	
	// Check to see if we can get rid of this file.
	if ([self isDeletableFileAtPath:standardizedSource] == NO) return NO;
	
	// Get attributes.
	success = [workspace getFileSystemInfoForPath:standardizedSource
									  isRemovable:&isRemovable
									   isWritable:&isWritable
									isUnmountable:&isUnmountable
									  description:&description
											 type:&type];
	if (success == NO || isWritable == NO) return NO;
	
	err = statfs(volPath, &sfsb);
	if (err != 0) return NO;
	
	device = [NSString stringWithCString:sfsb.f_mntfromname];
	isLocal = [device rangeOfString:@"/dev/"].location != NSNotFound;
	
	// If the file is remote we (at the discresion of the above flag) prompt the
	// user, to trash or not. If flag is NO, NO is returned.
	
	if (isLocal == NO)
	{
		// If flag is no we can't simply delete a file (this method is intended 
		// to keep it as safe for the user as possible, return NO.
		
		if (flag == NO) return NO;
		
		if (NSRunCriticalAlertPanel([NSString stringWithFormat:@"The file \"%@\" "
			@"will be deleted immediately.\nAre you sure you want to continue?",
			[standardizedSource lastPathComponent]],
									@"You cannot undo this action.",
									@"Delete",
									@"Cancel",
									nil) == NSAlertDefaultReturn)
		{
			return [self removeFileAtPath:standardizedSource handler:nil];
		}
		else
		{
			// User clicked cancel, they obviously do not want to delete the file.
			return NO;
		}
	}
	
	// The file is local, we must move it to the appropriate .Trash folder.
	// The appropriate .Trash folder is ~/Trash if it is on the same drive as the 
	// system, otherwise it is to go into /Volumes/<drivename>/.Trashes/<UID>/filename
	useDiskTrash = [standardizedSource rangeOfString:@"/Volumes/"].location != NSNotFound;
	
	if (useDiskTrash)
	{
		BOOL fileExists, isDirectory;
		NSArray * pathComponents = [standardizedSource pathComponents];
		NSString * trashesFolder = @"/";
		trashesFolder = [trashesFolder stringByAppendingPathComponent:
			[pathComponents objectAtIndex:1]];
		trashesFolder = [trashesFolder stringByAppendingPathComponent:
			[pathComponents objectAtIndex:2]];
		trashesFolder = [trashesFolder stringByAppendingPathComponent:@".Trashes"];
		
		// If the .Trashes folder doesn't exist on this drive we must create it.
		fileExists = [self fileExistsAtPath:trashesFolder isDirectory:&isDirectory];
		if (!fileExists)
		{
			[self createDirectoryAtPath:trashesFolder
							 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithUnsignedLong:777],@"NSFilePosixPermissions",
								 nil]];
		}
		
		trashesFolder = [trashesFolder stringByAppendingPathComponent:
			[NSString stringWithFormat:@"%i",getuid()]];
		
		// If the UID folder doesn't exist we must create it.
		fileExists = [self fileExistsAtPath:trashesFolder isDirectory:&isDirectory];
		if (!fileExists)
		{
			[self createDirectoryAtPath:trashesFolder
							 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithUnsignedLong:777],@"NSFilePosixPermissions",
								 nil]];
		}
		
		NSString * destinationPath = [trashesFolder stringByAppendingPathComponent:
			[standardizedSource lastPathComponent]];
		
		// Make sure there are no duplicates.
		if ([self fileExistsAtPath:destinationPath])
		{
			NSString * pathExtention = [destinationPath pathExtension];
			NSString * pathWithoutExtention = [destinationPath stringByDeletingPathExtension];
			destinationPath = [pathWithoutExtention stringByAppendingFormat:@"_%i",RandomIntBetween(0,10000)];
			if (![destinationPath isEqualToString:@""]) {
				destinationPath = [destinationPath stringByAppendingPathExtension:pathExtention];
			}
		}
		
		return [self movePath:standardizedSource toPath:destinationPath handler:nil];
	}
	
	// Use home trash.
	NSString * destinationPath = [NSHomeDirectory() stringByAppendingPathComponent:@".Trash"];
	destinationPath = [destinationPath stringByAppendingPathComponent:
		[standardizedSource lastPathComponent]];
	
	// Make sure there are no duplicates.
	if ([self fileExistsAtPath:destinationPath])
	{
		NSString * pathExtention = [destinationPath pathExtension];
		NSString * pathWithoutExtention = [destinationPath stringByDeletingPathExtension];
		destinationPath = [pathWithoutExtention stringByAppendingFormat:@"_%i",RandomIntBetween(0,10000)];
		if (![destinationPath isEqualToString:@""]) {
			destinationPath = [destinationPath stringByAppendingPathExtension:pathExtention];
		}
		
	}
	
	return [self movePath:standardizedSource toPath:destinationPath handler:nil];
	
	return NO;
}

@end