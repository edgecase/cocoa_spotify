//
//  ZmqDispatch.m
//  CoccoaSpotbox
//
//  Created by Tony Schneider on 3/8/12.
//  Copyright (c) 2012 Edgecase. All rights reserved.
//

#import "ZmqDispatch.h"

@implementation ZmqDispatch

@synthesize pub, sub, ctx;

- (id) initWithContext:(ZMQContext *)zmqContext
             publishTo:(NSString *)pubPort 
           subscribeTo:(NSString *)subPort {
  self.ctx = zmqContext;
  self.sub = [ctx socketWithType:ZMQ_SUB];
  self.pub = [ctx socketWithType:ZMQ_PUB];
  
  [pub bindToEndpoint:pubPort];
  [sub connectToEndpoint:subPort];
  
  const char *filter = "spotbox:players:spotify";
  NSData *filterData = [NSData dataWithBytes:filter length:strlen(filter)];
  [sub setData:filterData forOption:ZMQ_SUBSCRIBE];

  return self;
}

- (NSDictionary *) parseMessage:(NSString *)zmqMessage {
  NSArray *msg          = [zmqMessage componentsSeparatedByString:@"::"];
  NSString *destination = [msg objectAtIndex:0];
  NSString *method      = [msg objectAtIndex:1];
  NSArray *args         = NULL;

  if ([msg count] > 2) {
    NSRange args_range = NSMakeRange(2, [msg count] - 2);
    args = [msg subarrayWithRange:args_range];
  } else {
    args = [[NSArray alloc] init];
  }
  
  NSArray *keys      = [NSArray arrayWithObjects:@"destination", @"method", @"args", nil];
  NSArray *vals      = [NSArray arrayWithObjects:destination, method, args, nil];
  NSDictionary *data = [[NSDictionary alloc] initWithObjects:vals forKeys:keys];
  
  return data;
}

// ***** Called during Run loop ****** //

- (void) receiveData:(NSTimer *)timer {
  NSData *data = [sub receiveDataWithFlags:ZMQ_NOBLOCK];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"didReceieveData" object:self];
  
  if (data) {
    NSString *msg               = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
    NSDictionary *parsedMessage = [self parseMessage:msg];
    NSString *methodName        = [parsedMessage valueForKey:@"method"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:methodName object:self userInfo:parsedMessage];
  }
}

@end
