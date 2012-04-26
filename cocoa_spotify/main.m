//
//  main.m
//  CoccoaSpotbox
//
//  Created by Tony Schneider on 3/8/12.
//  Copyright (c) 2012 Edgecase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZMQObjC.h"
#import <CocoaLibSpotify/CocoaLibSpotify.h>
#import "SpotboxPlayer.h"
#import "SpotboxPlaylist.h"
#import "ZmqDispatch.h"

int main (int argc, const char * argv[]) {
  @autoreleasepool {
    
    NSArray *args = [[NSProcessInfo processInfo] arguments];
    
    if ([args count] == 3) {
      NSLog(@"Error: Please supply the location of the file containing your appkey");
      NSLog(@"");
      NSLog(@"usage: cocoa_spotify ~/location/of/appkey.key username password");
      exit(1);
    } else {
      NSString *appkeyLocation = [args objectAtIndex:1];
      NSFileManager *filemgr   = [NSFileManager defaultManager];
      NSString *path           = [appkeyLocation stringByExpandingTildeInPath];
      
      if ([filemgr fileExistsAtPath:path] == NO) {
        NSLog(@"Error: Unable to locate file at: %@", appkeyLocation);
        exit(1);
      } else {
        NSData *key = [NSData dataWithContentsOfFile:path];
        NSError *error = nil;

        [SPSession initializeSharedSessionWithApplicationKey:[NSData dataWithData:key] userAgent:@"com.edgecase.spotbox" error:&error];
        if (error != nil) { NSLog(@"error while creating session: %@", error); }
                
        // ZMQ Initialization
        ZMQContext *zmq_ctx     = [[ZMQContext alloc] initWithIOThreads:1];
        NSString *pub_port      = @"tcp://127.0.0.1:12001";
        NSString *sub_port      = @"tcp://127.0.0.1:12000";
        ZmqDispatch *dispatcher = [[ZmqDispatch alloc] initWithContext:zmq_ctx publishTo:pub_port subscribeTo:sub_port];
                  
        // Initialize spotbox classes
        SpotboxPlaylist *playlistManager = [[SpotboxPlaylist alloc] initWithDispatcher:dispatcher];
        SpotboxPlayer *playerManager     = [[SpotboxPlayer alloc] initWithDispatcher:dispatcher];
        
        [[SPSession sharedSession] setDelegate:playerManager];
        [[SPSession sharedSession] attemptLoginWithUserName:[args objectAtIndex:2]
                                                   password:[args objectAtIndex:3]
                                        rememberCredentials:NO];

        // create a timer for run loop
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                          target:dispatcher
                                                        selector:@selector(receiveData:)
                                                        userInfo:nil
                                                         repeats:YES];
        // Run Loop
        NSRunLoop *run_loop = [NSRunLoop currentRunLoop];
        [run_loop addTimer:timer forMode:NSDefaultRunLoopMode];
        [run_loop run];    
        
        // Close sockets later
        [[zmq_ctx sockets] makeObjectsPerformSelector:@selector(close)];  
        return EXIT_SUCCESS;    
      }
    }
  }
}

