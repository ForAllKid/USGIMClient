//
//  USGConversationCacheStore.m
//  BTYxyz
//
//  Created by 周宏辉 on 2018/4/8.
//  Copyright © 2018年 CDBottle. All rights reserved.
//

#import "USGConversationCacheStore.h"
#import "USGIMConversation.h"

@interface USGConversationCacheStore ()

@property (nonatomic, strong) NSMutableArray <USGIMConversation *> *conversationContainer;

@end

@implementation USGConversationCacheStore

- (instancetype)initWithClientId:(NSString *)clientId {
    self = [super init];
    if (self) {
        _clientId = clientId.copy;
    }
    return self;
}

+ (instancetype)conversationCacheStoreWithClientId:(NSString *)clientId {
    return [[[self class] alloc] initWithClientId:clientId];
}

- (BOOL)containsConversation:(USGIMConversation *)conversation {
    if (!conversation) {
        return NO;
    }
    return [self conversationForId:conversation.conversationId] != nil;
}

- (void)addConversation:(USGIMConversation *)conversation {
    NSAssert(conversation, @"");
    if ([self containsConversation:conversation]) {
        return;
    }
    [self.conversationContainer addObject:conversation];
}

- (void)deleteConversation:(USGIMConversation *)conversation {
    NSAssert(conversation, @"");
    if ([self containsConversation:conversation] == NO) {
        return;
    }
    [self.conversationContainer removeObject:conversation];
}

- (void)cleanStore {
    [self.conversationContainer removeAllObjects];
}

- (USGIMConversation *)conversationForId:(NSString *)conversationId {
    NSAssert(conversationId, @"");
    USGIMConversation *conversation = nil;
    for (USGIMConversation *one in self.conversationContainer) {
        if ([one.conversationId isEqualToString:conversationId]) {
            conversation = one;
            break;
        }
    }
    return conversation;
}

- (NSArray<USGIMConversation *> *)conversationsForIds:(NSArray<NSString *> *)conversationIds {
    NSMutableArray <USGIMConversation *> *tempContainer = [NSMutableArray new];
    for (NSString *conversationId in conversationIds) {
        if ([self conversationForId:conversationId]) {
            [tempContainer addObject:[self conversationForId:conversationId]];
        }
    }
    return tempContainer;
}

- (NSMutableArray<USGIMConversation *> *)conversationContainer {
    if (!_conversationContainer) {
        _conversationContainer = [NSMutableArray new];
    }
    return _conversationContainer;
}

@end
