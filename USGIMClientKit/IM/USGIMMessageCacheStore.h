//
//  USGIMConversationMessageStore.h
//  BTYxyz
//
//  Created by 周宏辉 on 2018/4/8.
//  Copyright © 2018年 CDBottle. All rights reserved.
//

#import <Foundation/Foundation.h>

@class USGIMMessage;

NS_ASSUME_NONNULL_BEGIN

@interface USGIMMessageCacheStore : NSObject

@property (nonatomic, copy, readonly) NSString *clientId;

@property (nonatomic, copy, readonly) NSString *conversationId;

+ (instancetype)cacheStoreWithClientId:(NSString *)clientId coversationId:(NSString *)conversationId;

- (void)addMessage:(USGIMMessage *)message;
- (void)addMessages:(NSArray <USGIMMessage *> *)messages;

- (void)deleteMessage:(USGIMMessage *)message;
- (void)deleteMessages:(NSArray <USGIMMessage *> *)messages;
- (void)cleanCache;

- (BOOL)containsMessage:(USGIMMessage *)message;

- (nullable USGIMMessage *)messageForId:(NSString *)messageId;
- (nullable NSArray <USGIMMessage *> *)messagesForContent:(NSString *)content;

@end

NS_ASSUME_NONNULL_END
