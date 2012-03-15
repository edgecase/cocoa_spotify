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
#import "ZmqDispatch.h"

#import "config.h"
#include "spotify_appkey.c"

int main (int argc, const char * argv[]) {
  @autoreleasepool {
    
    // ZMQ Initialization
    ZMQContext *zmq_ctx     = [[ZMQContext alloc] initWithIOThreads:1];
    NSString *pub_port      = @"tcp://127.0.0.1:12001";
    NSString *sub_port      = @"tcp://127.0.0.1:12000";
    ZmqDispatch *dispatcher = [[ZmqDispatch alloc] initWithContext:zmq_ctx publishTo:pub_port subscribeTo:sub_port];
              
    // Initialize and fiddle with Spotify Session
    [SPSession initializeSharedSessionWithApplicationKey:[NSData dataWithBytes:&g_spotify_appkey length:g_spotify_appkey_size]
                                               userAgent:@"com.edgecase.spotbox"
                                                   error:nil];
    
    // Initialize spotify player    
    SpotboxPlayer *player = [[SpotboxPlayer alloc] initWithDispatcher:dispatcher];
    [dispatcher setDelegate:player];
    [[SPSession sharedSession] setDelegate:player];
    
    NSFileManager *fm  = [NSFileManager defaultManager];
    NSString *username = [fm stringWithFileSystemRepresentation:SPOTIFY_USERNAME length:10];
    NSString *password = [fm stringWithFileSystemRepresentation:SPOTIFY_PASSWORD length:10];
    [[SPSession sharedSession] attemptLoginWithUserName:username
                                               password:password
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
    
    // Close sockets later (TODO: not sure if necessary)
    [[zmq_ctx sockets] makeObjectsPerformSelector:@selector(close)];  
    return EXIT_SUCCESS;    
  }
}

