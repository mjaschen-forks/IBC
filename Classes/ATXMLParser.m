//
//  ATXMLParser.m
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

#import "ATXMLParser.h"
#import "Story.h"


@implementation ATXMLParser

@synthesize delegate;
@synthesize storyClass;
@synthesize story;
@synthesize stories;
@synthesize dateElementName;
@synthesize dateFormatter;
@synthesize currentContent;
@synthesize desiredElementKeys;
@synthesize htmlEntities;


+ (ATXMLParser *)parserWithURLString:(NSString *)urlString
{
    return [[ATXMLParser alloc] initWithURLString:urlString];
}

+ (ATXMLParser *)parserWithData:(NSData *)data
{
	return [[ATXMLParser alloc] initWithData:data];
}

- (id) init
{
	self = [super init];
	if (self != nil) {
		[self setStoryClass:[Story self]];
		[self setDateElementName:@"pubDate"];
		[self setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz" localeIdentifier:@"en_US"];
        self.htmlEntities = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"HTMLEntities" ofType:@"plist"]];
	}
	return self;
}

- (id) initWithData:(NSData *)data {
    if ((self = [self init]))
    {
        xmlParser = [[NSXMLParser alloc] initWithData:data];
		if (xmlParser == nil)
			return nil;
		// :below:20091021 At least fail if initialization was unsuccessful
		[xmlParser setDelegate:self];
    }
	
    return self;
}

- (id)initWithURLString:(NSString *)urlString
{
    if ((self = [self init]))
    {
        xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:[NSURL URLWithString:urlString]];
		if (xmlParser == nil)
			return nil;
		[xmlParser setDelegate:self];
    }

    return self;
}






- (void)setDateFormat:(NSString *)format localeIdentifier:(NSString *)identifier
{
    NSLocale        *locale = [[NSLocale alloc] initWithLocaleIdentifier:identifier];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];

    [formatter setDateFormat:format];
    [formatter setLocale:locale];
    [self setDateFormatter:formatter];

}



- (BOOL)parse
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    return [xmlParser parse];
}



- (void)parseInBackgroundWithDelegate:(id <ATXMLParserDelegateProtocol>)object
{
    BOOL               result;
    

        [self setDelegate:object];

        result = [self parse];
        if ([(NSObject *)delegate respondsToSelector:@selector(parser:didFinishedSuccessfull:)])
            [delegate parser:self didFinishedSuccessfull:result];

    }



#pragma mark -
#pragma mark NSXMLParser delegate methods

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    [self setStories:[NSMutableArray array]];
}



- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [delegate parser:self setParsedStories:stories];
}



- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"item"])
    {
        id storyObject = [[storyClass alloc] init];
        [self setStory:storyObject];
    }
    else if ([[desiredElementKeys allKeys] containsObject:elementName])
    {
        if ([elementName isEqualToString:@"enclosure"])
            [story setLink:[attributeDict valueForKey:@"url"]];
        else
            [self setCurrentContent:[NSMutableString string]];
    }
}



- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	[[self currentContent] appendString:string];
}



- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:@"item"])
    {
        if ([(NSObject *)delegate respondsToSelector:@selector(parser:shouldAddParsedItem:)])
        {
            if ([delegate parser:self shouldAddParsedItem:[self story]])
                [stories addObject:[self story]];
        }
        else
        {
            [stories addObject:[self story]];
        }
    }
    else if ([[desiredElementKeys allKeys] containsObject:elementName])
    {
        if ([elementName isEqualToString:[self dateElementName]])
        {
            NSDate *date = [[self dateFormatter] dateFromString:[self currentContent]];
            [story setValue:date forKey:[desiredElementKeys objectForKey:elementName]];
        }
        else
        {
            NSString *storyKey = [desiredElementKeys objectForKey:elementName];
            if ([storyKey length] > 0)
            {
                for (NSString *htmlEntity in [htmlEntities allKeys])
                    [self.currentContent replaceOccurrencesOfString:htmlEntity withString:[htmlEntities objectForKey:htmlEntity] options:NSLiteralSearch
                                                              range:NSMakeRange(0, self.currentContent.length)];

                [story setValue:[self currentContent] forKey:storyKey];
            }
        }
    }
}



- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [delegate parser:self parseErrorOccurred:parseError];
}

@end
