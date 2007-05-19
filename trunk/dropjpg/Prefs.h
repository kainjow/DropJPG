#import <AppKit/AppKit.h>


@interface Prefs : NSWindowController
{
    IBOutlet NSMatrix *matrix;
    IBOutlet NSSlider *slider;
}

- (IBAction)save:(id)sender;

@end
