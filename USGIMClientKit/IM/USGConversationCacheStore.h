//
//  USGConversationCacheStore.h
//  BTYxyz
//
//  Created by 周宏辉 on 2018/4/8.
//  Copyright © 2018年 CDBottle. All rights reserved.
//

#import <Foundation/Foundation.h>

@class USGIMClient;
@class USGIMConversation;

NS_ASSUME_NONNULL_BEGIN

@interface USGConversationCacheStore : NSObject

@property (nonatomic, weak) USGIMClient *imClient;
@property (nonatomic, copy, readonly) NSString *clientId;

+ (instancetype)conversationCacheStoreWithClientId:(NSString *)clientId;

- (BOOL)containsConversation:(USGIMConversation *)conversation;

- (void)addConversation:(USGIMConversation *)conversation;

- (void)deleteConversation:(USGIMConversation *)conversation;

- (void)cleanStore;

- (nullable USGIMConversation *)conversationForId:(NSString *)conversationId;

- (nullable NSArray <USGIMConversation *> *)conversationsForIds:(NSArray <NSString *> *)conversationIds;

@end

NS_ASSUME_NONNULL_END
