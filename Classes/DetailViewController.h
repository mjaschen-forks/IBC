//
//  DetailViewController.h
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

#import <UIKit/UIKit.h>
#import "Story.h"
#import "AsyncImageButton.h"
#import <MediaPlayer/MediaPlayer.h>
#import "RootViewController.h"
#import "ATActivityIndicatorView.h"

@interface DetailViewController : UIViewController <UIWebViewDelegate, SubstitutableDetailViewController> {
    ATActivityIndicatorView *activityIndicator;
	IBOutlet UIWebView *webview;
    IBOutlet UIToolbar *toolbar;
    
	Story *story;
	UIActionSheet *myMenu;
}

@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (readwrite, strong) Story *story;
@property (nonatomic, strong) IBOutlet ATActivityIndicatorView *activityIndicator;

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle story:(Story *)newStory;
- (NSUInteger)imageWidth;
- (NSString *)rightBarButtonTitle;
- (void)updateInterface;
- (IBAction)speichern:(id)sender;

@end
