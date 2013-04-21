//
//  Story.h
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


extern NSString *const ATStoryTitle;
extern NSString *const ATStorySummary;
extern NSString *const ATStoryDate;
extern NSString *const ATStoryAuthor;
extern NSString *const ATStoryLink;
extern NSString *const ATStoryThumbnailLink;
extern NSString *const ATStoryContent;


@interface Story : NSObject <NSCoding> {
	NSString *title;
	NSString *summary;
	NSDate *date;
	NSString *author;
	NSString *link;
	NSString *thumbnailLink;
    NSMutableArray *storyContent;
}

@property (readwrite, copy) NSString *title;
@property (readwrite, copy) NSString *summary;
@property (readwrite, copy) NSDate *date;
@property (readwrite, copy) NSString *author;
@property (readwrite, copy) NSString *link;
@property (readwrite, copy) NSString *thumbnailLink;
@property (readonly, strong) NSArray *content;

- (void)addStoryPage:(NSString *)pageContent;

@end