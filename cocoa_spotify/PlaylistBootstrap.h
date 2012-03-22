//
//  PlaylistBootstrap.h
//  cocoa_spotify
//
//  Created by Tony Schneider on 3/21/12.
//  Copyright (c) 2012 Edgecase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZmqDispatch.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>

@interface PlaylistBootstrap : NSObject

- (id) initWithDispatcher:(ZmqDispatch *)aDispatcher;
- (void) reportPlaylistTracks:(SPPlaylist *)playlist;
- (void) loadTracksFromPlaylist:(NSURL *)playlist_url;

@property(retain) ZmqDispatch *dispatcher;

@end
