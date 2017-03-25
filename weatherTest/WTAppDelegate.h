//
//  WTAppDelegate.h
//  weatherTest
//
//  Created by Bjorn Chambless on 6/9/13.
//  Copyright (c) 2013 Bjorn Chambless. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface WTAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *tempField;
@property (assign) IBOutlet NSFormCell *latCell;
@property (assign) IBOutlet NSFormCell *longCell;
@property (assign) IBOutlet NSFormCell *zipCell;

-(IBAction) get_temp:(id)sender;
-(void) readTempData;

@end
