//
//  USGIMSocketWrapper.m
//  BTYxyz
//
//  Created by ForKid on 2018/3/23.
//  Copyright © 2018年 CDBottle. All rights reserved.
//

#import "USGIMSocketWrapper.h"

#if __has_include(<SocketRocket/SocketRocket.h>)
#import <SocketRocket/SocketRocket.h>
#else
#import "SocketRocket/SocketRocket.h"
#endif

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking/AFNetworking.h"
#endif

#if __has_include(<YYKit/YYKit.h>)
#import <YYKit/YYKit.h>
#else
#import "YYKit/YYKit.h"
#endif

#import "NSError+USGIM.h"
#import "USGIMRouter.h"
#import "USGIMBasicCommand.h"
#import "USGIMMessage.h"


//MARK: - notificationName define

///< socket已连接通知
NSNotificationName const kUSGIMSocketOpenedNotificationName = @"com.USGIM.notificatioName.opened";

///< socket已关闭通知
NSNotificationName const kUSGIMSocketClosedNotificationName = @"com.USGIM.notificatioName.closed";

///< socket重连通知
NSNotificationName const kUSGIMSocketReconnectNotificationName = @"com.USGIM.notificatioName.reconnect";

///< socket发生错误通知
NSNotificationName const kUSGIMSocketErrorNotificationName = @"com.USGIM.notificatioName.error";

///< socket收到消息通知
NSNotificationName const kUSGIMSocketMessageNotificationName = @"com.USGIM.notificatioName.message";



//MARK: - const define

///< 心跳包发送间隔
NSTimeInterval const kPingTimeInterval = 30 * 1;

///< 超时时间值
NSTimeInterval const kTimeoutCheckInterval = 1.f;

///< 默认超时时间
NSTimeInterval const kSocketDefaultTimeoutInterval = 30.f;

//MARK: - Wrapper class

@interface USGIMSocketWrapper ()<SRWebSocketDelegate> {
    
    ///< 超时时长 默认为30s ， checkTimeoutTimer会在发送ping后每秒监测一次pong 如果超过该值，则会提示超时
    NSTimeInterval _timeout;
    
    ///< 只调用一次，调用open方法后变为YES，调用close之后为NO，中间不会发生改变
    BOOL _invokedOpenOnce;
    
    ///< 当前应用程勋是否在后台运行
    BOOL _isApplicationEnteredBackground;
    
    ///< 上一次发送ping的时间
    NSTimeInterval _lastPingTimestamp;
    ///< 未收到pong消息的ping数量, 每次发送ping该值+1，收到pong -1
    int _countOfSendPingWithoutReceivePong;
    
    //reconnect
    ///< 是否需要重连，wrapper初始化时为NO，在建立连接成功后为YES
    BOOL _needReconnect;
    ///< 重连时间间隔(每次 * 2)，连接成功后重置 默认为1s
    NSTimeInterval _reconnectInterval;
    ///< 连接（重连）成功后的block回调
    dispatch_block_t _reconnectBlock;
    
    ///< socket线程
    dispatch_queue_t _serialQueue;
    
    ///< 保存当前所有正在连接（包括重连）的回调
    NSMutableArray <USGIMBooleanCallback> *_openBlockArray;
    
    ///< socket对象 真正用于通信的实例
    SRWebSocket *_webSocket;
    
    ///< 网络状态监测
    AFNetworkReachabilityManager *_networkReachabilityManager;
    
    ///< 当前的网络状态 初始化时为unknown
    AFNetworkReachabilityStatus _oldNetworkStatus;
    
    __weak NSTimer *_pingTimer;
    __weak NSTimer *_checkTimeoutTimer;
}

@end

@implementation USGIMSocketWrapper

//MARK: - life cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        
        _timeout = kSocketDefaultTimeoutInterval;
        
        _invokedOpenOnce = NO;
        
        
#if TARGET_OS_IOS
        
        UIApplicationState state = [UIApplication sharedApplication].applicationState;
        
        _isApplicationEnteredBackground = (state == UIApplicationStateBackground);
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationWillEnterBackgroundFounction) name:UIApplicationDidEnterBackgroundNotification object:nil];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationWillEnterForegroundFounction) name:UIApplicationWillEnterForegroundNotification object:nil];
        
#endif
        
        _openBlockArray = [NSMutableArray new];
        
        _lastPingTimestamp = -1.f;
        
        _needReconnect = NO;
        _reconnectInterval = 1.f;
        _countOfSendPingWithoutReceivePong = 0;
        _reconnectBlock = nil;
        
        _webSocket = nil;
        
        //第二个参数可以传NULL（等价DISPATCH_QUEUE_SERIAL）
        _serialQueue = dispatch_queue_create("com.USGIM.queue.serial", DISPATCH_QUEUE_SERIAL);
        
        
        _networkReachabilityManager = [AFNetworkReachabilityManager manager];
        
        _oldNetworkStatus = AFNetworkReachabilityStatusUnknown;
        
        __weak typeof(self) weak_self_ = self;
        
        [_networkReachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
           
            __strong USGIMSocketWrapper *strong_self_ = weak_self_;
            
            if (!strong_self_) {
                return;
            }
            
            dispatch_async(strong_self_->_serialQueue, ^{
                [strong_self_ handleForNetworkStatusChanged:status];
            });
            
        }];
        
        [_networkReachabilityManager startMonitoring];
        
        //初始化定时器
                
        _pingTimer = [self timerWithInterval:kPingTimeInterval
                                      action:@selector(sendPing)];
        
        _checkTimeoutTimer = [self timerWithInterval:kTimeoutCheckInterval
                                              action:@selector(checkTimeout)];

    }
    return self;
}


- (void)dealloc {
    [self distoryAllTimer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


//MARK: - public function


//MARK: - 建立链接
- (void)openWithCallback:(USGIMBooleanCallback)callback {
    
    dispatch_async(_serialQueue, ^{
       
        NSString *errorReason = nil;
        
        if (self->_isApplicationEnteredBackground) {
            
            errorReason = @"Can't open WebSocket when Application in Background.";
            
        } else if (self->_oldNetworkStatus == AFNetworkReachabilityStatusNotReachable) {
            
            errorReason = @"Can't open WebSocket when Network is Not Reachable.";
        }
        
        if (errorReason) {
            
            NSError *error = [NSError errorWithCode:0 reason:errorReason];
            
            if (callback) {
                callback(NO, error);
            }
            
            return;
        }
        
        self->_invokedOpenOnce = YES;
        
        [self _openWithCallback:callback blockBeforeOpen:NULL];
        
    });
    
}

- (void)_openWithCallback:(USGIMBooleanCallback)callback
          blockBeforeOpen:(void(^)(void))block {
    
    //取消正在执行的重连回调
    [self cancelReconnectBlock];
    
    /**
     * 判断是否处于可连接状态
     * 如果invokedOnce为NO,即表示没有执行过open方法
     */
    if (!_invokedOpenOnce ||
        _isApplicationEnteredBackground ||
        _oldNetworkStatus == AFNetworkReachabilityStatusNotReachable) {
        return;
    }
    
    SRWebSocket *webSocket = _webSocket;
    
    //如果当前已存在socket实例对象 判断
    if (webSocket) {
        
        SRReadyState readyState = webSocket.readyState;
        
        if (readyState == SR_OPEN) {
            if (callback) {
                callback(YES, nil);
            }
            return;
        }
        
        if (readyState == SR_CONNECTING) {
            
            if (callback && [_openBlockArray containsObject:callback] == NO) {
                [_openBlockArray addObject:callback];
            }
            
            return;
        }
        
    }
    
    if (callback && [_openBlockArray containsObject:callback] == NO) {
        [_openBlockArray addObject:callback];
    }
    
    if (block) {
        block();
    }

    [self getWebSocketServerURLString];
    
}


- (void)getWebSocketServerURLString {
    
    if (USGIMRouter.sharedRouter.serverTable[kUSGIMServerRouterURLNameKey]) {
        
        NSString *server = USGIMRouter.sharedRouter.serverTable[kUSGIMServerRouterURLNameKey];
        
        [self createWebSocketAndConnectWithServer:server];
        
    } else {
        
        [USGIMRouter.sharedRouter fetchWebSocketServerInbackgroundWithCompletionHandler:^(NSString * _Nullable webSocketServer, NSError * _Nullable error) {
           
            if (error) {
                NSLog(@"未获取到socket连接");
                return;
            }
            
            [self createWebSocketAndConnectWithServer:webSocketServer];
            
        }];
        
    }
    
}

//MARK: - 断开连接

- (void)close {
    
    dispatch_async(_serialQueue, ^{
       
        self->_invokedOpenOnce = NO;
        
        [self _closeWithBlockAfterClose:NULL];
        
    });
    
}

- (void)_closeWithBlockAfterClose:(void(^)(void))block {
    
    [self cancelReconnectBlock];
    
    _needReconnect = NO;
    
    _reconnectInterval = 1.f;
    
    [self stopPingTimer];
    
    [self stopCheckTimeoutTimer];
    
    if (_webSocket) {
        
        [self distoryWebSocketWithShouldClose:YES];
        
        if (block) {
            block();
        }
        
    }
}


//MARK: - 发送消息
- (void)send:(USGIMBasicCommand *)command callback:(USGIMBooleanCallback)callback{
    
    dispatch_async(_serialQueue, ^{
        
        NSData *data = [command contentData];
       
        [self _sendMessage:data callback:callback];
        
    });
}

- (void)_sendMessage:(NSData *)message callback:(USGIMBooleanCallback)callback{
    
    if (!message || message.length == 0) {
        
        return;
        
    }
    
    SRWebSocket *webSocket = _webSocket;
    
    if (!webSocket || webSocket.readyState != SR_OPEN) {
        
        NSString *reason = @"Websocket Not Connected.";

        NSError *error = [NSError errorWithCode:1 reason:reason];
        
        if (callback) {
            callback(NO, error);
        }
        
        return;
    }
    
    if ([message respondsToSelector:@selector(length)]) {
        
        NSInteger length = message.length;
        
        if (length > 5000) {
        
            NSString *reason = @"the data is too big";
        
            NSError *error = [NSError errorWithCode:2 reason:reason];
            
            if (callback) {
                callback(NO, error);
            }
            
            return;
        
        }
    }
    
    [_webSocket send:message];
    
    if (callback) {
        callback(YES, nil);
    }
}


//MARK: - private function


//MARK: - 创建webSocket实例

- (void)createWebSocketAndConnectWithServer:(NSString *)server {
    
    [self distoryWebSocketWithShouldClose:YES];
    
    NSURL *url = [NSURL URLWithString:server];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    SRWebSocket *webSocket = [[SRWebSocket alloc] initWithURLRequest:request];
 
    [webSocket setDelegateDispatchQueue:_serialQueue];
    
    webSocket.delegate = self;
    
    _webSocket = webSocket;
    
    [webSocket open];

}

//MARK: - 销毁webSocket实例

/**
 销毁WebSocket实例对象

 @param shouldClose 是否需要调用close方法
 */
- (void)distoryWebSocketWithShouldClose:(BOOL)shouldClose {
    
    if (_webSocket) {
        _webSocket.delegate = nil;
        if (shouldClose) {
            [_webSocket close];
        }
        _webSocket = nil;
    }
}

//MARK: - 取消重连回调
- (void)cancelReconnectBlock{
 
    if (_reconnectBlock) {
        
        dispatch_block_cancel(_reconnectBlock);
        
        _reconnectBlock = nil;
    }
    
}

//MARK: - 处理应用程序进入后台

- (void)applicationWillEnterBackgroundFounction {
    
    NSLog(@"后台");

    dispatch_async(_serialQueue, ^{
        
        self->_isApplicationEnteredBackground = YES;
        
        if (self->_invokedOpenOnce) {
            
            [self _closeWithBlockAfterClose:^{
                
                NSString *reason = @"Application is in Background.";
                
                NSError *error = [NSError errorWithCode:0 reason:reason];
                
                if (self->_openBlockArray.count > 0) {
                    
                    [self invokeAllOpenCallbackWithBoolValue:NO error:error];
                    
                } else {
                    
                    [self postNotificationName:kUSGIMSocketClosedNotificationName
                                         error:error];
                }
                
            }];
        }
        
    });
}

//MARK: 应用程序进入前台
- (void)applicationWillEnterForegroundFounction {
    
    NSLog(@"前台");
    
    dispatch_async(_serialQueue, ^{
       
        self->_isApplicationEnteredBackground = NO;
        
        if (self->_invokedOpenOnce) {
            
            [self _openWithCallback:NULL blockBeforeOpen:^{
               
                [self postNotificationName:kUSGIMSocketReconnectNotificationName
                                     error:nil];
                
            }];
            
        }
        
    });
    
}

//MARK: - 监测网络状态变化

- (void)handleForNetworkStatusChanged:(AFNetworkReachabilityStatus)newStatus {
    
    AFNetworkReachabilityStatus oldStatus = _oldNetworkStatus;
    
    BOOL isOldStatusNormal = (
                              (oldStatus == AFNetworkReachabilityStatusReachableViaWWAN) ||
                              (oldStatus == AFNetworkReachabilityStatusReachableViaWiFi)
                              );
    
    BOOL isOldStatusNotReachable = (oldStatus == AFNetworkReachabilityStatusNotReachable);
    
    BOOL isNewStatusNormal = (
                              (newStatus == AFNetworkReachabilityStatusReachableViaWWAN) ||
                              (newStatus == AFNetworkReachabilityStatusReachableViaWiFi)
                              );
    
    BOOL isNewStatusNotReachable = (newStatus == AFNetworkReachabilityStatusNotReachable);
    
    //不可用->可用
    if (isNewStatusNormal && isOldStatusNotReachable) {
        
        _oldNetworkStatus = newStatus;
        
        if (_invokedOpenOnce) {
            
            [self _openWithCallback:NULL blockBeforeOpen:^{
               
                [self postNotificationName:kUSGIMSocketReconnectNotificationName
                                     error:nil];
                
            }];
            
        }
        
    }
    
    //可用-> 不可用
    else if (isNewStatusNotReachable && isOldStatusNormal) {
        
        _oldNetworkStatus = newStatus;
        
        if (_invokedOpenOnce) {
            
            [self _closeWithBlockAfterClose:^{
               
                NSString *reason = @"Network is Not Reachable.";
   
                NSError *error = [NSError errorWithCode:0 reason:reason];
                
                if (self->_openBlockArray.count > 0) {
                    
                    [self invokeAllOpenCallbackWithBoolValue:NO error:error];
                    
                } else {
                    
                    [self postNotificationName:kUSGIMSocketClosedNotificationName
                                         error:error];
                }
                
                
            }];
            
        }
        
    }
    
    //可用->可用(一般用于在网络环境切换中，比如WiFi->WLAN, WLAN - WiFi)
    else if (isNewStatusNormal && isOldStatusNormal) {
        
        _oldNetworkStatus = newStatus;
        
    }
    
    if (_oldNetworkStatus == AFNetworkReachabilityStatusUnknown &&
        newStatus != AFNetworkReachabilityStatusUnknown) {
        
        _oldNetworkStatus = newStatus;
    }
}

//MARK: - 连接成功后调用所有的回调方法 然后清空
- (void)invokeAllOpenCallbackWithBoolValue:(BOOL)boolValue
                                     error:(NSError *)error {
    
    for (USGIMBooleanCallback block in _openBlockArray) {
        
        block(boolValue, error);
        
    }
    
    [_openBlockArray removeAllObjects];
}

//发送通知消息
- (void)postNotificationName:(NSNotificationName)name
                       error:(NSError *)error {
    
    NSDictionary *userInfo = nil;
    
    if (error) {
        userInfo = @{ @"error" : error };
    }
    
    [NSNotificationCenter.defaultCenter postNotificationName:name
                                                      object:self
                                                    userInfo:userInfo];
}

//MARK: websocket关闭连接
- (void)handleWebSocketClosedWithError:(NSError *)error {
    
    [self distoryWebSocketWithShouldClose:NO];
    
    [self stopAllTimer];

}

//MARK: - 重新连接


/**
 * 重连时会取消当前正在执行的重连回调方法
 * 然后会在一定时间后执行重连方法
 * 并且发送重连通知
 */
- (void)setupReconnectBlock {
    
    NSLog(@"尝试重连中");
    
    [self cancelReconnectBlock];
    
    __weak typeof(self) weak_self_ = self;
    
    _reconnectBlock = dispatch_block_create(0, ^{
       
        [weak_self_ cancelReconnectBlock];
        
        [weak_self_ _openWithCallback:NULL blockBeforeOpen:NULL];
        
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_reconnectInterval * NSEC_PER_SEC)), _serialQueue, _reconnectBlock);
    
    _reconnectInterval *= 2;
    
    [self postNotificationName:kUSGIMSocketReconnectNotificationName
                         error:nil];
    
}



//Timer


- (NSTimer *)timerWithInterval:(NSTimeInterval)interval action:(SEL)action {
    
    YYWeakProxy *proxy = [YYWeakProxy proxyWithTarget:self];
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:interval target:proxy selector:action userInfo:nil repeats:YES];
    
    timer.fireDate = NSDate.distantFuture;
    
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    
    return timer;
}

- (void)startPingTimer {
    
    [self stopPingTimer];
    
    _pingTimer.fireDate = NSDate.distantPast;
    
}

- (void)stopPingTimer {
    
    _pingTimer.fireDate = NSDate.distantFuture;
    
    _lastPingTimestamp = -1.f;
    
    _countOfSendPingWithoutReceivePong = 0;
    
}

- (void)startCheckTimeoutTimer {
    [self stopCheckTimeoutTimer];
    _checkTimeoutTimer.fireDate = NSDate.distantPast;
}

- (void)stopCheckTimeoutTimer {
    _checkTimeoutTimer.fireDate = NSDate.distantFuture;
}


- (void)sendPing {
    
    NSLog(@"即将发送心跳包");
    
    SRWebSocket *webSocket = _webSocket;
    
    if (!webSocket || webSocket.readyState != SR_OPEN) {
        return;
    }
    
    _lastPingTimestamp = [NSDate.date timeIntervalSince1970];
    
    _countOfSendPingWithoutReceivePong += 1;
    
    NSData *pingData = [@"" dataUsingEncoding:NSUTF8StringEncoding];
    
    [webSocket sendPing:pingData];
    
    NSLog(@"发送心跳包完成");
    
}

- (void)checkTimeout {
    
    NSTimeInterval now = NSDate.date.timeIntervalSince1970;
    
    NSTimeInterval deltaInterval = now - _lastPingTimestamp;
    
    if (_lastPingTimestamp > 0 && _countOfSendPingWithoutReceivePong > 0 && deltaInterval > _timeout) {
        
        /**
         允许3次的超时，如果超过3次，则触发断开操作
         */
        if (_countOfSendPingWithoutReceivePong >= 3) {
            
            [self _closeWithBlockAfterClose:^{
               
                NSString *reason = @"WebSocket Ping Timeout.";
                
                NSError *aError = [NSError errorWithCode:0 reason:reason];
                
                [self postNotificationName:kUSGIMSocketClosedNotificationName
                                     error:aError];
            }];
            
            [self _openWithCallback:NULL blockBeforeOpen:^{
                
                [self postNotificationName:kUSGIMSocketReconnectNotificationName
                                     error:nil];
                
            }];
            
        } else {
            
            [self sendPing];
            
        }
        
    }
    
}

- (void)startAllTimer {
    //启用timer
    [self startPingTimer];
    [self startCheckTimeoutTimer];
}

- (void)stopAllTimer {
    [self stopPingTimer];
    [self stopCheckTimeoutTimer];
}

- (void)distoryAllTimer {
    [_pingTimer invalidate];
    [_checkTimeoutTimer invalidate];
    _pingTimer = nil;
    _checkTimeoutTimer = nil;
}

//MARK: delegate


///< 收到消息
- (void)webSocketDidOpen:(SRWebSocket *)webSocket {

    NSLog(@"已建立连接");
    
    //重置重连时间
    _reconnectInterval = 1.f;
    
    _needReconnect = YES;

    //启用timer
    [self startAllTimer];
    
    //判断是否是首次打开
    if (_openBlockArray.count > 0) {
        
        //执行回调
        [self invokeAllOpenCallbackWithBoolValue:YES error:nil];
        
    } else {
        
        [self postNotificationName:kUSGIMSocketOpenedNotificationName
                             error:nil];
        
    }
    
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    
    NSLog(@"连接失败");
    
    [self handleWebSocketClosedWithError:error];
    
    if (_openBlockArray.count > 0) {
        
        [self invokeAllOpenCallbackWithBoolValue:NO
                                           error:error];
        
    } else {
        
        [self postNotificationName:kUSGIMSocketErrorNotificationName
                             error:error];
        
    }
    
    if (_needReconnect) {
        
        [self setupReconnectBlock];
        
    }
    
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code
           reason:(NSString *)reason wasClean:(BOOL)wasClean {
    
    NSLog(@"关闭了");
    
    NSError *error = [NSError errorWithCode:code reason:reason];
    
    [self handleWebSocketClosedWithError:error];
    
    if (_openBlockArray.count > 0) {
     
        [self invokeAllOpenCallbackWithBoolValue:NO error:error];
    
    } else {
        
        [self postNotificationName:kUSGIMSocketClosedNotificationName
                             error:error];
        
        if (_needReconnect) {
            
            [self setupReconnectBlock];
            
        }
    }
}


- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    
    NSData *data = (NSData *)message;
    
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    USGIMMessage *IMMessage = [USGIMMessage messageWithContent:string];
    
    [NSNotificationCenter.defaultCenter postNotificationName:kUSGIMSocketMessageNotificationName
                                                      object:self
                                                    userInfo:@{ @"command" : IMMessage }];
    
}


- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload {
    NSLog(@"收到心跳包");
    _countOfSendPingWithoutReceivePong = 0;
}


- (BOOL)webSocketShouldConvertTextFrameToString:(SRWebSocket *)webSocket {
    return YES;
}


//MARK: - getter

//MAEK: - setter


@end
