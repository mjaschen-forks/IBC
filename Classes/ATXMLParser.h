//
//  ATXMLParser.h
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

@class ATXMLParser;


@protocol ATXMLParserDelegateProtocol

@optional
- (void)parser:(ATXMLParser *)parser didFinishedSuccessfull:(BOOL)success;
- (BOOL)parser:(ATXMLParser *)parser shouldAddParsedItem:(id)item;

@required
- (void)parser:(ATXMLParser *)parser setParsedStories:(NSArray *)parsedStories;
- (void)parser:(ATXMLParser *)parser parseErrorOccurred:(NSError *)parserError;

@end



#pragma mark -

@interface ATXMLParser : NSObject <NSXMLParserDelegate>
{
    id <ATXMLParserDelegateProtocol> __weak delegate;
    Class                            storyClass;
    id                               story;
    NSMutableArray                  *stories;
    NSString                        *dateElementName;
    NSDateFormatter                 *dateFormatter;
    NSMutableString                 *currentContent;
    NSDictionary                    *desiredElementKeys;
    NSDictionary                    *htmlEntities;

@private
    NSXMLParser  *xmlParser;
}

@property(weak) id <ATXMLParserDelegateProtocol> delegate;
@property(assign) Class storyClass;
@property(strong) id story;
@property(strong) NSMutableArray *stories;
@property(copy) NSString *dateElementName;
@property(strong) NSDateFormatter *dateFormatter;
@property(strong) NSMutableString *currentContent;
@property(strong) NSDictionary *desiredElementKeys;
@property(strong) NSDictionary *htmlEntities;

+ (ATXMLParser *)parserWithURLString:(NSString *)urlString;
+ (ATXMLParser *)parserWithData:(NSData *)data;

- (id)initWithURLString:(NSString *)urlString;
- (id) initWithData:(NSData *)data;
- (void)setDateFormat:(NSString *)format localeIdentifier:(NSString *)identifier;
- (BOOL)parse;
- (void)parseInBackgroundWithDelegate:(id <ATXMLParserDelegateProtocol>)object;

@end
