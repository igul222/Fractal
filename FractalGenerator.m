//
//  FractalGenerator.m
//  Mandelbrot
//
//  Created by Ishaan Gulrajani on 12/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FractalGenerator.h"
#include <math.h>

#define START_BENCH CFTimeInterval bench_t1 = CFAbsoluteTimeGetCurrent()
#define END_BENCH NSLog(@"Benchmark: %f",CFAbsoluteTimeGetCurrent()-bench_t1)

#define DEBUG_MODE 0

static inline void HSVtoRGB( long double *r, long double *g, long double *b, long double h, long double s, long double v )
{
	//NSLog(@"Hue %f",h);
	int i;
	long double f, p, q, t;
	if( s == 0 ) {
		// achromatic (grey)
		*r = *g = *b = v;
		return;
	}
	h /= 60;			// sector 0 to 5
	i = floor( h );
	f = h - i;			// factorial part of h
	p = v * ( 1 - s );
	q = v * ( 1 - s * f );
	t = v * ( 1 - s * ( 1 - f ) );
	switch( i ) {
		case 0:
			*r = v;
			*g = t;
			*b = p;
			break;
		case 1:
			*r = q;
			*g = v;
			*b = p;
			break;
		case 2:
			*r = p;
			*g = v;
			*b = t;
			break;
		case 3:
			*r = p;
			*g = q;
			*b = v;
			break;
		case 4:
			*r = t;
			*g = p;
			*b = v;
			break;
		default:		// case 5:
			*r = v;
			*g = p;
			*b = q;
			break;
	}
}


static inline void color_bitmap_data_point(uint8_t* bitmap_data, int width, unsigned x, unsigned y, BOOL isInside, unsigned n) {
	if(isInside) {
		if(DEBUG_MODE) {
			bitmap_data[4*width*y+4*x] = 0xFF;
			bitmap_data[4*width*y+4*x+1] = 0xFF;
			bitmap_data[4*width*y+4*x+2] = 0xFF;
		} else {
			bitmap_data[4*width*y+4*x] = 0x00;
			bitmap_data[4*width*y+4*x+1] = 0x00;
			bitmap_data[4*width*y+4*x+2] = 0x00;			
		}
		bitmap_data[4*width*y+4*x+3] = 0xFF; // alpha channel is ignored, so we use it to designate calculated vs. non-calculated
	}
	else {
		long double hue = 0.5+(.005*n);
		hue -= floor(hue);
		long double r, g, b;
		HSVtoRGB(&r, &g, &b, hue*360, 1.0f, 0.8f);
				
		bitmap_data[4*width*y+4*x] = (uint8_t)floor(r*255);
		bitmap_data[4*width*y+4*x+1] = (uint8_t)floor(g*255);
		bitmap_data[4*width*y+4*x+2] = (uint8_t)floor(b*255);
		bitmap_data[4*width*y+4*x+3] = 0xFF;		
	}
}

static inline BOOL bitmap_data_points_equal(uint8_t* bitmap_data, int width, unsigned x1, unsigned y1, unsigned x2, unsigned y2) {
	BOOL t1 = (bitmap_data[4*width*y1+4*x1] == bitmap_data[4*width*y2+4*x2]);
	BOOL t2 = (bitmap_data[4*width*y1+4*x1+1] == bitmap_data[4*width*y2+4*x2+1]);
	BOOL t3 = (bitmap_data[4*width*y1+4*x1+2] == bitmap_data[4*width*y2+4*x2+2]);
	return (t1 && t2 && t3);
}

static inline BOOL bitmap_data_point_empty(uint8_t* bitmap_data, int width, unsigned x, unsigned y) {
	return (bitmap_data[4*width*y+4*x+3] != 0xFF);
}

static inline void copy_bitmap_data_point_to_point(uint8_t* bitmap_data, int width, unsigned x1, unsigned y1, unsigned x2, unsigned y2) {
	bitmap_data[4*width*y2+4*x2] = bitmap_data[4*width*y1+4*x1];
	bitmap_data[4*width*y2+4*x2+1] = bitmap_data[4*width*y1+4*x1+1];
	bitmap_data[4*width*y2+4*x2+2] = bitmap_data[4*width*y1+4*x1+2];
	bitmap_data[4*width*y2+4*x2+3] = 0xFF;
}

void mandelbrot(unsigned x, unsigned y, unsigned max_iterations, long double zoom, long double maxY, long double minX, uint8_t* bitmap_data, int width) {
	if(!bitmap_data_point_empty(bitmap_data, width, x, y))
		return;
	
	long double c_im = maxY - y*zoom;
	long double c_re = minX + x*zoom;
	
	long double Z_re = c_re, Z_im = c_im;
	BOOL isInside = true;
	unsigned n;
	for(n=0; n<max_iterations; n++)
	{
		long double Z_re2 = Z_re*Z_re, Z_im2 = Z_im*Z_im;
		if(Z_re2 + Z_im2 > 4)
		{
			isInside = false;
			break;
		}
		Z_im = 2*Z_re*Z_im + c_im;
		Z_re = Z_re2 - Z_im2 + c_re;
	}
	
	color_bitmap_data_point(bitmap_data,width,x,y,isInside,n);
}

void fill_rect(uint8_t* bitmap_data, int width, unsigned x1, unsigned y1, unsigned x2, unsigned y2, unsigned max_iterations, long double zoom, long double maxY, long double minX, FractalGenerator *generator, int r_level) {	
	int max_concurrency_level = 1;
	
	// force at least one recursion because if the frame is large enough, the entire perimeter could be the same color
	if(r_level == 0)
		goto split;
	
	// if the square is small enough, just fill it the simple way
	if(((x2-x1) < 2) || ((y2-y1) < 2)) {
		for(int i=x1;i<=x2;i++) {
			for(int j=y1;j<=y2;j++) {
				mandelbrot(i, j, max_iterations, zoom, maxY, minX, bitmap_data, width);
			}
		}
		goto ret;
	}
	
	// calculate values for the corners
	mandelbrot(x1, y1, max_iterations, zoom, maxY, minX, bitmap_data, width);
	mandelbrot(x1, y2, max_iterations, zoom, maxY, minX, bitmap_data, width);
	mandelbrot(x2, y1, max_iterations, zoom, maxY, minX, bitmap_data, width);
	mandelbrot(x2, y2, max_iterations, zoom, maxY, minX, bitmap_data, width);
	
	// make sure the corners are equal
	if(!bitmap_data_points_equal(bitmap_data, width, x1, y1, x2, y1) ||
	   !bitmap_data_points_equal(bitmap_data, width, x1, y1, x1, y2) ||
	   !bitmap_data_points_equal(bitmap_data, width, x1, y1, x2, y2))
		goto split;
	
	// draw a perimeter, and split if any point isn't equal
	for(int i=x1+1;i<x2;i++) {
		// top
		mandelbrot(i,y1,max_iterations,zoom,maxY,minX,bitmap_data,width);
		if(!bitmap_data_points_equal(bitmap_data, width, x1, y1, i, y1))
			goto split;
		// bottom
		mandelbrot(i,y2,max_iterations,zoom,maxY,minX,bitmap_data,width);
		if(!bitmap_data_points_equal(bitmap_data, width, x1, y1, i, y2))
			goto split;
	}
	
	for(int i=y1+1;i<y2;i++) {
		// left
		mandelbrot(x1,i,max_iterations,zoom,maxY,minX,bitmap_data,width);
		if(!bitmap_data_points_equal(bitmap_data, width, x1, y1, x1, i))
			goto split;
		// right
		mandelbrot(x2,i,max_iterations,zoom,maxY,minX,bitmap_data,width);
		if(!bitmap_data_points_equal(bitmap_data, width, x1, y1, x2, i))
			goto split;
	}
			
	// we've done it, we've drawn a perimeter! now just fill the square in.
	if(!DEBUG_MODE) {
		for(int i=x1+1;i<x2;i++) {
			for(int j=y1+1;j<y2;j++) {
				copy_bitmap_data_point_to_point(bitmap_data, width, x1, y1, i, j);
			}
		}
	}
	goto ret;
	
	unsigned int x_midpoint, y_midpoint;

split:
	// one of the tests failed; split our square into 4 more squares and recurse!
		
	x_midpoint = (x1+x2)/2;
	y_midpoint = (y1+y2)/2;
	
	if(r_level < max_concurrency_level) {
		for(int i=0;i<4;i++)
			[generator performSelectorOnMainThread:@selector(incrementWorkerCount) withObject:nil waitUntilDone:NO];

		dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
		dispatch_async(queue, ^(void) {
			fill_rect(bitmap_data,width,	x1				,y1				,x_midpoint		,y_midpoint		,max_iterations,zoom,maxY,minX,generator,r_level+1);
		});
		dispatch_async(queue, ^(void) {
			fill_rect(bitmap_data,width,	x_midpoint+1	,y1				,x2				,y_midpoint		,max_iterations,zoom,maxY,minX,generator,r_level+1);	
		});
		dispatch_async(queue, ^(void) {
			fill_rect(bitmap_data,width,	x1				,y_midpoint+1	,x_midpoint		,y2				,max_iterations,zoom,maxY,minX,generator,r_level+1);
		});
		dispatch_async(queue, ^(void) {
			fill_rect(bitmap_data,width,	x_midpoint+1	,y_midpoint+1	,x2				,y2				,max_iterations,zoom,maxY,minX,generator,r_level+1);		
		});
	} else {
		fill_rect(bitmap_data,width,	x1				,y1				,x_midpoint		,y_midpoint		,max_iterations,zoom,maxY,minX,generator,r_level+1);
		fill_rect(bitmap_data,width,	x_midpoint		,y1				,x2				,y_midpoint		,max_iterations,zoom,maxY,minX,generator,r_level+1);	
		fill_rect(bitmap_data,width,	x1				,y_midpoint		,x_midpoint		,y2				,max_iterations,zoom,maxY,minX,generator,r_level+1);
		fill_rect(bitmap_data,width,	x_midpoint		,y_midpoint		,x2				,y2				,max_iterations,zoom,maxY,minX,generator,r_level+1);		
	}
	
ret:
	if(r_level <= max_concurrency_level)
		[generator performSelectorOnMainThread:@selector(decrementWorkerCount) withObject:nil waitUntilDone:NO];
}

@interface FractalGenerator (PrivateMethods)
-(void)incrementWorkerCount;
-(void)decrementWorkerCount;
-(void)finishAndReturnImage;
@end


@implementation FractalGenerator
@synthesize width, height, centerX, centerY, zoom;

-(id)init {
	if(self = [super init]) {
		centerX = -0.5;
		zoom = 0.005; // units per pixel
	}
	return self;
}

-(void)generateImageFor:(id)theTarget callback:(SEL)theCallback {
	if(workerCount>0)
		NSLog(@"WARNING: generateImageFor:callback: called, but workerCount(%i) is already > 0 !",workerCount);
	
	target = theTarget;
	callback = theCallback;

	// Start benchmark
	bm_start_time = CFAbsoluteTimeGetCurrent();
	
	// antialiasing: generate a larger bitmap than needed
	int aa_factor = 2;
	long double e_zoom = zoom/aa_factor;
	e_width = width*aa_factor;
	e_height = height*aa_factor;
	bitmap_data = (uint8_t*)malloc(4*e_width*e_height);
	long double minX = centerX-(e_zoom*e_width/2.0);
	long double maxY = centerY+(e_zoom*e_height/2.0);
	//unsigned max_iterations = round(64-(32*log10(200*zoom)));
	unsigned max_iterations = 256;
	
	[self incrementWorkerCount];
	fill_rect(bitmap_data,e_width,0,0,e_width-1,e_height-1,max_iterations,e_zoom,maxY,minX,self,0);
}

-(void)incrementWorkerCount {
	workerCount++;
}

-(void)decrementWorkerCount {
	workerCount--;
	if(workerCount==0)
		[self finishAndReturnImage];
}

-(void)finishAndReturnImage {
	CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	CGContextRef context = CGBitmapContextCreateWithData(bitmap_data, e_width, e_height, 8, 4*e_width, colorSpace, kCGImageAlphaNoneSkipLast, NULL, NULL);
	
	CGImageRef cgImage = CGBitmapContextCreateImage(context);
	NSImage *nsImage = [[NSImage alloc] initWithCGImage:cgImage size:NSZeroSize];
	
	CGColorSpaceRelease(colorSpace);
	CGContextRelease(context);
	CGImageRelease(cgImage);
	free(bitmap_data);
	
	// antialiasing: resize the resulting image to its intended width/height
	[nsImage setSize:NSMakeSize((CGFloat)width, (CGFloat)height)];
	NSLog(@"Render finished in %f",CFAbsoluteTimeGetCurrent()-bm_start_time);
	
	[target performSelector:callback withObject:[nsImage autorelease]];
}

@end
