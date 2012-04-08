//
//  PlaylistBootstrap.m
//  cocoa_spotify
//
//  Created by Tony Schneider on 3/21/12.
//  Copyright (c) 2012 Edgecase. All rights reserved.
//

#import "SpotboxPlaylist.h"

@implementation SpotboxPlaylist

@synthesize dispatcher;

- (id) initWithDispatcher:(ZmqDispatch *)aDispatcher {
  self = [super init];
  if (self) {
    self.dispatcher = aDispatcher;
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(load_playlist:) 
                                                 name:@"loadPlaylist" 
                                               object:nil];
  }
  return self;
}

- (void) reportPlaylistTracks:(SPPlaylist *)playlist {
  NSMutableArray *trackUrls = [NSMutableArray array];
  NSMutableArray *tracks    = [playlist items];
 
  for (int index = 0; index < [tracks count]; index++) {
    SPPlaylistItem *item = [tracks objectAtIndex:index];
    if ([item itemURLType] == SP_LINKTYPE_TRACK) {
      [trackUrls addObject:[item itemURL]];
    }
  }
  
  NSString *playlistUrlStr = [[playlist spotifyURL] absoluteString];
  NSString *playlistName   = [playlist name];
  NSString *tracksStr      = [trackUrls componentsJoinedByString:@","];
  NSString *msg            = [NSString stringWithFormat:@"spotbox:server::playlist_loaded::%@,%@,%@", playlistUrlStr, playlistName, tracksStr];
  
  [[dispatcher pub] sendData:[msg dataUsingEncoding:NSUTF8StringEncoding] withFlags:ZMQ_NOBLOCK];
}

- (void) loadTracksFromPlaylist:(NSURL *)playlistUrl {
  SPPlaylist *playlist   = [[SPSession sharedSession] playlistForURL:playlistUrl];
  
  if (playlist != nil) {
    if (!playlist.isLoaded) {
      [self performSelector:@selector(loadTracksFromPlaylist:) withObject:playlistUrl afterDelay:0.1];
      return;
    }
  }
  
  [self reportPlaylistTracks:playlist];
}

//**************** ZmqDispatch Notifications *********************//

- (void) load_playlist:(NSNotification *)notification {
  NSString *playlistStr = [[[notification userInfo] valueForKey:@"args"] objectAtIndex:0];
  NSURL *playlistUrl = [[NSURL alloc] initWithString:playlistStr];
  
  [self loadTracksFromPlaylist:playlistUrl];
}

//************************* Dealloc *****************************//

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
