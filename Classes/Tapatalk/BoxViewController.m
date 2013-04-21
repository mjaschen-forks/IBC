//
//  BoxViewController.m
//  IBC
//
//  Created by Manuel Burghard on 25.08.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BoxViewController.h"
#import "ATMessage.h"
#import "User.h"
#import "DetailMessageViewController.h"
#import "PrivateMessagesViewController.h"

@implementation BoxViewController
@synthesize box, messages, isDeletingMessage;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil box:(Box *)aBox {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.box = aBox;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
    self.isDeletingMessage = NO;
}

#pragma mark -
#pragma mark Private Methods

- (void)writeMessage {
    TTMessageController *messageController = [[TTMessageController alloc] initWithRecipients:nil];
    messageController.delegate = self;
    ATContactDataSource *dataSource = [[ATContactDataSource alloc] init];
    dataSource.messageController = messageController;
    messageController.dataSource = dataSource;
    messageController.showsRecipientPicker = NO;
    messageController.navigationBarTintColor = ATNavigationBarTintColor;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:messageController];
    navigationController.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
    [self presentModalViewController:navigationController animated:YES];
}

- (void)loadMessages {
    NSString *xmlString = [NSString stringWithFormat:@"<?xml version=\"1.0\"?><methodCall><methodName>get_box</methodName><params><param><value><string>%ld</string></value></param></params></methodCall>", (long)self.box.boxID ];
    [self sendRequestWithXMLString:xmlString cookies:YES delegate:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSString *result = [[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding];
    NSString *expectedResult = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<methodResponse>\n<params>\n<param>\n<value><boolean>1</boolean></value>\n</param>\n</params>\n</methodResponse>";
    if (self.isDeletingMessage) {
        self.isDeletingMessage = NO;
        if ([result isEqualToString:expectedResult]) {
            [[SHKActivityIndicator currentIndicator] displayCompleted:@""];
        } else {
            [[SHKActivityIndicator currentIndicator] setCenterMessage:ATLocalizedString(@"Error", nil)];
            [[SHKActivityIndicator currentIndicator] hideAfterDelay];
        }
    } else if (self.isSending) {
        self.isSending = NO;
        if ([result isEqualToString:expectedResult]) {
            [self.modalViewController dismissModalViewControllerAnimated:YES];
            
        } else {
            [[SHKActivityIndicator currentIndicator] setCenterMessage:ATLocalizedString(@"Error", nil)];
            [[SHKActivityIndicator currentIndicator] show];
            [[SHKActivityIndicator currentIndicator] hideAfterDelay];
        }
    }
    
    [super connectionDidFinishLoading:connection];
}

/*
#pragma mark -
#pragma mark TTMessageControllerDelegate

- (void)composeControllerWillCancel:(TTMessageController *)controller {
    [controller dismissModalViewControllerAnimated:YES];
}

- (void)composeControllerShowRecipientPicker:(TTMessageController *)controller {
    ATContactDataSource *dataSource = (ATContactDataSource *)[controller dataSource];
    ATContactModel *model = [dataSource contactModel];
    NSMutableArray *onlineUsers =  model.onlineUsers;
    NSArray *titles = [NSArray arrayWithObjects:ATLocalizedString(@"Online Users", nil), nil];
    NSArray *groups = [NSArray arrayWithObjects:onlineUsers, nil];
    ATContactPicker *contactPicker = [[ATContactPicker alloc] initWithStyle:UITableViewStylePlain groups:groups titles:titles];
    contactPicker.delegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:contactPicker];
    navigationController.navigationBar.tintColor = ATNavigationBarTintColor;
    [contactPicker tableView:contactPicker.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [controller presentModalViewController:navigationController animated:YES];
    [navigationController release];
    [contactPicker release];
}

- (void)composeController:(TTMessageController *)controller didSendFields:(NSArray *)fields {
    NSMutableString *recipients = [NSMutableString string];
    for (NSObject *item in [(TTMessageRecipientField *)[fields objectAtIndex:0] recipients]) {
        if ([item isKindOfClass:[TTTableTextItem class]]) {
            [recipients appendString:[NSString stringWithFormat:@"<value><base64>%@</base64></value>", encodeString([(TTTableTextItem *)item text])]];
        } else if ([item isKindOfClass:[NSString class]]) {
            [recipients appendString:[NSString stringWithFormat:@"<value><base64>%@</base64></value>", encodeString((NSString *)item)]];
        }
    }
    ContentTranslator *translator = [ContentTranslator contentTranslator];
    NSString *subject = [(TTMessageTextField *)[fields objectAtIndex:1] text];
    NSString *message = [(TTMessageTextField *)[fields lastObject] text];
    subject = [translator translateStringForAT:subject];
    message = [translator translateStringForAT:message];
    
    NSString *xmlString = [NSString stringWithFormat:@"<?xml version=\"1.0\"?><methodCall><methodName>create_message</methodName><params><param><value><array><data>%@</data></array></value></param><param><value><base64>%@</base64></value></param><param><value><base64>%@</base64></value></param></params></methodCall>", recipients, encodeString(subject), encodeString(message)];
    self.isSending = YES;
    [self sendRequestWithXMLString:xmlString cookies:YES delegate:self];
}

#pragma mark -
#pragma mark ATContactPickerDelegate

- (void)contactPicker:(ATContactPicker *)contactPicker didSelectContact:(NSString *)contactName {
    TTMessageController *messageController = (TTMessageController *)[[(UINavigationController *)self.modalViewController viewControllers] objectAtIndex:0];
    [messageController addRecipient:contactName forFieldAtIndex:0];
    [messageController dismissModalViewControllerAnimated:YES];
}*/

#pragma mark -
#pragma mark XMLRPCResponsParserDelegate

- (void)parserDidFinishWithObject:(NSObject *)dictionaryOrArray ofType:(XMLRPCResultType)type {
    if (type == XMLRPCResultTypeDictionary) {
        NSDictionary *dictionary = (NSDictionary *)dictionaryOrArray;
        if (self.isSending) {
            self.isSending = NO;
            [self.modalViewController dismissModalViewControllerAnimated:YES];
            if (![[dictionary valueForKey:@"result"] boolValue]) {
                [self showAlertViewWithErrorString:[dictionary valueForKey:@"result_text"]];
            } 
            return;
        } else if (self.isDeletingMessage) {
            self.isDeletingMessage = NO;
            if ([[dictionary valueForKey:@"result"] boolValue]) {
                [[SHKActivityIndicator currentIndicator] displayCompleted:@""];
            } else {
                [[SHKActivityIndicator currentIndicator] hide];
                [self showAlertViewWithErrorString:[dictionary valueForKey:@"result_text"]];
            }
            return;
        }
        NSArray *array = [dictionary valueForKey:@"list"];
        self.messages = [NSMutableArray array];
        for (NSDictionary *dict in array) {
            ATMessage *message = [[ATMessage alloc] initWithDictionary:dict];
            message.boxID = self.box.boxID;
            [self.messages addObject:message];
        }
        [self.tableView reloadData];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = self.box.title;
    UIBarButtonItem *writeMessageButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(writeMessage)];
    self.navigationItem.rightBarButtonItem = writeMessageButton;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self loadMessages];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    }
    
    return (toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    // Return the number of rows in the section.
    return [self.messages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    ATMessage *message = [self.messages objectAtIndex:indexPath.row];
    
    cell.textLabel.text = message.subject;
    cell.detailTextLabel.text = message.sender;
    if (self.box.boxType == BoxTypeSentBox) {
        NSMutableString *recipients = [NSMutableString stringWithString:[message.recipients objectAtIndex:0]];
        for (NSInteger i = 1; i < message.recipients.count; i++) {
            [recipients appendFormat:@", %@", [message.recipients objectAtIndex:i]];
        }
        cell.detailTextLabel.text  = recipients;
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return !self.isDeletingMessage;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        ATMessage *message = [self.messages objectAtIndex:indexPath.row];
        NSString *xmlString = [NSString stringWithFormat:@"<?xml version=\"1.0\"?><methodCall><methodName>delete_message</methodName><params><param><value><string>%ld</string></value></param><param><value><string>%ld</string></value></param></params></methodCall>", (long)message.messageID, (long)self.box.boxID];
        
        self.isDeletingMessage = YES;
        [[SHKActivityIndicator currentIndicator] displayActivity:ATLocalizedString(@"Deleting message", nil)];
        [self sendRequestWithXMLString:xmlString cookies:YES delegate:self];
        [self.messages removeObject:message];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    
    DetailMessageViewController *detailMessageViewController = [[DetailMessageViewController alloc] initWithStyle:UITableViewStyleGrouped];
    detailMessageViewController.message = [self.messages objectAtIndex:indexPath.row];
    if (detailMessageViewController.message.state == ATMessageStateUnread) {
        self.box.numberOfUnreadMessages--;
        [(PrivateMessagesViewController *)[self.navigationController.viewControllers objectAtIndex:0] updateTabBarItemBadge];
    }
    [self.navigationController pushViewController:detailMessageViewController animated:YES];
     
}

@end
