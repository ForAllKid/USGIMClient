//
//  USGIMMessage_extension.h
//  BTYxyz
//
//  Created by 周宏辉 on 2018/4/8.
//  Copyright © 2018年 CDBottle. All rights reserved.
//

#import "USGIMMessage.h"

@interface USGIMMessage ()

/**
 客户端id
 */
@property (nonatomic, copy) NSString *clientId;

/**
 所属会话Id
 */
@property (nonatomic, copy) NSString *conversationId;

/**
 消息id
 */
@property (nonatomic, copy) NSString *messageId;

/**
 消息id
 */
@property (nonatomic, copy) NSString *content;

/**
 发送时间
 */
@property (nonatomic) NSTimeInterval sendTimestamp;

/**
 消息状态
 */
@property (nonatomic) USGIMMessageStatus status;

/**
 消息状态
 */
@property (nonatomic) USGIMMessageType type;

/**
 消息状态
 */
@property (nonatomic) USGIMMessageIOType IOType;



@end
