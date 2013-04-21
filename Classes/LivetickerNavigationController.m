//
//  LivetickerNavigationController.m
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

#import "LivetickerNavigationController.h"
#import "LivetickerController.h"


#define RELOAD_TIME 30


@implementation LivetickerNavigationController

@synthesize reloadTimer;


- (void)setReloadTimer:(NSTimer *)timer
{
    if (timer != reloadTimer)
    {
        [reloadTimer invalidate];
        reloadTimer = timer;
    }
    
}



- (void)dealloc
{
    if (reloadTimer)
    {
        [reloadTimer invalidate];
    }

}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (UI_USER_INTERFACE_IDIOM() ==UIUserInterfaceIdiomPhone) {
        LivetickerController *rootViewController = (LivetickerController *)[[self viewControllers] objectAtIndex:0];

        [self setReloadTimer:[NSTimer scheduledTimerWithTimeInterval:RELOAD_TIME target:rootViewController selector:@selector(reloadTickerEntries:) userInfo:nil
                                                         repeats:YES]];
        [rootViewController reloadTickerEntries:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self setReloadTimer:nil];
    }
}

@end
