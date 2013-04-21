//
//  Story.m
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

#import "Story.h"

NSString *const ATStoryTitle = @"title";
NSString *const ATStorySummary = @"summary";
NSString *const ATStoryDate = @"date";
NSString *const ATStoryAuthor = @"author";
NSString *const ATStoryLink = @"link";
NSString *const ATStoryThumbnailLink = @"thumbnailLink";
NSString *const ATStoryContent = @"content";

@implementation Story

@synthesize title, summary, date, author, link, thumbnailLink;
@synthesize content=storyContent;


- (id)init {
    if (self = [super init])
        storyContent = [[NSMutableArray alloc] init];

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super init]) {
		if ([aDecoder allowsKeyedCoding]) {
			[self setTitle:[aDecoder decodeObjectForKey:ATStoryTitle]];
			[self setSummary:[aDecoder decodeObjectForKey:ATStorySummary]];
			[self setDate:[aDecoder decodeObjectForKey:ATStoryDate]];
			[self setAuthor:[aDecoder decodeObjectForKey:ATStoryAuthor]];
			[self setLink:[aDecoder decodeObjectForKey:ATStoryLink]];
			[self setThumbnailLink:[aDecoder decodeObjectForKey:ATStoryThumbnailLink]];
            storyContent = [aDecoder decodeObjectForKey:ATStoryContent];
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:[self title] forKey:ATStoryTitle];
	[aCoder encodeObject:[self summary] forKey:ATStorySummary];
	[aCoder encodeObject:[self date] forKey:ATStoryDate];
	[aCoder encodeObject:[self author] forKey:ATStoryAuthor];
	[aCoder encodeObject:[self link] forKey:ATStoryLink];
	[aCoder encodeObject:[self thumbnailLink] forKey:ATStoryThumbnailLink];
    [aCoder encodeObject:[self content] forKey:ATStoryContent];
}


- (void)addStoryPage:(NSString *)pageContent
{
    [storyContent addObject:pageContent];
}

@end