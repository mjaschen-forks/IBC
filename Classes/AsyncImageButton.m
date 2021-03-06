//
//  AsyncImageView.m
//  IBC
//
//	IBC Magazin -- An iPhone Application for the site http://www.mtb-news.de
//	Copyright (C) 2011	Stephan König (s dot konig at me dot com), Manuel Burghard
//						Alexander von Below
//						
//	This program is free software; you can redistribute it and/or
//	modify it under the terms of the GNU General Public License
//	as published by the Free Software Foundation; either version 2
//	of the License, or (at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with this program; if not, write to the Free Software
//	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.//
//

#import "AsyncImageButton.h"
#import "ImageCacheObject.h"
#import "ImageCache.h"

#define SPINNY_TAG 5555   

//
// Key's are URL strings.
// Value's are ImageCacheObject's
//
static ImageCache *imageCache = nil;

@implementation AsyncImageButton

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
    }
    return self;
}

- (void)dealloc {
    [connection cancel];
}

-(void)loadImageFromURL:(NSURL*)url {
    if (connection != nil) {
        [connection cancel];
        connection = nil;
    }
    if (data != nil) {
        data = nil;
    }
    
    if (imageCache == nil) // lazily create image cache
        imageCache = [[ImageCache alloc] initWithMaxSize:2*1024*1024];  // 2 MB Image cache
    
    UIView *spinnyDelete = [self viewWithTag:SPINNY_TAG];
    [spinnyDelete removeFromSuperview];

    urlString = [[url absoluteString] copy];
    UIImage *cachedImage = [imageCache imageForKey:urlString];
    
    [self setBackgroundImage:nil forState:UIControlStateNormal];

    if (cachedImage != nil) {
        [self setBackgroundImage:cachedImage forState:UIControlStateNormal];
        [self setContentMode:UIViewContentModeScaleAspectFit];
        //self.autoresizingMask = 
        //UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self setNeedsLayout];
        return;
    }
        
    UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinny.tag = SPINNY_TAG;
	CGPoint spinnyCenter = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);

	//spinnyCenter.x = spinnyCenter.x - 5;
    //spinnyCenter.y = spinnyCenter.y - 5;
	spinny.center = spinnyCenter;
    [spinny startAnimating];
    [self addSubview:spinny];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url 
                                             cachePolicy:NSURLRequestUseProtocolCachePolicy 
                                         timeoutInterval:60.0];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void)connection:(NSURLConnection *)connection 
    didReceiveData:(NSData *)incrementalData {
    if (data==nil) {
        data = [[NSMutableData alloc] initWithCapacity:2048];
    }
    [data appendData:incrementalData];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
    connection = nil;
    
    UIView *spinny = [self viewWithTag:SPINNY_TAG];
    [spinny removeFromSuperview];
    
    //if ([[self subviews] count] > 0) {
      //  [[[self subviews] objectAtIndex:0] removeFromSuperview];
    //}
    
    UIImage *image = [UIImage imageWithData:data];
    
    [imageCache insertImage:image withSize:[data length] forKey:urlString];
    
	[self setBackgroundImage:image forState:UIControlStateNormal];
    [self setContentMode:UIViewContentModeScaleAspectFit];
    //self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
    [self setNeedsLayout];
    data = nil;
}

- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error {
    connection = nil;
    
    UIView *spinny = [self viewWithTag:SPINNY_TAG];
    [spinny removeFromSuperview];
    
    [self setNeedsLayout];
    data = nil;
}

@end
