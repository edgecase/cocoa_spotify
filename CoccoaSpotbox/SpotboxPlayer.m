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
    playback_manager = [[SPPlaybackManager alloc] initWithPlaybackSession:[SPSession sharedSession]];
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
      NSLog(@"shit went wrong");
    }
    return;
  }
  NSBeep();
}

// ********** Session Delegate *********** //

- (void) sessionDidLoginSuccessfully:(SPSession *)aSession {
  NSLog(@"logged in");
  NSString *spotify_str = @"spotify:track:18lwMD3frXxiVWBlztdijW";
  [self play_track:spotify_str];
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
  NSLog(@"session meta data changed");
}

- (void)session:(SPSession *)aSession recievedMessageForUser:(NSString *)aMessage; {  
  NSLog(@"received msg for user: %@", aMessage);
}

@end
