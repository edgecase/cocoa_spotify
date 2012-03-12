//
//  SpotboxPlayer.m
//  CoccoaSpotbox
//
//  Created by Tony Schneider on 3/8/12.
//  Copyright (c) 2012 Edgecase. All rights reserved.
//

#import "SpotboxPlayer.h"

@implementation SpotboxPlayer

@synthesize playback_manager;

- (id) init {
  self = [super init];
  if (self) {
    SPSession *session = [SPSession sharedSession];
    playback_manager = [[SPPlaybackManager alloc] initWithPlaybackSession:session];
  }
  return self;
}

- (void) play_track:(NSString *)track_str {
  NSURL *track_url = [[NSURL alloc] initWithString:track_str];
  SPTrack *track = [[SPSession sharedSession] trackForURL:track_url];
  
  if (track != nil) {
    if (!track.isLoaded) {
      // track might not be loaded. So call it again!
      [self performSelector:@selector(play_track:) withObject:track_str afterDelay:0.1];
      return;
    }
    
    NSError *error = nil;
    
    if (![self.playback_manager playTrack:track error:&error]) {
      NSLog(@"shit went wrong: %@", error);
    }
    return;
  }
  NSBeep();
}

- (void) pause_track {
  if ([playback_manager isPlaying]) {
    [playback_manager setIsPlaying:NO];
  } else {
    NSTimeInterval track_position = [playback_manager trackPosition];
    [playback_manager seekToTrackPosition:track_position];
    [playback_manager setIsPlaying:YES];
  }
}

- (void) stop_track {
  [playback_manager.playbackSession unloadPlayback];
}

// ********** ZmqDispatch Delegate ******* //

- (void) zmqDispatchDidReceiveData:(ZmqDispatch *)dispatcher {
  if ([playback_manager isPlaying]) {
    NSTimeInterval pos       = [playback_manager trackPosition];
    NSString *track_position = [[NSString alloc] initWithFormat:@"%d", ((long)pos % 60)];
    NSString *message        = [NSString stringWithFormat:@"%@::%@::%@", @"spotbox:server", @"track_progress", track_position];
    NSData* data             = [message dataUsingEncoding:NSUTF8StringEncoding];
    
    [dispatcher.pub sendData:data withFlags:ZMQ_NOBLOCK];
  }
}

- (void) zmqDispatchDidReceivePlay:(NSString *)track_url {
  NSLog(@"PLAY");
  [self play_track:track_url];
}

- (void) zmqDispatchDidReceiveStop {
  [self stop_track];
}

- (void) zmqDispatchDidReceivePause {
  [self pause_track];
}

// **********  Session Delegate ********** //

- (void) sessionDidLoginSuccessfully:(SPSession *)aSession {
  NSLog(@"logged in");
}

- (void) session:(SPSession *)aSession didFailToLoginWithError:(NSError *)error {
  NSLog(@"session failed to login: %@", error);
}

- (void) session:(SPSession *)aSession didEncounterNetworkError:(NSError *)error {
  NSLog(@"session network error: %@", error);
}

- (void) session:(SPSession *)aSession didLogMessage:(NSString *)aMessage {
  NSLog(@"session log: %@", aMessage);
}

- (void)sessionDidChangeMetadata:(SPSession *)aSession; {
  NSLog(@"meta data changed");
}

- (void)session:(SPSession *)aSession recievedMessageForUser:(NSString *)aMessage; {  
  NSLog(@"received msg for user: %@", aMessage);
}

// Unregister observers

- (void) dealloc {
  
}

@end
