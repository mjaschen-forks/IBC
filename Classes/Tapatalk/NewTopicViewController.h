//
//  NewTopicViewController.h
//  IBC
//
//  Created by Manuel Burghard on 14.05.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AnswerViewController.h"
#import "SubForum.h"

@interface NewTopicViewController : AnswerViewController <NSXMLParserDelegate> {
    SubForum *forum;
    UITextField *topicField;
}

@property (strong) SubForum *forum;
@property (strong) UITextField *topicField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil forum:(SubForum *)aForum;

@end
