//
//  SpotboxPlayer.m
//  CoccoaSpotbox
//
//  Created by Tony Schneider on 3/8/12.
//  Copyright (c) 2012 Edgecase. All rights reserved.
//

#import "SpotboxPlayer.h"

@implementation SpotboxPlayer

@synthesize playback_manager, dispatcher;

- (id) initWithDispatcher:(ZmqDispatch *)aDispatcher {
  self = [super init];
  if (self) {
    SPSession *session    = [SPSession sharedSession];
    self.playback_manager = [[SPPlaybackManager alloc] initWithPlaybackSession:session];
    self.dispatcher       = aDispatcher;
    
    [self addObserver:self
           forKeyPath:@"playback_manager.currentTrack"
              options:NSKeyValueObservingOptionNew
              context:nil];
  }
  return self;
}

- (void) sendMessage:(NSString *)msg {
  NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
  [dispatcher.pub sendData:data withFlags:ZMQ_NOBLOCK];
}

// Observe currentTrack going to NULL, this signifies the end of a track
//
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if ([keyPath isEqualToString:@"playback_manager.currentTrack"]) {
    if ([change valueForKey:@"new"] == [NSNull null]) {
      NSLog(@"track ended");
      [self sendMessage:@"spotbox:server::track_ended"];
    }
  }
}

// Play a spotify track
//
- (void) play_track:(NSString *)track_str {
  NSURL *track_url = [[NSURL alloc] initWithString:track_str];
  SPTrack *track = [[SPSession sharedSession] trackForURL:track_url];
  
  if (track != nil) {
    if (!track.isLoaded) {
      [self performSelector:@selector(play_track:) withObject:track_str afterDelay:0.1]; // track might not be loaded.
      return;
    }
    
    NSError *error = nil;
    if (![self.playback_manager playTrack:track error:&error]) {
      NSLog(@"shit went wrong: %@", error);
    }
    
    [self sendMessage:[NSString stringWithFormat:@"%@::%@", @"spotbox:server::playing", track_str]];
    
  } else { NSLog(@"WAT"); }
} 

// Pause/Unpause track
//
- (void) pause_track {
  if ([playback_manager isPlaying]) {
    [playback_manager setIsPlaying:NO];
    [self sendMessage:@"spotbox:server::paused"];
  } else {
    NSTimeInterval track_position = [playback_manager trackPosition];
    [playback_manager seekToTrackPosition:track_position];
    [playback_manager setIsPlaying:YES];
    [self sendMessage:@"spotbox:server::unpaused"];
  }
}

// Stop a track
//
- (void) stop_track {
  [playback_manager.playbackSession unloadPlayback];
  [self sendMessage:@"spotbox:server::stopped"];
}

// Report track progress of currently playing track
//
- (void) report_track_progress {
  if ([playback_manager isPlaying]) {
    NSTimeInterval pos       = [playback_manager trackPosition];
    NSString *track_position = [[NSString alloc] initWithFormat:@"%d", (long)pos];
    [self sendMessage:[NSString stringWithFormat:@"%@::%@", @"spotbox:server::track_progress", track_position]];
  }
}

// ********** ZmqDispatch Delegate ******* //

// Called when zmq dispatcher receives data. Assigns self.dispatcher so this class can publish
// 
- (void) zmqDispatchDidReceiveData {  
  [self report_track_progress];
}

- (void) zmqDispatchDidReceivePlay:(NSString *)track_url {
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

// Remove observers

- (void) dealloc {
  [self removeObserver:self forKeyPath:@"playback_manager.currentTrack"];
}

@end
