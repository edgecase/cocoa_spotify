//
//  PlaylistBootstrap.m
//  cocoa_spotify
//
//  Created by Tony Schneider on 3/21/12.
//  Copyright (c) 2012 Edgecase. All rights reserved.
//

#import "PlaylistBootstrap.h"

@implementation PlaylistBootstrap

@synthesize dispatcher;

- (id) initWithDispatcher:(ZmqDispatch *)aDispatcher {
  self = [super init];
  if (self) {
    self.dispatcher = aDispatcher;
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(load_playlist:) 
                                                 name:@"load_playlist" 
                                               object:nil];
  }
  return self;
}

- (void) reportPlaylistTracks:(SPPlaylist *)playlist {
  NSMutableArray *track_urls = [NSMutableArray array];
  NSMutableArray *tracks = [playlist items];
 
  for (int index = 0; index < [tracks count]; index++) {
    SPPlaylistItem *item = [tracks objectAtIndex:index];
    if ([item itemURLType] == SP_LINKTYPE_TRACK) {
      [track_urls addObject:[item itemURL]];
    }
  }
  
  NSString *playlist_url_str = [[playlist spotifyURL] absoluteString];
  NSString *playlist_name    = [playlist name];
  NSString *tracks_str       = [track_urls componentsJoinedByString:@","];
  NSString *msg = [NSString stringWithFormat:@"spotbox:server::playlist_loaded::%@,%@,%@", playlist_url_str, playlist_name, tracks_str];
  [[dispatcher pub] sendData:[msg dataUsingEncoding:NSUTF8StringEncoding] withFlags:ZMQ_NOBLOCK];
}

- (void) loadTracksFromPlaylist:(NSURL *)playlist_url {
  SPPlaylist *playlist   = [[SPSession sharedSession] playlistForURL:playlist_url];
  
  if (playlist != nil) {
    if (!playlist.isLoaded) {
      [self performSelector:@selector(loadTracksFromPlaylist:) withObject:playlist_url afterDelay:0.1];
      return;
    }
  }
  
  [self reportPlaylistTracks:playlist];
}

//**************** ZmqDispatch Notifications *********************//

- (void) load_playlist:(NSNotification *)notification {
  NSString *playlist_str = [[[notification userInfo] valueForKey:@"args"] objectAtIndex:0];
  NSURL *playlist_url = [[NSURL alloc] initWithString:playlist_str];
  
  [self loadTracksFromPlaylist:playlist_url];
}

//************************* Dealloc *****************************//

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
