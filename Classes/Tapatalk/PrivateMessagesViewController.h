//
//  PrivateMessagesViewController.h
//  IBC
//
//  Created by Manuel Burghard on 21.08.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATTableViewController.h"
#import "Three20/Three20.h"
#import "Three20/Three20+Additions.h"
#import "ATContactPicker.h"

@interface PrivateMessagesViewController : ATTableViewController {
    NSMutableArray *boxes;
}

@property (strong) NSMutableArray *boxes;

- (void)updateTabBarItemBadge;
- (void)writeMessageWithRecipients:(NSArray *)recipients;

@end
