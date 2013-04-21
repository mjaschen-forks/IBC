//
//  ContentTranslator.h
//  IBC
//
//  Created by Manuel Burghard on 12.05.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RegexKitLite.h"


@interface ContentTranslator : NSObject {
    NSDictionary *iOSTranslations;
    NSDictionary *atTranslations;
}

@property (strong) NSDictionary *iOSTranslations;
@property (strong) NSDictionary *atTranslations;

+ (ContentTranslator *)contentTranslator;
- (NSString *)translateStringForiOS:(NSString *)aString;
- (NSString *)translateStringForAT:(NSString *)aString;
NSString * decodeString(NSString *aString);
NSString * encodeString(NSString *aString);

@end
