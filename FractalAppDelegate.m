//
//  MandelbrotAppDelegate.m
//  Mandelbrot
//
//  Created by Ishaan Gulrajani on 12/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FractalAppDelegate.h"
#import "FractalGenerator.h"
#import "ClickableImageView.h"
#import <QuartzCore/QuartzCore.h>
#import "NSView+AMAnimationAdditions.h"

@implementation FractalAppDelegate
@synthesize window, imageView, imageView2, textField;

-(void)dealloc {
	[generator release];
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	generator = [[FractalGenerator alloc] init];
	imageView.clickDelegate = self;
	[imageView setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawOnSetNeedsDisplay];
	[imageView2 setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawOnSetNeedsDisplay];
	
	[textField setFont:[NSFont systemFontOfSize:24.0]];
	[textField setAlphaValue:0.0];
	
	NSRect frame = textField.frame;
	frame.size.height += 14.0;
	[textField setFrame:frame];

	[textField.layer setOpaque:NO];
	[textField setAlphaValue:0.0];
	[textField setHidden:0];
	
	[self performSelector:@selector(showTextField) withObject:nil afterDelay:1.0];
	[self performSelector:@selector(hideTextField) withObject:nil afterDelay:3.0];
	
	[self updateFractal];
}

-(void)windowWillStartLiveResize:(NSNotification *)notification {
	dontUpdateOnResize = YES;
}

-(void)windowDidEndLiveResize:(NSNotification *)notification {
	dontUpdateOnResize = NO;
	[self updateFractal];
}

-(void)windowDidResize:(NSNotification *)notification {
	if(!dontUpdateOnResize)
		[self updateFractal];
}

-(void)imageViewClicked:(NSEvent *)theEvent {
	[self zoomIn:YES event:theEvent];
}

-(void)imageViewRightClicked:(NSEvent *)theEvent {
	[self zoomIn:NO event:theEvent];
}

-(void)zoomIn:(BOOL)zoomIn event:(NSEvent *)event {
	if(!zoomIn && generator.zoom >= 0.01)
		return;
	
	int zoomFactor = 4;
	
	[imageView2 setHidden:NO];
	[imageView setHidden:YES];
	imageView2.image = imageView.image;
	NSRect f = [imageView2 frame];
	f.origin.x = 0;
	f.origin.y = 0;
	f.size.width = imageView.frame.size.width;
	f.size.height = imageView.frame.size.height;
	imageView2.frame = f;
	
	NSPoint location = [event locationInWindow];
	f.origin.x -= (zoomIn? zoomFactor : 1.0/zoomFactor)*location.x - f.size.width/2;
	f.origin.y -= (zoomIn? zoomFactor : 1.0/zoomFactor)*location.y - f.size.height/2;
	f.size.width *= (zoomIn? zoomFactor : 1.0/zoomFactor);
	f.size.height *= (zoomIn? zoomFactor : 1.0/zoomFactor);

	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithRect:f],NSViewAnimationEndFrameKey,imageView2,NSViewAnimationTargetKey,nil];
	NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:params]];
	[animation setAnimationBlockingMode:NSAnimationNonblocking];
	[animation setDuration:0.5];
	[animation setAnimationCurve:NSAnimationEaseInOut];
	[animation startAnimation];
	[animation release];
	
	
	zoomFinished = NO;
	[self performSelector:@selector(finishZoom) withObject:nil afterDelay:0.5f];

	location.x -= (int)(imageView.bounds.size.width/2);
	location.y -= (int)(imageView.bounds.size.height/2);
	location.x *= generator.zoom;
	location.y *= generator.zoom;
	generator.centerX += location.x;
	generator.centerY += location.y;
	generator.zoom /= (zoomIn? zoomFactor : 1.0/zoomFactor);
	
	[self updateFractal];
}

-(void)updateFractal {
	generator.width = (int)imageView.bounds.size.width;
	generator.height = (int)imageView.bounds.size.height;

	[generator generateImageFor:self callback:@selector(displayFractal:)];
	fractalGenerated = NO;
}

-(void)displayFractal:(NSImage *)image {
	[imageView setImage:image];
	fractalGenerated = YES;
	
	if(zoomFinished)
		[self finishZoom];
}

-(void)finishZoom {
	if(fractalGenerated) {
		[imageView setHidden:NO];
		[imageView2 setHidden:YES];
	}
	zoomFinished = YES;
}

-(void)showTextField {
	[NSAnimationContext beginGrouping];
	[[textField animator] setAlphaValue:0.6];
	[NSAnimationContext endGrouping];	
}

-(void)hideTextField {
	[NSAnimationContext beginGrouping];
	[[textField animator] setAlphaValue:0.0];
	[NSAnimationContext endGrouping];
}

@end
