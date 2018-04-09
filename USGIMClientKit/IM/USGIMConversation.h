//
//  USGIMConversation.h
//  BTYxyz
//
//  Created by ForKid on 2018/3/23.
//  Copyright © 2018年 CDBottle. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "USGIMCommon.h"

@class USGIMClient;
@class USGIMMessage;
@class USGIMMessageOption;

NS_ASSUME_NONNULL_BEGIN

@interface USGIMConversation : NSObject

/**
 当前会话客户端id
 */
@property (nonatomic, copy, readonly) NSString *clientId;

/**
 当前会话Id
 */
@property (nonatomic, copy, readonly) NSString *conversationId;

/**
 当前会话名字
 */
@property (nullable, nonatomic, copy, readonly) NSString *name;

/**
 当前会话中的成员
 */
@property (nullable, nonatomic, strong, readonly) NSArray <NSString *> *members;

/**
 当前会话所属客户端
 */
@property (nonatomic, weak, readonly) USGIMClient *imClient;


/**
 发送消息

 @param message 消息实体 不可为空
 @param callback 回调
 */
- (void)sendMessage:(USGIMMessage *)message
           callback:(nullable USGIMBooleanCallback)callback;


/**
 发送消息，可以附带参数

 @param message 消息 不可为空
 @param option 消息参数配置信息
 @param callback 回调
 */
- (void)sendMessage:(USGIMMessage *)message
             option:(nullable USGIMMessageOption *)option
           callback:(nullable USGIMBooleanCallback)callback;


/**
 向会话消息缓存列表中添加一条信息

 @param message 消息对象
 */
- (void)addMessageToCache:(USGIMMessage *)message;

/**
 从会话消息缓存列表移除一条消息

 @param message 消息
 */
- (void)removeMessageFromCache:(USGIMMessage *)message;

/**
 清空当前会话中所有的缓存消息
 */
- (void)cleanMessageCache;


- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
