//
//  USGIMRouter.h
//  BTYxyz
//
//  Created by ForKid on 2018/4/2.
//  Copyright © 2018年 CDBottle. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const kUSGIMServerRouterURLNameKey;

@interface USGIMRouter : NSObject

/**
 * 地址缓存表
 */
@property (nonatomic, strong, readonly) NSDictionary <NSString *, NSString *> *serverTable;

+ (instancetype)sharedRouter;

- (void)fetchWebSocketServerInbackgroundWithCompletionHandler:(nullable void(^)(NSString *_Nullable webSocketServer, NSError *_Nullable error))completionHandler;


@end

NS_ASSUME_NONNULL_END
