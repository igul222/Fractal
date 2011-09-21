//
//  ClickableImageView.m
//  Mandelbrot
//
//  Created by Ishaan Gulrajani on 12/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ClickableImageView.h"


@implementation ClickableImageView
@synthesize clickDelegate;

-(void)mouseDown:(NSEvent *)theEvent {
	if([clickDelegate respondsToSelector:@selector(imageViewClicked:)])
		[clickDelegate performSelector:@selector(imageViewClicked:) withObject:theEvent];
}

-(void)rightMouseDown:(NSEvent *)theEvent {
	if([clickDelegate respondsToSelector:@selector(imageViewRightClicked:)])
		[clickDelegate performSelector:@selector(imageViewRightClicked:) withObject:theEvent];
}


@end
