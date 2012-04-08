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

@interface SpotboxPlayer : NSObject <SPSessionDelegate> {
  SPPlaybackManager *playbackManager;
}

@property(retain) SPPlaybackManager *playbackManager;
@property(retain) ZmqDispatch *dispatcher;

- (id)   initWithDispatcher:(ZmqDispatch *)aDispatcher;
- (void) sendMessage:(NSString *)msg;

@end
