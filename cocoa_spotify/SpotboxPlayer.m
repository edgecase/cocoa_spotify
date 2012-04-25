//
//  SpotboxPlayer.m
//  CoccoaSpotbox
//
//  Created by Tony Schneider on 3/8/12.
//  Copyright (c) 2012 Edgecase. All rights reserved.
//

#import "SpotboxPlayer.h"

@implementation SpotboxPlayer

@synthesize playbackManager, dispatcher;

- (id) initWithDispatcher:(ZmqDispatch *)aDispatcher {
  self = [super init];
  if (self) {
    SPSession *session   = [SPSession sharedSession];
    self.playbackManager = [[SPPlaybackManager alloc] initWithPlaybackSession:session];
    self.dispatcher      = aDispatcher;
    
    // Add observers
    
    [self addObserver:self
           forKeyPath:@"playbackManager.currentTrack"
              options:NSKeyValueObservingOptionNew
              context:nil];
    
    // Register for notifications
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reportTrackProgress:) name:@"didReceieveData" object:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playTrack:) name:@"play" object:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseTrack:) name:@"pause" object:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unpauseTrack:) name:@"unpause" object:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopTrack:) name:@"stop" object:NULL];
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
  if ([keyPath isEqualToString:@"playbackManager.currentTrack"]) {
    if ([change valueForKey:@"new"] == [NSNull null]) {
      [self sendMessage:@"spotbox:server::trackEnded"];
    }
  }
}

// ********** ZmqDispatch Notifications ******* //

- (void) playTrack:(NSNotification *) notification {
  NSString *trackStr = [[[notification userInfo] valueForKey:@"args"] objectAtIndex:0];
  NSURL *trackUrl    = [[NSURL alloc] initWithString:trackStr];
  SPTrack *track     = [[SPSession sharedSession] trackForURL:trackUrl];
  
  if (track != nil) {
    if (!track.isLoaded) {
      [self performSelector:@selector(playTrack:) withObject:notification afterDelay:0.1]; // track might not be loaded.
      return;
    }
    
    NSError *error = nil;
    if (![self.playbackManager playTrack:track error:&error]) { NSLog(@"Unable to play track: %@", error); }
    
    [self sendMessage:[NSString stringWithFormat:@"%@::%@", @"spotbox:server::playing", trackStr]];
    
  } else { NSLog(@"Track not found."); }
}

- (void) pauseTrack:(NSNotification *) notification {
  if ([playbackManager isPlaying]) {
    [playbackManager setIsPlaying:NO];
    [self sendMessage:@"spotbox:server::paused"];
  } 
}
  
- (void) unpauseTrack:(NSNotification *) notification {
  NSTimeInterval trackPosition = [playbackManager trackPosition];
  [playbackManager seekToTrackPosition:trackPosition];
  [playbackManager setIsPlaying:YES];
  [self sendMessage:@"spotbox:server::unpaused"];
}

- (void) reportTrackProgress:(NSNotification *) notification {
  if ([playbackManager isPlaying]) {
    NSTimeInterval pos      = [playbackManager trackPosition];
    NSString *trackPosition = [[NSString alloc] initWithFormat:@"%d", (long)pos];
    NSString *currentTrack  = [[[playbackManager currentTrack] spotifyURL] absoluteString];

    [self sendMessage:[NSString stringWithFormat:@"%@::%@::%@", @"spotbox:server::trackProgress", trackPosition, currentTrack]];
  }
}

- (void) stopTrack:(NSNotification *) notification {
  [playbackManager.playbackSession unloadPlayback];
  [self sendMessage:@"spotbox:server::stopped"];
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
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end