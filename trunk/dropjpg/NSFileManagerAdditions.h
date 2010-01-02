//
//  NSFileManagerAdditions.h
//  DropJPG
//
//  Created by Kevin Wojniak on 9/22/09.
//  Copyright 2009 Kevin Wojniak. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSFileManager (DJAdditions)

- (NSURL *)makeUniqueURL:(NSURL *)URL;

@end
