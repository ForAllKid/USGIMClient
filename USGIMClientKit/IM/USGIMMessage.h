//
//  USGIMMessage.h
//  BTYxyz
//
//  Created by ForKid on 2018/3/23.
//  Copyright © 2018年 CDBottle. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, USGIMMessageType) {
    ///< 未知消息类型
    USGIMMessageTypeUnknown = -1,
    ///< 文本消息
    USGIMMessageTypeText = 0,
};

typedef NS_ENUM(NSUInteger, USGIMMessageStatus) {
    ///< 未知状态 一般用于未指定状态
    USGIMMessageStatusUnknown = -1,
    ///< 发送失败的消息
    USGIMMessageStatusFailed = 0,
    ///< 消息等待发送
    USGIMMessageStatusWating,
    ///< 消息发送中
    USGIMMessageStatusSending,
    ///< 已发送的消息
    USGIMMessageStatusSent
};

typedef NS_ENUM(NSUInteger, USGIMMessageIOType) {
    ///< 发出的消息
    USGIMMessageIOTypeSend = 0,
    ///< 收到的消息
    USGIMMessageIOTypeReceive
};

NS_ASSUME_NONNULL_BEGIN

@interface USGIMMessage : NSObject

/**
 客户端id
 */
@property (nonatomic, copy, readonly) NSString *clientId;

/**
 所属会话Id
 */
@property (nonatomic, copy, readonly) NSString *conversationId;

/**
 消息id
 */
@property (nonatomic, copy, readonly) NSString *messageId;

/**
 消息状态
 */
@property (nonatomic, readonly) USGIMMessageStatus status;

/**
 消息状态
 */
@property (nonatomic, readonly) USGIMMessageType type;

/**
 消息状态
 */
@property (nonatomic, readonly) USGIMMessageIOType IOType;


/**
 发送成功时间，如果发送失败，每次重试会重置该时间
 */
@property (nonatomic, readonly) NSTimeInterval sendTimestamp;


/**
 文本内容
 */
@property (nonatomic, copy, readonly) NSString *content;

/**
 根据指定的文本文字构造一个消息实体

 @param content 文本内容，不可为空
 @return 消息实例
 */
+ (USGIMMessage *)messageWithContent:(NSString *)content;

@end

NS_ASSUME_NONNULL_END
