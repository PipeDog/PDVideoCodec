//
//  PDMediaCodecBatchRequest.m
//  PDMediaCodec
//
//  Created by liang on 2021/1/22.
//

#import "PDMediaCodecBatchRequest.h"
#import "PDMediaCodecRequest.h"
#import "PDMediaCodecError.h"

@interface PDMediaCodecBatchRequestManager : NSObject

@end

@implementation PDMediaCodecBatchRequestManager {
    dispatch_semaphore_t _lock;
    NSMutableDictionary<PDMediaCodecRequestID, PDMediaCodecBatchRequest *> *_requestMap;
}

+ (instancetype)defaultManager {
    static PDMediaCodecBatchRequestManager *__defaultManager;
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

- (void)addRequest:(PDMediaCodecBatchRequest *)request {
    dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER);
    _requestMap[request.requestID] = request;
    dispatch_semaphore_signal(self->_lock);
}

- (void)removeRequest:(PDMediaCodecBatchRequest *)request {
    dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER);
    _requestMap[request.requestID] = nil;
    dispatch_semaphore_signal(self->_lock);
}

@end

@implementation PDMediaCodecBatchRequest

+ (instancetype)requestWithBuilder:(void (^)(id<PDMediaCodecBatchRequestBuilder> _Nonnull))block {
    PDMediaCodecBatchRequest *request = [[PDMediaCodecBatchRequest alloc] init];
    
    id<PDMediaCodecBatchRequestBuilder> builder = (id<PDMediaCodecBatchRequestBuilder>)request;
    !block ?: block(builder);
    
    NSAssert(builder.batchRequests, @"The property `srcURL` can not be nil!");
    return request;
}

- (instancetype)send {
    [self sendWithDoneHandler:nil];
    return self;
}

- (instancetype)sendWithDoneHandler:(PDMediaCodecBatchRequestBlock)doneHandler {
    [[PDMediaCodecBatchRequestManager defaultManager] addRequest:self];
    
    if (!self.batchRequests.count) {
        NSError *error = PDErrorWithDomain(PDCodecErrorDomain, PDInvalidArgumentErrorCode,
                                             @"You should set argument `batchRequest` before invoke `send` or `sendWithDoneHandler:` method!");
        !doneHandler ?: doneHandler(NO, @{@0: error}, nil, nil);
        [[PDMediaCodecBatchRequestManager defaultManager] removeRequest:self];
        NSAssert(NO, @"You should set argument `batchRequest` before invoke `send` or `sendWithDoneHandler:` method!");
        return self;
    }
    
    dispatch_group_t group = dispatch_group_create();
    NSMutableDictionary<NSNumber *, NSError *> *errorMap = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSNumber *, PDMediaCodecRequest *> *successRequestMap = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSNumber *, PDMediaCodecRequest *> *failedRequestMap = [NSMutableDictionary dictionary];

    NSUInteger requestCount = self.batchRequests.count;
    for (NSInteger i = 0; i < requestCount; i++) {
        PDMediaCodecRequest *request = self.batchRequests[i];
        
        dispatch_group_enter(group);
        [request sendWithDoneHandler:^(BOOL success, NSError * _Nullable error) {
            
            if (!success || error) {
                errorMap[@(i)] = error ?: PDErrorWithDomain(PDCodecErrorDomain, PDCodecFailedErrorCode, @"Unknown error type");
                failedRequestMap[@(i)] = request;
            } else {
                successRequestMap[@(i)] = request;
            }

            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        !doneHandler ?: doneHandler(!failedRequestMap.count,
                                    errorMap.count ? errorMap : nil,
                                    successRequestMap.count ? successRequestMap : nil,
                                    failedRequestMap.count ? failedRequestMap : nil);
        [[PDMediaCodecBatchRequestManager defaultManager] removeRequest:self];
    });
    
    return self;
}

- (void)cancel {
    for (PDMediaCodecRequest *request in self.batchRequests) {
        [request cancel];
    }
    
    [[PDMediaCodecBatchRequestManager defaultManager] removeRequest:self];
}

- (PDMediaCodecRequestID)requestID {
    PDMediaCodecRequestID requestID = [NSString stringWithFormat:@"%lu", (unsigned long)[self hash]];
    return requestID;
}

@end
