//
//  DetailThreadController.m
//  Tapatalk
//
//  Created by Manuel Burghard on 21.04.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DetailThreadController.h"
#import "ATWebViewController.h"
#import "AnswerViewController.h"
#import "PrivateMessagesViewController.h"
#import "Apfeltalk_MagazinAppDelegate.h"

@interface DetailThreadController()

- (NSInteger)numberOfSites;

@end

@implementation DetailThreadController
@synthesize topic, posts, currentPost, site, numberOfPosts, answerCell, username;

const CGFloat kDefaultRowHeight = 44.0;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil topic:(Topic *)aTopic {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.topic = aTopic;
        self.posts = [NSMutableArray array];
        self.site = 0;
        self.numberOfPosts = self.topic.numberOfPosts + 1;
        isAnswering = NO;
    }
    return self;
}

- (void)dealloc {
    self.site = 0;
    self.numberOfPosts = 0;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark -
#pragma mark Private and Public Methods

- (void)displayActivityIndicator {
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationItem.backBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self.tableView setScrollEnabled:NO];
    /*CGPoint center = self.tableView.center;
     center.y += self.tableView.contentOffset.y;
     center = [UIApplication sharedApplication].keyWindow.center;
     center.x += self.view.frame.origin.x;*/
    if (isAnswering) {
        [[SHKActivityIndicator currentIndicator] displayActivity:ATLocalizedString(@"Sending...", nil)];
    } else if (isSubscribing) {
        [[SHKActivityIndicator currentIndicator] displayActivity:(self.topic.subscribed ? ATLocalizedString(@"Unsubscribing", nil) : ATLocalizedString(@"Subscribing", nil))]; 
    } else {
        [[SHKActivityIndicator currentIndicator] displayActivity:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Site %i of %i", @"ATLocalizable", @""), site+1, [self numberOfSites]]];
    }
}

- (void)dismissActivityIndicator {
    self.navigationItem.backBarButtonItem.enabled = YES;
    self.navigationItem.leftBarButtonItem.enabled = YES;
    self.navigationItem.rightBarButtonItem.enabled = YES;
    [self.tableView setScrollEnabled:YES];
    if (isAnswering) {
        [[SHKActivityIndicator currentIndicator] displayCompleted:@""];
    } else if (isSubscribing) {
        [[SHKActivityIndicator currentIndicator] displayCompleted:@""]; 
    } else {
        [[SHKActivityIndicator currentIndicator] hide];
    }
    
}

- (CGFloat)groupedCellMarginWithTableWidth:(CGFloat)tableViewWidth
{
    CGFloat marginWidth;
    if(tableViewWidth > 20)
    {
        if(tableViewWidth < 400)
        {
            marginWidth = 10;
        }
        else
        {
            marginWidth = MAX(31, MIN(45, tableViewWidth*0.06));
        }
    }
    else
    {
        marginWidth = tableViewWidth - 10;
    }
    return marginWidth;
}

- (void)loginWasSuccessful {
    self.topic.userCanPost = YES;
    NSArray *indexes = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:1 inSection:[self.posts count]]];
    [self.tableView performSelectorOnMainThread:@selector(reloadRowsAtIndexPaths:withRowAnimation:) withObject:indexes waitUntilDone:NO];
}

- (NSInteger)numberOfSites {
    NSInteger numberOfSites;
    if (numberOfPosts % 10 == 0) {
        numberOfSites = numberOfPosts / 10;
    } else {
        numberOfSites = numberOfPosts / 10 + 1;
    }
    return numberOfSites;
}

- (void)loadLastSite {
    site = [self numberOfSites]-1; 
}

- (void)loadThread {
    NSString *xmlString = [NSString stringWithFormat:@"<?xml version=\"1.0\"?><methodCall><methodName>get_thread</methodName><params><param><value><string>%i</string></value></param><param><value><int>%i</int></value></param><param><value><int>%i</int></value></param></params></methodCall>", self.topic.topicID, self.site*10, self.site*10+9];
    [self sendRequestWithXMLString:xmlString cookies:YES delegate:self];
    if (self.site == [self numberOfSites]-1 && self.topic.hasNewPost) {
        xmlString = [NSString stringWithFormat:@"<?xml version=\"1.0\"?><methodCall><methodName>mark_topic_read</methodName><params><param><value><array><data><value><string>%i</string></value></data></array></value></param></params></methodCall>", self.topic.topicID];
        
        [self sendRequestWithXMLString:xmlString cookies:YES delegate:nil];
        self.topic.hasNewPost = NO;
    }
}

- (void)endEditing:(UIBarButtonItem *)sender {
    [activeView resignFirstResponder];
    [self.navigationItem setLeftBarButtonItem:nil animated:NO];
    self.navigationItem.hidesBackButton = NO;
}

- (void)reply {
    if (![[User sharedUser] isLoggedIn]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Error", @"ATLocalizable", @"") message:NSLocalizedStringFromTable(@"Please login...", @"ATLocalizable", @"") delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"ATLocalizable", @"") otherButtonTitles:nil, nil];
        alertView.tag = 2;
        [alertView show];
        return;
    } else if (!self.topic.userCanPost) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Error", @"ATLocalizable", @"") message:NSLocalizedStringFromTable(@"You don't have rights to answer", @"ATLocalizable", @"") delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"ATLocalizable", @"") otherButtonTitles:nil, nil];
        [alertView show];
        return;
    } else if (self.topic.closed) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Error", @"ATLocalizable", @"") message:NSLocalizedStringFromTable(@"Topic is closed", @"ATLocalizable", @"") delegate:nil cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"ATLocalizable", @"") otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
    
    [self endEditing:nil];
    isAnswering = YES;
    [self displayActivityIndicator];
    
    ContentTranslator *translator = [[ContentTranslator alloc] init];
    NSString *content = [translator translateStringForAT:answerCell.textView.text];
    NSString *xmlString = [NSString stringWithFormat:@"<?xml version=\"1.0\"?><methodCall><methodName>reply_post</methodName><params><param><value><string>%i</string></value></param><param><value><string>%i</string></value></param><param><value><base64>%@</base64></value></param><param><value><base64>%@</base64></value></param></params></methodCall>", self.topic.forumID, 
                           self.topic.topicID, 
                           encodeString(@"answer"), 
                           encodeString(content)];
    [self sendRequestWithXMLString:xmlString cookies:YES delegate:self];
}

- (void)previous {
    if (site > 0) {
        site--;
        [self loadThread];
        [self displayActivityIndicator];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (void)last {
    site = [self numberOfSites]-1;
    [self loadThread];
    [self displayActivityIndicator];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)next {
    if (site < [self numberOfSites]-1) {
        site++;
        [self loadThread];
        [self displayActivityIndicator];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (void)showActionSheet {
    NSString *loginButtonTitle = nil, *answerButton = nil, *subscribeButton = nil;
    if ([[User sharedUser] isLoggedIn]) {
        loginButtonTitle = NSLocalizedStringFromTable(@"Logout", @"ATLocalizable", @"");
        if (self.topic.userCanPost && !self.topic.closed)
            answerButton = NSLocalizedStringFromTable(@"Answer", @"ATLocalizable", @"");
        if (self.topic.subscribed)
            subscribeButton = NSLocalizedStringFromTable(@"Unsubscribe", @"ATLocalizable", @"");
        else
            subscribeButton = NSLocalizedStringFromTable(@"Subscribe", @"ATLocalizable", @"");
    } else {
        loginButtonTitle = NSLocalizedStringFromTable(@"Login", @"ATLocalizable", @"");
    }
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"Cancel", @"ATLocalizable", @"") destructiveButtonTitle:nil otherButtonTitles:loginButtonTitle, NSLocalizedStringFromTable(@"Last", @"ATLocalizable", @""), subscribeButton, answerButton, nil];
    if (self.navigationController.tabBarController.tabBar) {
        [actionSheet showFromTabBar:self.navigationController.tabBarController.tabBar];
    } else {
        [actionSheet showInView:self.view];
    }
}

#pragma mark -
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    AnswerViewController *answerViewController;
    NSString *xmlString;
    
    if ([[User sharedUser] isLoggedIn]) {
        switch (buttonIndex) {
            case 0:
                [self logout];
                break;
            case 1:
                [self last];
                break;
            case 2:
                xmlString = [NSString stringWithFormat:@"<?xml version=\"1.0\"?><methodCall><methodName>subscribe_topic</methodName><params><param><value><string>%i</string></value></param></params></methodCall>", self.topic.topicID];
                if (self.topic.subscribed) {
                    xmlString = [xmlString stringByReplacingOccurrencesOfString:@"subscribe_topic" withString:@"unsubscribe_topic"];
                }
                isSubscribing = YES;
                [self displayActivityIndicator];
                [self sendRequestWithXMLString:xmlString cookies:YES delegate:self];
                break;
            case 3:
                if (self.topic.userCanPost && !self.topic.closed) {
                    answerViewController = [[AnswerViewController alloc] initWithNibName:@"AnswerViewController" bundle:nil topic:self.topic];
                    [self.navigationController pushViewController:answerViewController animated:YES];
                }
                break;
            default:
                break;
        }
    } else {
        switch (buttonIndex) {
            case 0:
                [self login];
                break;
            case 1:
                [self last];
                break;
            default:
                break;
        }
    }
}

#pragma mark -
#pragma mark UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 2) {
        [self login];
        return;
    } else {
        [super alertView:alertView didDismissWithButtonIndex:buttonIndex];
    }
}

#pragma mark -
#pragma mark XMLRPCResponseDelegate

- (void)parserDidFinishWithObject:(NSObject *)dictionaryOrArray ofType:(XMLRPCResultType)type {
    if (type == XMLRPCResultTypeDictionary) {
        NSDictionary *dictionary = (NSDictionary *)dictionaryOrArray;
        if (isSubscribing) {
            [self dismissActivityIndicator];
            isSubscribing = NO;
            BOOL result = [[dictionary valueForKey:@"result"] boolValue];
            if (result) {
                if (self.topic.subscribed)
                    self.topic.subscribed = !result;
                else
                    self.topic.subscribed = result;
            } else {
                NSLog(@"Error: %@", [dictionary valueForKey:@"result_text"]);
                UIAlertView *alertView;
                if (self.topic.subscribed)
                   alertView = [[UIAlertView alloc] initWithTitle:ATLocalizedString(@"Error", nil) message:ATLocalizedString(@"There was an error when unsubscribing the topic.", nil) delegate:nil cancelButtonTitle:ATLocalizedString(@"OK", nil) otherButtonTitles:nil, nil]; 
                else
                   alertView = [[UIAlertView alloc] initWithTitle:ATLocalizedString(@"Error", nil) message:ATLocalizedString(@"There was an error when subscribing to the topic.", nil) delegate:nil cancelButtonTitle:ATLocalizedString(@"OK", nil) otherButtonTitles:nil, nil]; 
                [alertView show];
            }
            result = NO;
            return;
        } else if (isAnswering) {
            [self dismissActivityIndicator];
            isAnswering = NO;
            if ([[dictionary valueForKey:@"result"] boolValue]) {
                answerCell.textView.text = @"";
                [self loadThread];
            } else {
                NSLog(@"Error: %@", [dictionary valueForKey:@"result_text"]);
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:ATLocalizedString(@"Error", nil) message:ATLocalizedString(@"There was an error when replying to the topic.", nil) delegate:nil cancelButtonTitle:ATLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
                [alertView show];
            }
            return;
        }
        self.posts = [NSMutableArray array];
        NSArray *array = [dictionary valueForKey:@"posts"];
        self.topic.closed = [[dictionary valueForKey:@"is_closed"] boolValue];
        self.topic.subscribed = [[dictionary valueForKey:@"is_subscribed"] boolValue];
        self.topic.userCanPost = [[dictionary valueForKey:@"can_reply"] boolValue];
        for (NSDictionary *dict in array) {
            Post *post = [[Post alloc] initWithDictionary:dict];
            [self.posts addObject:post];
        }
        [self dismissActivityIndicator];
        [self.tableView reloadData];
    } else {
        
    }
}

#pragma mark -
#pragma mark ContentCellDelegate & SubjectCellDelegate

- (BOOL)contentCell:(ContentCell *)cell shouldLoadRequest:(NSURLRequest *)aRequest {
    // This methode will open a GalleryView or a webView! 
    NSString *extension = [[[aRequest URL] absoluteString] pathExtension];
    
    BOOL isImage = NO;
    NSArray *extensions = [NSArray arrayWithObjects:@"tiff", @"tif", @"jpg", @"jpeg", @"gif", @"png",@"bmp", @"BMPf", @"ico", @"cur", @"xbm", nil];
    
    for (NSString *e in extensions) {
        if ([extension isEqualToString:e]) {
            isImage = YES;
        }
    }
    
    if (isImage) {
        GCImageViewer *imageViewer = [[GCImageViewer alloc] initWithURL:[aRequest URL]];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [self presentModalViewController:imageViewer animated:YES];
        } else {
            [self.navigationController pushViewController:imageViewer animated:YES];
        }   
        return NO;
    }
    
    ATWebViewController *webViewController = [[ATWebViewController alloc] initWithNibName:@"ATWebViewController" bundle:nil URL:[aRequest URL]];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self presentModalViewController:webViewController animated:YES];
    } else {
        [self.navigationController pushViewController:webViewController animated:YES];
    }
    
    return NO;
}

- (void)contentCellDidBeginEditing:(ContentCell *)cell {
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:[self.tableView numberOfSections]-1] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    activeView = cell.textView;
    if (self.navigationItem.hidesBackButton) {
        return;
    }
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(endEditing:)];
    [self.navigationItem setLeftBarButtonItem:leftButton animated:YES];
}

- (void)contentCell:(ContentCell *)cell shouldQuoteText:(NSString *)quoteText ofObjectAtIndexPath:(NSIndexPath *)indexPath {
    AnswerViewController *answerViewController = [[AnswerViewController alloc] initWithNibName:@"AnswerViewController" bundle:nil topic:self.topic];
    [self.navigationController pushViewController:answerViewController animated:YES];
    Post *post = [self.posts objectAtIndex:indexPath.section];
    answerViewController.textView.text = [NSString stringWithFormat:@"[QUOTE=%@;%ld]%@[/QUOTE]", post.author, (long)post.postID, quoteText];
}

- (void)contentCellDidEndEditing:(ContentCell *)cell {
    [self endEditing:nil];
}

#pragma mark -
#pragma mark UISwipeGestureRecognizer

- (void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer {
    if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        [self next];
    }
    else if (recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        if (site >0 ) {
            [self previous];
        }
    }
}

#pragma mark -
#pragma mark UILongPressGestureRecognizer

- (void)showMenu:(UILongPressGestureRecognizer *)sender {
    if ([sender state] == UIGestureRecognizerStateBegan) {
        UITableViewCell *view = (UITableViewCell *)sender.view;
        CGPoint location = [sender locationInView:view];
        CGPoint locationInTextLabel = [view.textLabel convertPoint:location fromView:view];
        if (CGRectContainsPoint(view.textLabel.frame, locationInTextLabel)) {
            self.username = view.textLabel.text;
            UIMenuController *menuController = [UIMenuController sharedMenuController];
            UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:ATLocalizedString(@"Send Message", nil) action:@selector(sendMessage:)];
            [self becomeFirstResponder];
            [menuController setArrowDirection:UIMenuControllerArrowUp];
            [menuController setMenuItems:[NSArray arrayWithObject:menuItem]];
            CGRect rect = view.detailTextLabel.frame;
            [menuController setTargetRect:CGRectMake(rect.size.width/2, rect.size.height, 0.0f, 0.0f) inView:view.textLabel];
            [menuController setMenuVisible:YES animated:YES];
        }
    }
}

- (void)sendMessage:(id)sender {
    if (![[User sharedUser] isLoggedIn]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:ATLocalizedString(@"Error", nil) message:ATLocalizedString(@"Please login...", nil) delegate:self cancelButtonTitle:ATLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
        alertView.tag = 2;
        [alertView show];
    } else {
        [self dismissModalViewControllerAnimated:NO];
        UITabBarController *tabBarController = [Apfeltalk_MagazinAppDelegate sharedAppDelegate].tabBarController;
        PrivateMessagesViewController *privateMessagesViewController = (PrivateMessagesViewController *)[[(UINavigationController *)[tabBarController.viewControllers objectAtIndex:2] viewControllers] objectAtIndex:0];
        [privateMessagesViewController writeMessageWithRecipients:[NSArray arrayWithObject:username]];
        [tabBarController setSelectedIndex:4];
    }
}

#pragma mark -

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return (action == @selector(sendMessage:));
}

#pragma mark - View lifecycle

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = topic.title;    
    UISwipeGestureRecognizer *leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    
    [self.tableView addGestureRecognizer:leftSwipeGestureRecognizer];
    
    UISwipeGestureRecognizer *rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    
    [self.tableView addGestureRecognizer:rightSwipeGestureRecognizer];
    
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self loadThread];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0: {
            if (self.posts.count != 0) {
                if (indexPath.section == self.posts.count) 
                    return 100.0;
                return 30;
            }
            return kDefaultRowHeight;
            break;
        } case 1: {
            if (indexPath.section == self.posts.count)
                return kDefaultRowHeight;
            NSString *content = [(Post *)[self.posts objectAtIndex:indexPath.section] content];
            CGFloat margin = [self groupedCellMarginWithTableWidth:CGRectGetWidth(self.tableView.frame)];
            CGFloat width = CGRectGetWidth(self.tableView.frame) - 2.0 * margin - 16.0;
            CGSize maxSize = CGSizeMake(width, CGFLOAT_MAX);
            CGFloat fontSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"fontSize"];
            CGSize size = [content sizeWithFont:[UIFont fontWithName:@"Helvetica" size:fontSize] constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
            CGFloat height = size.height + 16.0;
            
            return height;
            break;
        } default: {
            break;
        }
    }
    
    /*if ([self.posts count] == 0) {
        return kDefaultRowHeight;
    }
    
    if (indexPath.section == [self.posts count] +1) return kDefaultRowHeight;
    if ([self.posts count] != 0 && indexPath.row == 0) {
        if (indexPath.section == [self.posts count]) return 100.0;
        return 30.0;
    } else if (indexPath.row == 1) {
        if (indexPath.section == [self.posts count]) return kDefaultRowHeight;
        NSString *content = [(Post *)[self.posts objectAtIndex:indexPath.section] content];
        
        ContentCell *contentCell = [[ContentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        contentCell.frame = CGRectMake(0, 0, self.tableView.size.width, 10);
        contentCell.textView.text = content;
        CGFloat contentCellHeight = contentCell.textView.contentSize.height;
        [contentCell release];
        
        CGFloat margin = [self groupedCellMarginWithTableWidth:CGRectGetWidth(self.tableView.frame)];
        CGFloat width = CGRectGetWidth(self.tableView.frame) - 2.0 * margin - 16.0;
        CGSize maxSize = CGSizeMake(width, CGFLOAT_MAX);
        CGFloat fontSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"fontSize"];
        CGSize size = [content sizeWithFont:[UIFont fontWithName:@"Helvetica" size:fontSize] constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
        CGFloat height = size.height + 16.0;
        
        return height;
    }
    */
    return kDefaultRowHeight;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == [self.posts count]) {
        if ([self.posts count] != 0) 
            return NSLocalizedStringFromTable(@"Direct response", @"ATLocalizable", @"");
        return nil;
    } else if (section == [self.posts count] +1) return nil;
    return [(Post *)[self.posts objectAtIndex:section] title];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self.posts count] == 0) {
        return 1;
    } else if (!self.topic.userCanPost || self.topic.closed) {
        return [self.posts count];
    }
    return [self.posts count]+1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self.posts count] == 0) {
        return [super tableView:tableView numberOfRowsInSection:section];
    }
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == [tableView numberOfSections]-1) {
        NSString *s = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Site %i of %i", @"ATLocalizable", @""), site+1, [self numberOfSites]];
        if (self.topic.closed) {
            return [NSString stringWithFormat:@"%@\n%@", s, NSLocalizedStringFromTable(@"Topic is closed", @"ATLocalizable", @"")];
        }
        return s;
    }
    return nil;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *AuthorCellIdentifier = @"AuthorCell";
    static NSString *ContentCellIdentifier = @"ContentCell";
    static NSString *ActionsCellIdentifier = @"ActionsCell";
    static NSString *AnswerCellIdentifier = @"AnswerCell";
    Post *p;
    
    if ([self.posts count] != 0 && indexPath.section < [self.posts count]) {
        p = (Post *)[self.posts objectAtIndex:indexPath.section];
    }
    /*
	if (indexPath.row == 0) {
		if (indexPath.section == [self.posts count] && [self.posts count] == 0) { // For the loading cell
			return [super tableView:tableView cellForRowAtIndexPath:indexPath];
		}
        
        if (indexPath.section == [self.posts count] && [self.posts count] != 0) {
            if (answerCell == nil) {
                self.answerCell = [[ContentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AnswerCellIdentifier  tableViewWidth:CGRectGetWidth(self.tableView.frame)]; 
            }
            answerCell.textView.scrollEnabled = YES;
            answerCell.textView.editable = YES;
            answerCell.delegate = self;
            return answerCell;
        }
		
		UITableViewCell *authorCell = [tableView dequeueReusableCellWithIdentifier:AuthorCellIdentifier];
		if (authorCell == nil) {
			authorCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:AuthorCellIdentifier] autorelease];
            UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showMenu:)];
            [authorCell addGestureRecognizer:longPressGestureRecognizer];
            [longPressGestureRecognizer release];
		}
        
        NSDateFormatter *outFormatter = [[NSDateFormatter alloc] init];
        [outFormatter setDateFormat:@"dd.MM.yyyy HH:mm"];
        authorCell.textLabel.text = p.author;
        authorCell.detailTextLabel.textColor = authorCell.textLabel.textColor;
        authorCell.detailTextLabel.text = [outFormatter stringFromDate:p.postDate];
        authorCell.detailTextLabel.font = [UIFont systemFontOfSize:14.0];
        authorCell.selectionStyle = UITableViewCellSelectionStyleNone;
        if (p.userIsOnline) {
            authorCell.imageView.image = [UIImage imageNamed:@"online.png"];
        } else {
            authorCell.imageView.image = [UIImage imageNamed:@"offline.png"];
        }
        [outFormatter release];
		return authorCell;
	} else if (indexPath.row == 1) {
        if (indexPath.section == [self.posts count] && [self.posts count] != 0) {
            UITableViewCell *actionsCell = [tableView dequeueReusableCellWithIdentifier:ActionsCellIdentifier];
            if (actionsCell == nil) {
                actionsCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ActionsCellIdentifier] autorelease];
            }
            actionsCell.textLabel.text = NSLocalizedStringFromTable(@"Answer", @"ATLocalizable", @"");
            actionsCell.textLabel.textAlignment = UITextAlignmentCenter;
            actionsCell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            return actionsCell;
        }
        
		ContentCell *contentCell = (ContentCell *)[tableView dequeueReusableCellWithIdentifier:ContentCellIdentifier];
		if (contentCell == nil) {
			contentCell = [[[ContentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ContentCellIdentifier  tableViewWidth:CGRectGetWidth(self.tableView.frame)] autorelease];
		}
        contentCell.textView.text = p.content;
        contentCell.textView.scrollEnabled = NO;
        
        contentCell.delegate = self;
		return contentCell;
	}*/ 
    
    switch (indexPath.row) {
        case 0: {
            if (indexPath.section == self.posts.count) {
                if (self.posts.count == 0)
                    return [super tableView:tableView cellForRowAtIndexPath:indexPath]; // loadingCell
                
                if (answerCell == nil) {
                    self.answerCell = [[ContentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AnswerCellIdentifier  tableViewWidth:CGRectGetWidth(self.tableView.frame)]; 
                }
                answerCell.textView.scrollEnabled = YES;
                answerCell.textView.editable = YES;
                answerCell.delegate = self;
                return answerCell;
            }
            
            UITableViewCell *authorCell = [tableView dequeueReusableCellWithIdentifier:AuthorCellIdentifier];
            if (authorCell == nil) {
                authorCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:AuthorCellIdentifier];
                UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showMenu:)];
                [authorCell addGestureRecognizer:longPressGestureRecognizer];
            }
            
            NSDateFormatter *outFormatter = [[NSDateFormatter alloc] init];
            [outFormatter setDateFormat:@"dd.MM.yyyy HH:mm"];
            authorCell.textLabel.text = p.author;
            authorCell.detailTextLabel.textColor = authorCell.textLabel.textColor;
            authorCell.detailTextLabel.text = [outFormatter stringFromDate:p.postDate];
            authorCell.detailTextLabel.font = [UIFont systemFontOfSize:14.0];
            authorCell.selectionStyle = UITableViewCellSelectionStyleNone;
            if (p.userIsOnline) {
                authorCell.imageView.image = [UIImage imageNamed:@"online.png"];
            } else {
                authorCell.imageView.image = [UIImage imageNamed:@"offline.png"];
            }
            return authorCell;
            
            break;
        } case 1: {
            if (indexPath.section == self.posts.count) {
                UITableViewCell *actionsCell = [tableView dequeueReusableCellWithIdentifier:ActionsCellIdentifier];
                if (actionsCell == nil) {
                    actionsCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ActionsCellIdentifier];
                }
                actionsCell.textLabel.text = NSLocalizedStringFromTable(@"Answer", @"ATLocalizable", @"");
                actionsCell.textLabel.textAlignment = UITextAlignmentCenter;
                actionsCell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
                return actionsCell;
            }
            
            ContentCell *contentCell = (ContentCell *)[tableView dequeueReusableCellWithIdentifier:ContentCellIdentifier];
            if (contentCell == nil) {
                contentCell = [[ContentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ContentCellIdentifier  tableViewWidth:CGRectGetWidth(self.tableView.frame)];
                contentCell.textView.scrollEnabled = NO;
                contentCell.delegate = self;
            }
            contentCell.textView.text = p.content;
            return contentCell;
            break;
        } default:{
            break;
        }
    }

	return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == [self.posts count] && [self.posts count] != 0) {
        if (indexPath.row == 0) {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
        if (indexPath.row == 1) {
            [self reply];
        }
    }
    
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    [self endEditing:nil];
    AnswerViewController *answerViewController = [[AnswerViewController alloc] initWithNibName:@"AnswerViewController" bundle:nil topic:self.topic];
    [self.navigationController pushViewController:answerViewController animated:YES];
    answerViewController.textView.text = answerCell.textView.text;
    answerCell.textView.text = @"";
}

@end