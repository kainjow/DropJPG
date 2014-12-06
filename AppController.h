//
//  AppController.h
//  DropJPG
//
//  Copyright 2009 Kevin Wojniak. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class Converter, PrefsController;

@interface AppController : NSObject
{
	Converter *converter;
	PrefsController *prefsController;
}

- (IBAction)sendFeedback:(id)sender;
- (IBAction)openPrefs:(id)sender;

@end
