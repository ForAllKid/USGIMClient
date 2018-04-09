//
//  USGIMRouter.m
//  BTYxyz
//
//  Created by ForKid on 2018/4/2.
//  Copyright © 2018年 CDBottle. All rights reserved.
//

#import "USGIMRouter.h"

NSString *const kUSGIMServerRouterURLNameKey = @"com.USGIM.router.serverURL";

@interface USGIMRouter ()

@property (nonatomic, strong) NSMutableDictionary <NSString *, NSString *> *innerServerTable;

@end

@implementation USGIMRouter

+ (instancetype)sharedRouter {
    
    static USGIMRouter *_router = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _router = [[[self class] alloc] init];
    });
    return _router;
}

- (void)fetchWebSocketServerInbackgroundWithCompletionHandler:(void (^)(NSString * _Nullable, NSError * _Nullable))completionHandler {
    
    NSURL *url = [NSURL URLWithString:@"http://192.168.6.3/readshare/port2/Text/getServerIp"];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
      
        if (error) {
            NSLog(@"the load error is %@", error.localizedDescription);
            if (completionHandler) {
                completionHandler(nil, error);
            }
            return;
        }
        
        NSError *jsonFormatError = nil;
        
        id responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonFormatError];
        
        if (jsonFormatError) {
            if (completionHandler) {
                completionHandler(nil, jsonFormatError);
            }
            return;
        }
        
        NSDictionary *responseDict = (NSDictionary *)responseObject;
        
        NSDictionary *contentDict = responseDict[@"content"];
        
        NSString *server = contentDict[@"addr_ip"];
        NSString *port = contentDict[@"port"];

        NSString *socketServer = [NSString stringWithFormat:@"ws://%@:%@", server, port];
            
        self.innerServerTable[kUSGIMServerRouterURLNameKey] = socketServer;
        
        if (completionHandler) {
            completionHandler(socketServer, nil);
        }
    }];
    
    
    [task resume];
}

- (NSMutableDictionary<NSString *,NSString *> *)innerServerTable {
    if (!_innerServerTable) {
        _innerServerTable = [[NSMutableDictionary alloc] init];
    }
    return _innerServerTable;
}

- (NSDictionary<NSString *,NSString *> *)serverTable {
    return self.innerServerTable;
}

@end
