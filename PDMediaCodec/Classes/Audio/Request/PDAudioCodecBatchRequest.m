//
//  PDAudioCodecBatchRequest.m
//  PDMediaCodec
//
//  Created by liang on 2021/2/1.
//

#import "PDAudioCodecBatchRequest.h"
#import "PDAudioCodecRequest.h"
#import "PDMediaCodecError.h"

@interface PDAudioCodecBatchRequestManager : NSObject

@end

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

@implementation PDAudioCodecBatchRequest

+ (instancetype)requestWithBuilder:(void (^)(id<PDAudioCodecBatchRequestBuilder> _Nonnull))block {
    PDAudioCodecBatchRequest *request = [[PDAudioCodecBatchRequest alloc] init];
    
    id<PDAudioCodecBatchRequestBuilder> builder = (id<PDAudioCodecBatchRequestBuilder>)request;
    !block ?: block(builder);
    
    NSAssert(builder.batchRequests, @"The property `srcURL` can not be nil!");
    return request;
}

- (instancetype)send {
    [self sendWithDoneHandler:nil];
    return self;
}

- (instancetype)sendWithDoneHandler:(PDAudioCodecBatchRequestBlock)doneHandler {
    [[PDAudioCodecBatchRequestManager defaultManager] addRequest:self];
    
    if (!self.batchRequests.count) {
        NSError *error = PDErrorWithDomain(PDCodecErrorDomain, PDInvalidArgumentErrorCode,
                                           @"You should set argument `batchRequest` before invoke `send` or `sendWithDoneHandler:` method!");
        !doneHandler ?: doneHandler(NO, @{@0: error}, nil, nil);
        [[PDAudioCodecBatchRequestManager defaultManager] removeRequest:self];
        NSAssert(NO, @"You should set argument `batchRequest` before invoke `send` or `sendWithDoneHandler:` method!");
        return self;
    }
    
    dispatch_group_t group = dispatch_group_create();
    NSMutableDictionary<NSNumber *, NSError *> *errorMap = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSNumber *, PDAudioCodecRequest *> *successRequestMap = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSNumber *, PDAudioCodecRequest *> *failedRequestMap = [NSMutableDictionary dictionary];
    
    NSUInteger requestCount = self.batchRequests.count;
    for (NSInteger i = 0; i < requestCount; i++) {
        PDAudioCodecRequest *request = self.batchRequests[i];
        
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
        [[PDAudioCodecBatchRequestManager defaultManager] removeRequest:self];
    });
    
    return self;
}

- (void)cancel {
    for (PDAudioCodecRequest *request in self.batchRequests) {
        [request cancel];
    }
    
    [[PDAudioCodecBatchRequestManager defaultManager] removeRequest:self];
}

- (PDAudioCodecRequestID)requestID {
    PDAudioCodecRequestID requestID = [NSString stringWithFormat:@"%lu", (unsigned long)[self hash]];
    return requestID;
}

@end
