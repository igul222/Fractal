//
//  MandelbrotAppDelegate.h
//  Mandelbrot
//
//  Created by Ishaan Gulrajani on 12/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ClickableImageView, FractalGenerator;
@interface FractalAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate> {
    NSWindow *window;
	ClickableImageView *imageView;
	NSImageView *imageView2;
	NSTextField *textField;
	BOOL dontUpdateOnResize;
	FractalGenerator *generator;
	
	BOOL fractalGenerated;
	BOOL zoomFinished;
}
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet ClickableImageView *imageView;
@property (assign) IBOutlet NSImageView *imageView2;
@property (assign) IBOutlet NSTextField *textField;

-(void)updateFractal;
-(void)displayFractal:(NSImage *)fractal;
-(void)zoomIn:(BOOL)zoomIn event:(NSEvent *)event;
-(void)finishZoom;
-(void)showTextField;
-(void)hideTextField;

@end
