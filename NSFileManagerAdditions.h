//
//  NSFileManagerAdditions.h
//  TRKit
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

@interface NSFileManager (TRAdditions)
- (BOOL)trashPath:(NSString *)source showAlerts:(BOOL)flag;
@end
