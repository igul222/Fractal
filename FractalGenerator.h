//
//  FractalGenerator.h
//  Mandelbrot
//
//  Created by Ishaan Gulrajani on 12/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FractalGenerator : NSObject {
	int width;
	int height;
	long double centerX;
	long double centerY;
	long double zoom;
	
	
	int e_width;
	int e_height;
	uint8_t* bitmap_data;
	
	id target;
	SEL callback;
	int workerCount;
	
	CFAbsoluteTime bm_start_time;
}
@property int width;
@property int height;
@property long double centerX;
@property long double centerY;
@property long double zoom;

-(void)generateImageFor:(id)theTarget callback:(SEL)theCallback;

@end
