//
//  ZmqDispatch.m
//  CoccoaSpotbox
//
//  Created by Tony Schneider on 3/8/12.
//  Copyright (c) 2012 Edgecase. All rights reserved.
//

#import "ZmqDispatch.h"

@implementation ZmqDispatch

@synthesize pub, sub, ctx, delegate;

- (id) initWithContext:(ZMQContext *)zmq_context
             publishTo:(NSString *)pub_port 
           subscribeTo:(NSString *)sub_port {
  self.ctx = zmq_context;
  self.sub = [ctx socketWithType:ZMQ_SUB];
  self.pub = [ctx socketWithType:ZMQ_PUB];
  
  [pub bindToEndpoint:pub_port];
  [sub connectToEndpoint:sub_port];
  
  const char *filter = "spotbox:players:spotify";
  NSData *filterData = [NSData dataWithBytes:filter length:strlen(filter)];
  [sub setData:filterData forOption:ZMQ_SUBSCRIBE];

  return self;
}

- (NSDictionary *) parseMessage:(NSString *)zmq_message {
  NSArray *msg          = [zmq_message componentsSeparatedByString:@"::"];
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
  
  [delegate zmqDispatchDidReceiveData]; // provide hook for delegates
  
  if (data) {
    NSString *msg               = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
    NSDictionary *parsedMessage = [self parseMessage:msg];
    NSString *method_name       = [parsedMessage valueForKey:@"method"];
    
    if ([method_name isEqualToString:@"play"]) {
      NSString *track_str = [[parsedMessage valueForKey:@"args"] objectAtIndex:0];
      [delegate zmqDispatchDidReceivePlay:track_str];
    } else if ([method_name isEqualToString:@"stop"]) {
      [delegate zmqDispatchDidReceiveStop];
    } else if ([method_name isEqualToString:@"pause"] || [method_name isEqualToString:@"unpause"]) {
      [delegate zmqDispatchDidReceivePause];
    } else if ([method_name isEqualToString:@"load_playlist"]) {
      [[NSNotificationCenter defaultCenter] postNotificationName:method_name object:self userInfo:parsedMessage];
    } else {
      NSLog(@"Unsupported method: %@ w/ raw msg: %@", method_name, msg);
    }
  }
}

@end
