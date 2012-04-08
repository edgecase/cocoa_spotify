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

@interface ZmqDispatch : NSObject

@property (strong)ZMQSocket *pub;
@property (strong)ZMQSocket *sub;
@property (strong)ZMQContext *ctx;

- (id) initWithContext:(ZMQContext *)ctx 
             publishTo:(NSString *)pubPort 
           subscribeTo:(NSString *)subPort;

- (void) receiveData:(NSTimer *)timer;

- (NSDictionary *) parseMessage:(NSString *)message;

@end
