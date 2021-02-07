//
//  PDAudioCodecBatchRequestManager.m
//  PDMediaCodec
//
//  Created by liang on 2021/2/7.
//

#import "PDAudioCodecBatchRequestManager.h"
#import "PDAudioCodecBatchRequest.h"

@implementation PDAudioCodecBatchRequestManager {
    dispatch_semaphore_t _lock;
    NSMutableDictionary<PDAudioCodecRequestID, PDAudioCodecBatchRequest *> *_requestMap;
}

+ (instancetype)defaultManager {
    static PDAudioCodecBatchRequestManager *__defaultManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __defaultManager = [[self alloc] init];
    });
    return __defaultManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _lock = dispatch_semaphore_create(1);
        _requestMap = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addRequest:(PDAudioCodecBatchRequest *)request {
    dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER);
    _requestMap[request.requestID] = request;
    dispatch_semaphore_signal(self->_lock);
}

- (void)removeRequest:(PDAudioCodecBatchRequest *)request {
    dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER);
    _requestMap[request.requestID] = nil;
    dispatch_semaphore_signal(self->_lock);
}

@end
