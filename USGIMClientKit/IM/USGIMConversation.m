//
//  USGIMConversation.m
//  BTYxyz
//
//  Created by ForKid on 2018/3/23.
//  Copyright © 2018年 CDBottle. All rights reserved.
//

#import "USGIMConversation.h"
#import "USGIMConversation_extension.h"
#import "USGIMClient_extension.h"
#import "USGIMMessage_extension.h"
#import "USGIMMessageCacheStore.h"

#import "NSError+USGIM.h"

@interface USGIMConversation ()

@property (nonatomic, strong) USGIMMessageCacheStore *messageCacheStore;

@end

@implementation USGIMConversation

- (instancetype)initWithConversationId:(NSString *)conversationId imClient:(USGIMClient *)imClient{
    self = [super init];
    if (self) {
        
        _conversationId = conversationId.copy;
        
        _imClient = imClient;
        
        _clientId = imClient.clientId.copy;
        
    }
    return self;
}

+ (instancetype)createConversationId:(NSString *)conversationId client:(USGIMClient *)imClient {
    
    if (!conversationId) {
        return nil;
    }
    
    USGIMConversation *conversation = [[USGIMConversation alloc] initWithConversationId:conversationId imClient:imClient];
    
    return conversation;
}


- (void)sendMessage:(USGIMMessage *)message callback:(USGIMBooleanCallback)callback {
    [self sendMessage:message option:nil callback:callback];
}

- (void)sendMessage:(USGIMMessage *)message option:(USGIMMessageOption *)option callback:(USGIMBooleanCallback)callback {
    
    if (self.imClient.status != USGIMClientStatusOpened) {
        
        NSString *reason = @"the client is not open";
        
        NSError *error = [NSError errorWithCode:101 reason:reason];
        
        if (callback) {
            callback(NO, error);
        }
        return;
    }
    
    dispatch_async([USGIMClient imClientQueue], ^{
       
        message.clientId = self.clientId.copy;
        message.conversationId = self.conversationId.copy;
        message.IOType = USGIMMessageIOTypeSend;
        message.status = USGIMMessageStatusSending;
        message.sendTimestamp = NSDate.date.timeIntervalSince1970;
        
        [self.imClient sendMessage:message callback:^(BOOL flag, NSError * _Nullable error) {
            
            if (flag) {
                
                message.status = USGIMMessageStatusSent;
                
            } else {
                
                message.status = USGIMMessageStatusFailed;
                
            }
            
            [self addMessageToCache:message];

            
        }];
        
    });
    
}

- (void)addMessageToCache:(USGIMMessage *)message {
    message.IOType = USGIMMessageIOTypeReceive;
    message.sendTimestamp = NSDate.date.timeIntervalSince1970;
    [self.messageCacheStore addMessage:message];
}

- (void)removeMessageFromCache:(USGIMMessage *)message {
    [self.messageCacheStore deleteMessage:message];
}

- (void)cleanMessageCache {
    [self.messageCacheStore cleanCache];
}


- (USGIMMessageCacheStore *)messageCacheStore {
    if (!_messageCacheStore) {
        _messageCacheStore = [USGIMMessageCacheStore cacheStoreWithClientId:self.clientId coversationId:self.conversationId];
    }
    return _messageCacheStore;
}

@end
