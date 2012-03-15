//
//  ZmqDispatch.h
//  CoccoaSpotbox
//
//  Created by Tony Schneider on 3/8/12.
//  Copyright (c) 2012 Edgecase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZMQObjC.h"

@class ZmqDispatch;

@protocol ZmqDispatchDelegate <NSObject>

- (void) zmqDispatchDidReceivePlay:(NSString *)track_url;
- (void) zmqDispatchDidReceiveData;
- (void) zmqDispatchDidReceiveStop;
- (void) zmqDispatchDidReceivePause;

@end

@interface ZmqDispatch : NSObject

@property (strong)ZMQSocket *pub;
@property (strong)ZMQSocket *sub;
@property (strong)ZMQContext *ctx;
@property (nonatomic, weak) id <ZmqDispatchDelegate> delegate;

- (id) initWithContext:(ZMQContext *)ctx 
             publishTo:(NSString *)pub_port 
           subscribeTo:(NSString *)sub_port;

- (void) receiveData:(NSTimer *)timer;

- (NSDictionary *) parseMessage:(NSString *)message;

@end
