//
//  DetailViewController.m
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

#import "DetailGallery.h"
#import "Fullscreen.h"
#import "RootViewController.h"
#import "Apfeltalk_MagazinAppDelegate.h"
#import "GCImageViewer.h"
#import "ATMXMLUtilities.h"

#import <libxml/HTMLparser.h>

#define MAX_IMAGE_WIDTH ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 728 :280)

@interface DetailGallery (private)
- (void)createMailComposer:(NSString*)str;
@end

@implementation DetailGallery

- (void)showFullscreen {
    NSString *str = [[self story] summary];
    
    NSString *thumbLink = extractTextFromHTMLForQuery(str, @"//img[attribute::title]/attribute::src");
    
    if ([thumbLink length] == NSNotFound) {
		UIAlertView * errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Keine URL", @"")
                                                              message:NSLocalizedString (@"Es konnte keine URL für das Bild gefunden werden", @"")
                                                             delegate:nil cancelButtonTitle:NSLocalizedString (@"OK", @"")
                                                    otherButtonTitles:nil];
		[errorAlert show];
        return;
    }
    
    NSString *imageLink = [thumbLink stringByReplacingOccurrencesOfString:@"/thumbs" withString:@""];
    
    GCImageViewer *galleryImageViewController = [[GCImageViewer alloc] initWithURL:[NSURL URLWithString:imageLink]];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController pushViewController:galleryImageViewController animated:YES];
    } else {
        [self presentModalViewController:galleryImageViewController animated:YES];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
    
    NSString *str = [[self story] summary];
    NSString *thumbLink = extractTextFromHTMLForQuery(str, @"//img/attribute::src");
    
    thumbLink = [thumbLink stringByReplacingOccurrencesOfString:@"/thumbs" withString:@""];
    
    NSURL *loadURL = [request URL]; // retain the loadURL for use
   
    if ([[loadURL absoluteString] isEqualToString:thumbLink]) {
        if (![webView isLoading]) {
            [self showFullscreen];
        }
        return NO;
    }
    return YES;
}

- (NSString *)strip_tags:(NSString *)data :(NSArray *)valid_tags
{
	//use to strip the HTML tags from the data
	NSScanner *scanner;
	NSString *text = nil;
	NSString *tag = nil;
	
	//set up the scanner
	scanner = [NSScanner scannerWithString:data];
	
	while([scanner isAtEnd] == NO) {
		//find start of tag
		[scanner scanUpToString:@"<" intoString:NULL];
		
		//find end of tag
		[scanner scanUpToString:@">" intoString:&text];
		
		//get the name of the tag
		if([text rangeOfString:@"</"].location != NSNotFound)
			tag = [text substringFromIndex:2]; //remove </
		else {
			tag = [text substringFromIndex:1]; //remove <
			//find out if there is a space in the tag
			if([tag rangeOfString:@" "].location != NSNotFound)
				//remove text after a space
				tag = [tag substringToIndex:[tag rangeOfString:@" "].location];
		}
		
		//if not a valid tag, replace the tag with a space
		if([valid_tags containsObject:tag] == NO)
			data = [data stringByReplacingOccurrencesOfString:
					[NSString stringWithFormat:@"%@>", text] withString:@""];
	}
	
	//return the cleaned up data
	return data;
}

- (NSString *) storyTitle {
	if ([[[self story] title] isEqual: @""])
		return NSLocalizedString (@"--Kein Titel--", @"");
	else
		return [[self story] title];
}

#pragma mark libxml SAX Callbacks
void characters(	void * 	user_data,
				const xmlChar * 	ch,
				int  	len) {
	NSMutableString *output = (NSMutableString *)CFBridgingRelease(user_data);
	NSString *charString = (NSString *)CFBridgingRelease(CFStringCreateWithBytes(kCFAllocatorDefault,
															   ch, len, 
															   kCFStringEncodingUTF8, NO));
	[output appendString:charString];
}

void endElement (void *userData, const xmlChar *name) {
	if (strcmp((const char *)name, "br") == 0) {
		NSMutableString *output = (NSMutableString *)CFBridgingRelease(userData);
		[output appendString:@"<br/>"];
	}		
}

- (NSString *) htmlString
{
	cleanedString = [NSMutableString new];
	//elementString = [NSMutableString new];
	xmlSAXHandler saxInfo;
	memset(&saxInfo, 0, sizeof(saxInfo));
	saxInfo.characters = &characters;
	saxInfo.endElement = &endElement;
	
	// :below:20090919 The following will strip extract the pure text and breaks from the HTML
	
	// The big problem is that we don't have really structured input here, so all of this remains pretty brute force
	
	// Input is:
	//	<a href="http://www.apfeltalk.de/gallery/showphoto.php?photo=15992" target="_blank"><img title="Screenshot_2009-09-17_at_16_31_09.png" border="0" src="http://www.apfeltalk.de/gallery/data/500/thumbs/Screenshot_2009-09-17_at_16_31_09.png" alt="Screenshot_2009-09-17_at_16_31_09.png" /></a><br /><br />von: GunBound<br /><br />Beschreibung: Nein, eigentlich ist ja alles klar\u0085<br /><br />6 Kommentare<img width='1' height='1' src='http://rss.feedsportal.com/c/837/f/10954/s/6302265/mf.gif' border='0'/><div class='mf-viral'><table border='0'><tr><td valign='middle'><a href="http://res.feedsportal.com/viral/sendemail2_de.html?title=H\u00f8\u00f8\u00f8\u00f8\u00f8?&link=http://www.apfeltalk.de/gallery/showphoto.php?photo=15992" target="_blank"><img src="http://rss.feedsportal.com/images/emailthis2.gif" border="0" /></a></td><td valign='middle'><a href="http://res.feedsportal.com/viral/bookmark_de.cfm?title=H\u00f8\u00f8\u00f8\u00f8\u00f8?&link=http://www.apfeltalk.de/gallery/showphoto.php?photo=15992" target="_blank"><img src="http://rss.feedsportal.com/images/bookmark.gif" border="0" /></a></td></tr></table></div><br/><br/><a href="http://da.feedsportal.com/r/50216880195/u/82/f/10954/c/837/s/103817829/a2.htm"><img src="http://da.feedsportal.com/r/50216880195/u/82/f/10954/c/837/s/103817829/a2.img" border="0"/></a>
	// Output should be:
	// <br /><br />von: GunBound<br /><br />Beschreibung: Nein, eigentlich ist ja alles klar\u0085<br /><br />6 Kommentare<br/><br/>
	// TODO: Add a unit test for this
	
	// We could try if seperating it by <br/> Tags works...
    
	xmlChar *xmlCharString = (xmlChar*)[[[self story] summary] cStringUsingEncoding:NSUTF8StringEncoding];
	htmlDocPtr	htmlDoc = htmlSAXParseDoc		(xmlCharString, 
												 "utf-8", 
												 &saxInfo, 
												 CFBridgingRetain(cleanedString))	;
		
	free (htmlDoc);
	//[elementString release];
	NSString *str = [[[self story] thumbnailLink] stringByReplacingOccurrencesOfString:@"/thumbs" withString:@""];
    
	NSString *showpicture = [NSString stringWithFormat:@"<a href=\"%@\"><img src=\"%@\" alt=\"No Medium Picture.\" /></a> ", str, str];
	NSString *resultString = [NSString stringWithFormat:@"%@%@", showpicture, cleanedString];
    
	cleanedString = nil;
    
    NSLog(@"%@", self.story.summary);
    NSLog(@"%@", resultString);
    
    NSScanner *scanner = [NSScanner scannerWithString:resultString];
    [scanner scanUpToString:@"<br/><br/>von: " intoString:nil];
    NSUInteger location = [scanner scanLocation];
    [scanner scanString:@"<br/><br/>von: " intoString:nil];
    NSUInteger length = 0;
    [scanner scanUpToString:@"<br/>" intoString:nil];
    if (![scanner isAtEnd])
        length = [scanner scanLocation] - location + 5; // + 5 to remove the next br tag
    else
        length = [resultString length] - location;
    NSRange range = NSMakeRange(location, length);
    NSString *author = nil, *rawAuthorString = [resultString substringWithRange:range];
    author = [rawAuthorString stringByReplacingOccurrencesOfString:@"<br/><br/>von: " withString:@""];
    author = [author stringByReplacingOccurrencesOfString:@"<br/>" withString:@""];
    resultString = [resultString stringByReplacingOccurrencesOfString:rawAuthorString withString:@""];
    
    [self.story setAuthor:author];
    Story           *theStory = self.story;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setDateFormat:[NSString stringWithFormat:@"%@ HH:mm", [dateFormatter dateFormat]]];
    
    float fontSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"fontSize"];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"DetailView" ofType:@"html"];
    NSString *htmlString = [NSString stringWithFormat:[NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL], 
                            fontSize, [self imageWidth], (fontSize + 3.0), theStory.title, (fontSize - 1.0), theStory.author, [dateFormatter stringFromDate:theStory.date], fontSize,
                            resultString];
    return htmlString;
}

- (NSString *) rightBarButtonTitle {
	return NSLocalizedStringFromTable(@"Picture options", @"ATLocalizable", @"");
}

-(IBAction)speichern:(id)sender
{
    [super speichern:sender];
	Apfeltalk_MagazinAppDelegate *appDelegate = (Apfeltalk_MagazinAppDelegate *)[[UIApplication sharedApplication] delegate];

	// :below:20090920 This is only to placate the analyzer
	myMenu = [[UIActionSheet alloc]
              initWithTitle: nil
              delegate:self
              cancelButtonTitle:NSLocalizedStringFromTable(@"Cancel", @"ATLocalizable", @"")
              destructiveButtonTitle:nil
              otherButtonTitles:ATLocalizedString(@"Send as mail", nil), ATLocalizedString(@"Save picture", nil), ATLocalizedString(@"Fullscreen", nil),nil];
    
    [myMenu showFromTabBar:[[appDelegate tabBarController] tabBar]];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIdx
{
	NSString *str = [[self story] summary];
	
    NSString *thumbLink = extractTextFromHTMLForQuery(str, @"//img[attribute::title]/attribute::src");
	
    if ([thumbLink length] == NSNotFound) {
		UIAlertView * errorAlert = [[UIAlertView alloc] initWithTitle:ATLocalizedString(@"No URL", nil)
                                                              message:ATLocalizedString(@"No URL for the picture was found", nil)
                                                             delegate:nil cancelButtonTitle:NSLocalizedString (@"OK", @"")
                                                    otherButtonTitles:nil];
		[errorAlert show];
        return;
    }

    NSString *imageLink = [thumbLink stringByReplacingOccurrencesOfString:@"/thumbs" withString:@""];
    
    switch (buttonIdx) {
        case 2: {
            [self showFullscreen];
            break;
        }
        case 1:
        {
            UIImage *image = [UIImage imageWithData: [NSData dataWithContentsOfURL: [NSURL URLWithString:imageLink]]];
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil); 
            
            UIAlertView * errorAlert = [[UIAlertView alloc] initWithTitle:ATLocalizedString(@"Picture saved", nil) message:ATLocalizedString(@"The picture has been saved to your library successfully", nil) delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"ATLocalizable", @"") otherButtonTitles:nil];
            [errorAlert show];
            
        }
            break;
        case 0:
        {
            imageLink = [thumbLink stringByReplacingOccurrencesOfString:@"/thumbs" withString:@"/medium"];
            
            if (TARGET_IPHONE_SIMULATOR)
                NSLog(@"Keep in mind, that no mail could be send in Simulator mode... just providing the UI");
            [self createMailComposerWithThumbnailLink:imageLink];
        }
    }
    
	// :below:20090920 This is only to placate the analyzer
	if (actionSheet == myMenu) {
		myMenu = nil;
	}
}

- (void)createMailComposerWithThumbnailLink:(NSString*)thumbnailLink {
    
	MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
	controller.mailComposeDelegate = self;
    
    NSString *imageLink = [thumbnailLink stringByReplacingOccurrencesOfString:@"/thumbs" withString:@"/medium"];
    
	// adde image as attachment
	UIImage *image = [UIImage imageWithData: [NSData dataWithContentsOfURL: [NSURL URLWithString:imageLink]]];
    if (image == nil) {
        imageLink = [thumbnailLink stringByReplacingOccurrencesOfString:@"/thumbs" withString:@""];
        image = [UIImage imageWithData: [NSData dataWithContentsOfURL: [NSURL URLWithString:imageLink]]];
    }
    
    if (image == nil) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:ATLocalizedString(@"Couldn't load picture", nil)
                                                            message:ATLocalizedString(@"Photo couldn't be loaded in any resolution", nil)
                                                           delegate:nil cancelButtonTitle:NSLocalizedString (@"OK", @"")
                                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
	NSData *imageData = UIImageJPEGRepresentation(image, 1);
	[controller addAttachmentData:imageData mimeType:@"image/jpg" fileName:@"attachment.jpg"];
    
	[controller setSubject:[story title]];
	[self presentModalViewController:controller animated:YES];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	[self becomeFirstResponder];
	[self dismissModalViewControllerAnimated:YES];
}


@end
