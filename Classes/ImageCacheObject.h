//
//  ImageCacheObject.h
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

#import <Foundation/Foundation.h>


@interface ImageCacheObject : NSObject {
    NSUInteger size;    // size in bytes of image data
    NSDate *timeStamp;  // time of last access
    UIImage *image;     // cached image
}

@property (nonatomic, readonly) NSUInteger size;
@property (nonatomic, strong, readonly) NSDate *timeStamp;
@property (nonatomic, strong, readonly) UIImage *image;

-(id)initWithSize:(NSUInteger)sz Image:(UIImage*)anImage;
-(void)resetTimeStamp;

@end
