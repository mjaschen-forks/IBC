//
//  LivetickerController.h
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
#import "ATXMLParser.h"

@class DetailLiveticker;

@interface LivetickerController : UITableViewController <ATXMLParserDelegateProtocol>
{
    NSMutableData *xmlData;
    NSArray         *stories;
    NSDateFormatter *shortTimeFormatter;
    NSUInteger       displayedStoryIndex;
    IBOutlet UITableViewCell *loadingCell;
    UIPopoverController *popoverController;    
    UIBarButtonItem *rootPopoverButtonItem;
    BOOL didFirstLoad;
}

@property(strong) NSMutableData *xmlData;
@property(strong) NSArray *stories;
@property(strong) NSDateFormatter *shortTimeFormatter;
@property(assign) NSUInteger displayedStoryIndex;
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong) UIBarButtonItem *rootPopoverButtonItem;

- (void)reloadTickerEntries:(NSTimer *)timer;
- (void)changeStory:(id)sender;

@end
