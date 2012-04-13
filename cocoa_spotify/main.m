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
#import "config.h"
#include "spotify_appkey.c"

int main (int argc, const char * argv[]) {
  @autoreleasepool {
    
    NSArray *args = [[NSProcessInfo processInfo] arguments];
    
    if ([args count] == 0) {
      NSLog(@"Error: Please supply the location of the file containing your appkey");
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
        NSString *dataStr = [[NSString alloc] initWithData:key encoding:NSUTF8StringEncoding];
        NSLog(@"dataStr %@", dataStr);


        [SPSession initializeSharedSessionWithApplicationKey:[NSData dataWithData:key] userAgent:@"com.edgecase.spotbox" error:nil];
        
    //    // Initialize and fiddle with Spotify Session
    //    [SPSession initializeSharedSessionWithApplicationKey:[NSData dataWithBytes:&g_spotify_appkey length:g_spotify_appkey_size]
    //                                               userAgent:@"com.edgecase.spotbox"
    //                                                   error:nil];
        // ZMQ Initialization
        ZMQContext *zmq_ctx     = [[ZMQContext alloc] initWithIOThreads:1];
        NSString *pub_port      = @"tcp://127.0.0.1:12001";
        NSString *sub_port      = @"tcp://127.0.0.1:12000";
        ZmqDispatch *dispatcher = [[ZmqDispatch alloc] initWithContext:zmq_ctx publishTo:pub_port subscribeTo:sub_port];
                  
        // Initialize spotbox classes
        SpotboxPlaylist *playlistManager = [[SpotboxPlaylist alloc] initWithDispatcher:dispatcher];
        SpotboxPlayer *playerManager     = [[SpotboxPlayer alloc] initWithDispatcher:dispatcher];
        
        [[SPSession sharedSession] setDelegate:playerManager];
        
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
        
        // Close sockets later
        [[zmq_ctx sockets] makeObjectsPerformSelector:@selector(close)];  
        return EXIT_SUCCESS;    
      }
    }
  }
}

