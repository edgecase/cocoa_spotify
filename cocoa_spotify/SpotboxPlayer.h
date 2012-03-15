//
//  SpotboxPlayer.h
//  CoccoaSpotbox
//
//  Created by Tony Schneider on 3/8/12.
//  Copyright (c) 2012 Edgecase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPPlaybackManager.h"
#import "ZmqDispatch.h"

@interface SpotboxPlayer : NSObject <SPSessionDelegate, ZmqDispatchDelegate> {
  SPPlaybackManager *playback_manager;
}

@property(retain) SPPlaybackManager *playback_manager;
@property(retain) ZmqDispatch *dispatcher;

- (id) initWithDispatcher:(ZmqDispatch *)aDispatcher;

- (void) sendMessage:(NSString *)msg;
- (void) play_track:(NSString *)track_url;
- (void) stop_track;
- (void) pause_track;

@end
