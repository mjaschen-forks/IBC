//
//  ATMXMLUtilities.h
//  IBC
//
//  Created by Alexander v. Below on 21.09.09.
//  Copyright 2009 AVB Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libxml/tree.h>


@interface ATMXMLUtilities : NSObject
{
    xmlDocPtr theXMLDoc;
}

@property (nonatomic, strong) NSDictionary *xPaths;

+ (ATMXMLUtilities *)xmlUtilitiesWithURLString:(NSString *)urlString;

- (id)initWithURLString:(NSString *)urlString;

- (NSString *)authorName;
- (NSString *)articleContent;
- (NSArray *)articlePagesLinks;

@end

NSString *extractTextFromHTMLForQuery (NSString *htmlInput, NSString *query);
