//
//  ClickableImageView.h
//  Mandelbrot
//
//  Created by Ishaan Gulrajani on 12/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ClickableImageView : NSImageView {
	id clickDelegate;
}
@property(assign) id clickDelegate;

@end
