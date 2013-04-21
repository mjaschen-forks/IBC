//
//  SubForumController.h
//  Tapatalk
//
//  Created by Manuel Burghard on 19.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ATTableViewController.h"
#import "SubForum.h"
#import "Topic.h"
#import "DetailThreadController.h"

@interface SubForumController : ATTableViewController {
    SubForum *subForum;
    Topic *currentTopic;
    NSMutableArray *topics;
    NSMutableArray *dataArray;
    NSInteger numberOfTopics;
    
    BOOL isTopicID, isTopicTitle, isPrefixes, isNewPost, isReplyNumber, isClosed, isSubscribed;
    BOOL isLoadingPinnedTopics;
    BOOL isTotalTopicNumber;
}

@property (strong) SubForum *subForum;
@property (strong) Topic *currentTopic;
@property (strong) NSMutableArray *topics;
@property (assign) BOOL isLoadingPinnedTopics;
@property (assign) NSInteger numberOfTopics;
@property (strong) NSMutableArray *dataArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil subForum:(SubForum *)aSubForum;

@end
