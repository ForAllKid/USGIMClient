//
//  USGIMClient.h
//  BTYxyz
//
//  Created by ForKid on 2018/3/23.
//  Copyright © 2018年 CDBottle. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "USGIMCommon.h"

@class USGIMMessage;
@class USGIMConversation;
@class USGIMSocketWrapper;
@class USGIMConversationQuery;

@protocol USGIMClientDelegate;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, USGIMClientStatus) {
    ///< 初始状态，触发在initial后
    USGIMClientStatusNone = 0,
    ///< 正在建立连接
    USGIMClientStatusOpening,
    ///< 已经建立连接
    USGIMClientStatusOpened,
    ///< 客户端暂停, 一般触发在网络状态发生改变
    USGIMClientStatusPaused,
    ///< 客户端回复连接中，触发在pause后
    USGIMClientStatusResuming,
    ///< 客户端正在关闭（断开连接）
    USGIMClientStatusClosing,
    ///< 客户端已关闭连接
    USGIMClientStatusClosed
};

@interface USGIMClient : NSObject


+ (dispatch_queue_t)imClientQueue;

/**
 delegate
 */
@property (nullable, nonatomic, weak) id<USGIMClientDelegate> delegate;

/**
 当前客户端用户
 */
@property (nonatomic, copy, readonly) NSString *clientId;

/**
 状态，参照枚举说明
 */
@property (nonatomic, readonly) USGIMClientStatus status;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;


/**
 根据一个Id创建一个客户端

 @param clientId 客户端Id
 @return 实例
 */
- (instancetype)initWithClientId:(NSString *)clientId;

/**
 建立连接

 @param callback 连接回调
 */
- (void)openWithCallback:(nullable USGIMBooleanCallback)callback;

/**
 关闭连接

 @param callback 关闭回调
 */
- (void)closeWithCallback:(nullable USGIMBooleanCallback)callback;


/**
 创建一个会话，会话名字可为空
 
 @param conversationName 会话名字，可为空
 @param clientId 其他客户端Id，不可为空
 @param callback 创建回调
 */
- (void)createConversationWithName:(nullable NSString *)conversationName
                          clientId:(NSString *)clientId
                          callback:(nullable USGIMBooleanCallback)callback;


/**
 构造一个会话查询对象

 @return 返回会话查询对象
 */
- (USGIMConversationQuery *)conversationQuery;

/**
 移除并关闭一个会话，该会话必须是当前客户端已经创建的

 @param conversation 会话
 */
- (void)removeConversation:(USGIMConversation *)conversation;

/**
 清空关闭所有会话
 */
- (void)removeAllConversations;


@end

//MARK: - delegate

@protocol USGIMClientDelegate <NSObject>

@optional

/**
 *  当前聊天状态被暂停，常见于网络断开时触发。
 *  @param imClient 相应的 imClient
 */
- (void)imClientPaused:(USGIMClient *)imClient;

/**
 *  当前聊天状态被暂停，常见于网络断开时触发。
 *  注意：该回调会覆盖 imClientPaused: 方法。
 *  @param imClient 相应的 imClient
 *  @param error    具体错误信息
 */
- (void)imClientPaused:(USGIMClient *)imClient error:(NSError *)error;

/**
 *  当前聊天状态开始恢复，常见于网络断开后开始重新连接。
 *  @param imClient 相应的 imClient
 */
- (void)imClientResuming:(USGIMClient *)imClient;

/**
 *  当前聊天状态已经恢复，常见于网络断开后重新连接上。
 *  @param imClient 相应的 imClient
 */
- (void)imClientResumed:(USGIMClient *)imClient;

/*!
 接收到新的普通消息。
 @param conversation － 所属对话
 @param message - 具体的消息
 */
- (void)conversation:(USGIMConversation *)conversation didReceiveCommonMessage:(USGIMMessage *)message;

/*!
 客户端下线通知。
 @param imClient 已下线的 client。
 @param error 错误信息。
 */
- (void)imClient:(USGIMClient *)imClient didOfflineWithError:(nullable NSError *)error;



@end

NS_ASSUME_NONNULL_END
