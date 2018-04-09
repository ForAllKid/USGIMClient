//
//  USGIMClient.m
//  BTYxyz
//
//  Created by ForKid on 2018/3/23.
//  Copyright © 2018年 CDBottle. All rights reserved.
//

#import "USGIMClient.h"
#import "USGIMClient_extension.h"
#import "NSError+USGIM.h"
#import "USGIMConversation_extension.h"
#import "USGIMMessage_extension.h"
#import "USGConversationCacheStore.h"
#import "USGIMSocketWrapper.h"
#import "USGIMConversationQuery.h"
#import "USGIMBasicCommand.h"

#if __has_include(<YYKit/YYKit.h>)
#import <YYKit/YYKit.h>
#else
#import "YYKit/YYKit.h"
#endif


dispatch_queue_t imClientQueue = NULL;



@interface USGIMClient () {
    dispatch_queue_t _conversationMemeryQueue;
}

@property (nonatomic, strong) USGConversationCacheStore *conversationCacheStore;

@end

@implementation USGIMClient

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imClientQueue = dispatch_queue_create("com.USGIM.Client", DISPATCH_QUEUE_SERIAL);
    });
}

+ (dispatch_queue_t)imClientQueue {
    return imClientQueue;
}

//MARK: - life cycle

- (instancetype)initWithClientId:(NSString *)clientId {
    self = [super init];
    if (self) {
        
        _clientId = clientId.copy;
        
        _status = USGIMClientStatusNone;
        
        _conversationMemeryQueue = dispatch_queue_create("com.USGIM.queue.conversationMemery", DISPATCH_QUEUE_SERIAL);
        
        USGIMSocketWrapper *socketWrapper = [USGIMSocketWrapper new];
        
        NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
        
        [center addObserver:self
                   selector:@selector(webSocketOpend:)
                       name:kUSGIMSocketOpenedNotificationName
                     object:socketWrapper];
        
        [center addObserver:self
                   selector:@selector(webSocketReconnecting:)
                       name:kUSGIMSocketReconnectNotificationName
                     object:socketWrapper];
        
        [center addObserver:self
                   selector:@selector(webSocketClosed:)
                       name:kUSGIMSocketClosedNotificationName
                     object:socketWrapper];
        
        [center addObserver:self
                   selector:@selector(webSocketReceiveMessage:)
                       name:kUSGIMSocketMessageNotificationName
                     object:socketWrapper];
        
        [center addObserver:self
                   selector:@selector(webSocketReceiveError:)
                       name:kUSGIMSocketErrorNotificationName
                     object:socketWrapper];
        
        _socketWrapper = socketWrapper;
        
    }
    return self;
}


- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_socketWrapper close];
}

//MARK: - open

- (void)openWithCallback:(USGIMBooleanCallback)callback {
    [self openWithClientId:self.clientId callback:callback];
}

- (void)openWithClientId:(NSString *)clientId callback:(USGIMBooleanCallback)callback {
    
    if (!clientId) {
        [NSException raise:NSInternalInconsistencyException format:@"the clientId is nil"];
    }
    
    //判断长度。。。
    
    
    //打开
    
    dispatch_async(imClientQueue, ^{
       
        if (self.status != USGIMClientStatusOpened) {
            
            [self.socketWrapper openWithCallback:^(BOOL flag, NSError * _Nullable error) {
                
                dispatch_async_on_main_queue(^{
                    if (callback) {
                        callback(flag, error);
                    }
                });
                
            }];
            
        }
        
    });
    
}


//MARK: - close

- (void)closeWithCallback:(USGIMBooleanCallback)callback {
    
    dispatch_async(imClientQueue, ^{
       
        if (self.status == USGIMClientStatusClosed) {
            if (callback) {
                callback(YES, nil);
            }
            return;
        }
        
        [self.socketWrapper close];
        
        /**
         这里可以将会话保存在本地，下次启动时在重新拉去生成
         */
        [self.conversationCacheStore cleanStore];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(imClient:didOfflineWithError:)]) {
            [self.delegate imClient:self didOfflineWithError:nil];
        }
        
        if (callback) {
            callback(YES, nil);
        }
        
    });
    
}


- (void)sendMessage:(USGIMMessage *)message {
    [self sendMessage:message callback:NULL];
}

- (void)sendMessage:(USGIMMessage *)message callback:(USGIMBooleanCallback)callback {
#warning 这里要改的
    
    USGIMBasicCommand *command = [[USGIMBasicCommand alloc] init];
    [self.socketWrapper send:command callback:callback];
    
}

//MARK: - create conversation

- (void)createConversationWithName:(NSString *)conversationName clientId:(NSString *)clientId callback:(USGIMBooleanCallback)callback {
    
    if ([clientId isNotBlank] == NO) {
        NSString *reason = @"the other clientId can not be nil";
        NSError *error = [NSError errorWithCode:10 reason:reason];
        
        if (callback) {
            callback(NO, error);
        }
        return;
    }
    
    NSArray <NSString *> *members = @[self.clientId, clientId];
 
    dispatch_async(imClientQueue, ^{
       
        USGIMConversation *conversation = [self getConversationWithConversationId:[self conversationIdWithOtherClientId:clientId]];
        
        conversation.members = members.copy;
        conversation.name = conversationName.copy;
        
        if (!conversation) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSString *reason = [NSString stringWithFormat:@"Create Conversation failed"];
                
                NSError *error = [NSError errorWithCode:11 reason:reason];
                
                callback(NO, error);
                                    
            });
            
            return;
            
        }
        
        if (callback) {
            callback(YES, nil);
        }
        
        
    });
    
}


- (USGIMConversation *)getConversationWithConversationId:(NSString *)conversationId {
    
    __block USGIMConversation *conversation = nil;
    
    dispatch_async(_conversationMemeryQueue, ^{
        
        conversation = [self _getConversationWithConversationId:conversationId];
        
    });
    
    return nil;
}

- (USGIMConversation *)_getConversationWithConversationId:(NSString *)conversationId {
    
    if (!conversationId) {
        return nil;
    }
    
    
    USGIMConversation *conversation = [self _getConversationFromMemoryWithConversationId:conversationId];
    
    if (conversation) {
        return conversation;
    }
    
    conversation = [USGIMConversation createConversationId:conversationId client:self];
    [self.conversationCacheStore addConversation:conversation];
    
    return conversation;
 
}

- (USGIMConversation *)_getConversationFromMemoryWithConversationId:(NSString *)conversationId {
    
    return [self.conversationCacheStore conversationForId:conversationId];
    
}

- (USGIMConversationQuery *)conversationQuery {
    USGIMConversationQuery *query = [[USGIMConversationQuery alloc] init];
    
    return query;
}

- (void)removeConversation:(USGIMConversation *)conversation {
    [self.conversationCacheStore deleteConversation:conversation];
}

- (void)removeAllConversations {
    [self.conversationCacheStore cleanStore];
}

//MARK: -

- (NSString *)conversationIdWithOtherClientId:(NSString *)otherClientId {
    return [[NSString stringWithFormat:@"%@%@USGIM", self.clientId, otherClientId] md5String];
}



//MARK: - socket status change

- (void)webSocketOpend:(NSNotification *)notification {
    
    dispatch_async(imClientQueue, ^{
       
        self.status = USGIMClientStatusOpened;

        if (self.delegate && [self.delegate respondsToSelector:@selector(imClientResumed:)]) {
            [self.delegate imClientResumed:self];
        }
        
    });
    
}

- (void)webSocketReconnecting:(NSNotification *)notification {
    
    dispatch_async(imClientQueue, ^{
       
        self.status = USGIMClientStatusResuming;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(imClientResuming:)]) {
            [self.delegate imClientResuming:self];
        }
        
    });
    
}

- (void)webSocketClosed:(NSNotification *)notification {
    
    dispatch_async(imClientQueue, ^{
       
        self.status = USGIMClientStatusPaused;
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(imClientPaused:)]) {
            [self.delegate imClientPaused:self];
        }
        
    });
    
}

- (void)webSocketReceiveMessage:(NSNotification *)notification {
    
    dispatch_async(imClientQueue, ^{
       
        NSDictionary *userInfo = notification.userInfo;
        
        NSData *data = userInfo[@"message"];
        
        NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        USGIMMessage *message = [USGIMMessage messageWithContent:content];
#warning 这里要格式化一下clientId
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(conversation:didReceiveCommonMessage:)]) {
            
            USGIMConversation *conversation = [self getConversationWithConversationId:message.conversationId];
            
            [conversation addMessageToCache:message];
            
            [self.delegate conversation:conversation didReceiveCommonMessage:message];
            
        }
        
    });
    
}

- (void)webSocketReceiveError:(NSNotification *)notification {
    
    dispatch_async(imClientQueue, ^{
       
        
        if (!self.delegate) {
            
            return;
        }
        
        if ([self.delegate respondsToSelector:@selector(imClientPaused:error:)]) {
            
            NSError *error = [notification.userInfo objectForKey:@"error"];
            
            dispatch_async(dispatch_get_main_queue(), ^{

                [self.delegate imClientPaused:self error:error];
                
            });
            
        } else if ([self.delegate respondsToSelector:@selector(imClientPaused:)]) {

            dispatch_async_on_main_queue(^{
               
                [self.delegate imClientPaused:self];
                
            });

        }
        
    });
    
}


- (USGConversationCacheStore *)conversationCacheStore {
    if (!_conversationCacheStore) {
        _conversationCacheStore = [USGConversationCacheStore conversationCacheStoreWithClientId:self.clientId];
    }
    return _conversationCacheStore;
}

@end
