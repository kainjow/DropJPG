#import "Prefs.h"


@implementation Prefs

- (id)init
{
    if (self = [super initWithWindowNibName:@"Preferences"])
	{
		[self setWindowFrameAutosaveName:@"Preferences"];
	}
	
    return self;
}

- (void)awakeFromNib
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [slider setFloatValue:[[[NSUserDefaults standardUserDefaults] objectForKey:@"quality"] floatValue]];
    [[matrix cellAtRow:0 column:0] setState:[[defaults objectForKey:@"delete"] boolValue]];
    [[matrix cellAtRow:1 column:0] setState:[[defaults objectForKey:@"capitalize"] boolValue]];
    [[matrix cellAtRow:2 column:0] setState:[[defaults objectForKey:@"quit"] boolValue]];
    [[matrix cellAtRow:3 column:0] setState:[[defaults objectForKey:@"showinfinder"] boolValue]];
    [[matrix cellAtRow:4 column:0] setState:[[defaults objectForKey:@"dest"] boolValue]];
}

- (IBAction)save:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithFloat:[slider floatValue]] forKey:@"quality"];
    [defaults setObject:[NSNumber numberWithBool:[[matrix cellAtRow:0 column:0] state]] forKey:@"delete"];
    [defaults setObject:[NSNumber numberWithBool:[[matrix cellAtRow:1 column:0] state]] forKey:@"capitalize"];
    [defaults setObject:[NSNumber numberWithBool:[[matrix cellAtRow:2 column:0] state]] forKey:@"quit"];
    [defaults setObject:[NSNumber numberWithBool:[[matrix cellAtRow:3 column:0] state]] forKey:@"showinfinder"];
    [defaults setObject:[NSNumber numberWithBool:[[matrix cellAtRow:4 column:0] state]] forKey:@"dest"];
}

@end
