//
//  USGIMSocketWrapper.h
//  BTYxyz
//
//  Created by ForKid on 2018/3/23.
//  Copyright © 2018年 CDBottle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "USGIMCommon.h"

@class USGIMBasicCommand;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const kUSGIMSocketOpenedNotificationName;
FOUNDATION_EXPORT NSNotificationName const kUSGIMSocketClosedNotificationName;
FOUNDATION_EXPORT NSNotificationName const kUSGIMSocketReconnectNotificationName;
FOUNDATION_EXPORT NSNotificationName const kUSGIMSocketErrorNotificationName;
///< socket收到消息通知
FOUNDATION_EXPORT NSNotificationName const kUSGIMSocketMessageNotificationName;

@interface USGIMSocketWrapper : NSObject


- (void)openWithCallback:(USGIMBooleanCallback)callback;

- (void)close;

- (void)send:(USGIMBasicCommand *)command callback:(nullable USGIMBooleanCallback)callback;

@end

NS_ASSUME_NONNULL_END
