//
//  SpotboxPlayer.h
//  CoccoaSpotbox
//
//  Created by Tony Schneider on 3/8/12.
//  Copyright (c) 2012 Edgecase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPPlaybackManager.h"

@interface SpotboxPlayer : NSObject <SPSessionDelegate> {
  SPPlaybackManager *playback_manager;
}

@property(retain) SPPlaybackManager *playback_manager;

- (void)play_track:(NSString *)track_url;

@end
