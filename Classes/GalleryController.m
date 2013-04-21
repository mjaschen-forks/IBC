//
//  RootViewController.m
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

#import "GalleryController.h"
#import "DetailGallery.h"
#import "AsyncImageView.h"
#import "Story.h"
#import "ATMXMLUtilities.h"

@implementation GalleryController

- (NSDictionary *) desiredKeys {
	NSMutableDictionary *elementKeys = [NSMutableDictionary dictionaryWithDictionary:[super desiredKeys]];
	[elementKeys removeObjectForKey:@"content:encoded"];
	[elementKeys setObject:@"summary" forKey:@"description"];
	
	return elementKeys;
}

- (void)parseXMLFileAtURL:(NSString *)URL
{
    [super parseXMLFileAtURL:URL];
	
	// This needs to be done in post-processing, as libxml2 interferes with NSXMLParser
	/*NSMutableArray *thumbnailStories = [[NSMutableArray alloc] initWithCapacity:[stories count]];
	for (Story *s in stories) {
		NSString *thumbnailLink = extractTextFromHTMLForQuery([s summary], @"//img[attribute::alt]/attribute::src");
		if ([thumbnailLink length] > 0) {
			[s setThumbnailLink:thumbnailLink];
			[thumbnailStories addObject:s];
		}
	}	
	[stories release];
	stories = thumbnailStories;*/
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [super connectionDidFinishLoading:connection];

	// This needs to be done in post-processing, as libxml2 interferes with NSXMLParser
	NSMutableArray *thumbnailStories = [[NSMutableArray alloc] initWithCapacity:[stories count]];
	for (Story *s in stories) {
		NSString *thumbnailLink = extractTextFromHTMLForQuery([s summary], @"//img[attribute::alt]/attribute::src");
		if ([thumbnailLink length] > 0) {
			[s setThumbnailLink:thumbnailLink];
			[thumbnailStories addObject:s];
		}
	}

	stories = thumbnailStories;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *CellIdentifier = @"ImageCell";
    
    if ([stories count] == 0) 
		return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    } else {
		AsyncImageView* oldImage = (AsyncImageView*) [cell.contentView viewWithTag:999];
		[oldImage removeFromSuperview];
	}

	CGRect previewImageFrame;
	previewImageFrame.size.width=44.f; 
	previewImageFrame.size.height=44.f;
	previewImageFrame.origin.x=6;
	previewImageFrame.origin.y=0;
	
	AsyncImageView* asyncImage = [[AsyncImageView alloc] initWithFrame:previewImageFrame];
	asyncImage.tag = 999;
	Story *story = [stories objectAtIndex:indexPath.row];
	NSString *urlString = [story thumbnailLink];
	if ([urlString length] > 0) {
		NSURL *url = [NSURL URLWithString:urlString];
		[asyncImage loadImageFromURL:url];
		
		[cell.contentView addSubview:asyncImage];    		
	}
	else
		NSLog (@"%@ has no thumbnail", [story title]);
	
	// We leave it like this for the moment, because the gallery has no read indicators
	int storyIndex = [indexPath indexAtPosition: [indexPath length] - 1];
	
	// No special customization
	cell.indentationLevel = 5; // intend, so the image does not get cut off
	cell.textLabel.text = [[stories objectAtIndex: storyIndex] title];    // TODO show author name in cell text
	cell.textLabel.font = [UIFont boldSystemFontOfSize:12];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([stories count] == 0) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    Story *story = [stories objectAtIndex: indexPath.row];
    DetailGallery *detailController;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        detailController = [[DetailGallery alloc] initWithNibName:@"DetailView" bundle:[NSBundle mainBundle] 
                                                            story:story];
        [self.navigationController pushViewController:detailController animated:YES];
    } else {
        detailController = [self.splitViewController.viewControllers lastObject];
        [detailController setStory:story];
        [detailController updateInterface];
        
        if (popoverController != nil) {
            [popoverController dismissPopoverAnimated:YES];
        }
        
        /*if (rootPopoverButtonItem != nil) {
            [detailController showRootPopoverButtonItem:self.rootPopoverButtonItem];
        }*/
    }
}

- (NSString *) documentPath {
	return @"http://www.feedage.com/html2rss/html2rss.php?id=7174437";
}

/*- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {return YES;
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}*/

#pragma mark -
#pragma mark UISplitViewControllerDelegate 

- (void)splitViewController:(UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController:(UIPopoverController*)pc {
    
    // Keep references to the popover controller and the popover button, and tell the detail view controller to show the button.
    barButtonItem.title = @"Fotos";
    self.popoverController = pc;
    self.rootPopoverButtonItem = barButtonItem;
    UIViewController <SubstitutableDetailViewController> *detailViewController = [self.splitViewController.viewControllers objectAtIndex:1];
    [detailViewController showRootPopoverButtonItem:barButtonItem];
}

@end
