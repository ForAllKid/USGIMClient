//
//  USGIMConversationMessageStore.m
//  BTYxyz
//
//  Created by 周宏辉 on 2018/4/8.
//  Copyright © 2018年 CDBottle. All rights reserved.
//

#import "USGIMMessageCacheStore.h"
#import "USGIMMessage.h"

@interface USGIMMessageCacheStore ()

@property (nonatomic, strong) NSMutableArray <USGIMMessage *> *messageContainer;

@end

@implementation USGIMMessageCacheStore

- (instancetype)initWithClientId:(NSString *)clientId coversationId:(NSString *)conversationId {
    self = [super init];
    if (self) {
        _clientId = clientId.copy;
        _conversationId = conversationId.copy;
    }
    return self;
}

+ (instancetype)cacheStoreWithClientId:(NSString *)clientId coversationId:(NSString *)conversationId {
    return [[[self class] alloc] initWithClientId:clientId coversationId:conversationId];
}

- (BOOL)containsMessage:(USGIMMessage *)message {
    return [self.messageContainer containsObject:message];
}

- (USGIMMessage *)messageForId:(NSString *)messageId {
    NSAssert(messageId, @"");
    
    USGIMMessage *message = nil;
    
    for (USGIMMessage *one in self.messageContainer) {
        if ([one.messageId isEqualToString:messageId]) {
            message = one;
            break;
        }
    }
    return message;
}

- (NSArray<USGIMMessage *> *)messagesForContent:(NSString *)content {
    NSAssert(content, @"");
        
    NSMutableArray <USGIMMessage *> *tempContainer = [NSMutableArray new];
    
    for (USGIMMessage *one in self.messageContainer) {
        if ([one.content isEqualToString:content]) {
            [tempContainer addObject:one];
        }
    }
    return tempContainer;
}

- (void)addMessage:(USGIMMessage *)message {
    if ([self containsMessage:message]) {
        return;
    }
    [self.messageContainer addObject:message];
}

- (void)addMessages:(NSArray<USGIMMessage *> *)messages {
    if (!messages || messages.count == 0) {
        return;
    }
    for (USGIMMessage *one in messages) {
        [self addMessage:one];
    }
}

- (void)deleteMessage:(USGIMMessage *)message {
    if (!message || [self containsMessage:message] == NO) {
        return;
    }
    [self.messageContainer removeObject:message];
}

- (void)deleteMessages:(NSArray<USGIMMessage *> *)messages {
    if (!messages || messages.count == 0) {
        return;
    }
    for (USGIMMessage *one in messages) {
        [self deleteMessage:one];
    }
}

- (void)cleanCache {
    [self.messageContainer removeAllObjects];
}

- (NSMutableArray<USGIMMessage *> *)messageContainer {
    if (!_messageContainer) {
        _messageContainer = [NSMutableArray new];
    }
    return _messageContainer;
}

@end
