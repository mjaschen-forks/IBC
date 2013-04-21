//
//  ATContactDataSource.h
//  IBC
//
//  Created by Manuel Burghard on 30.08.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Three20/Three20.h"
#import "Three20/Three20+Additions.h"

@class ATContactModel;

@interface ATContactDataSource : TTSectionedDataSource {
    ATContactModel* contactModel;
    TTMessageController *__weak messageController;
}

@property (strong) ATContactModel* contactModel;
@property (weak) TTMessageController *messageController;

@end