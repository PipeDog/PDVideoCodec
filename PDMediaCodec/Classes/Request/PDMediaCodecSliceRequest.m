//
//  PDMediaCodecSliceRequest.m
//  PDMediaCodec
//
//  Created by liang on 2021/1/23.
//

#import "PDMediaCodecSliceRequest.h"
#import "PDMediaSplitEngine.h"
#import "PDMediaCodecBatchRequest.h"
#import "PDMediaCodecRequest+Build.h"
#import "PDMediaCodecUtil.h"
#import "PDMediaCodecError.h"
#import "PDCodecDebugTool.h"

@interface PDMediaCodecSliceRequestManager : NSObject

@end

@implementation PDMediaCodecSliceRequestManager {
    dispatch_semaphore_t _lock;
    NSMutableDictionary<PDMediaCodecRequestID, PDMediaCodecSliceRequest *> *_requestMap;
}

+ (instancetype)defaultManager {
    static PDMediaCodecSliceRequestManager *__defaultManager;
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

- (void)addRequest:(PDMediaCodecSliceRequest *)request {
    dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER);
    _requestMap[request.requestID] = request;
    dispatch_semaphore_signal(self->_lock);
}

- (void)removeRequest:(PDMediaCodecSliceRequest *)request {
    dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER);
    _requestMap[request.requestID] = nil;
    dispatch_semaphore_signal(self->_lock);
}

@end

@interface PDMediaCodecSliceRequest ()

@property (nonatomic, strong) PDMediaCodecBatchRequest *batchRequest;
@property (nonatomic, strong) PDMediaCodecRequest *safeRequest;

@end

@implementation PDMediaCodecSliceRequest

#pragma mark - Class Methods
+ (dispatch_queue_t)splitQueueForRequest:(PDMediaCodecRequest *)request {
    static NSArray<dispatch_queue_t> *__splitQueues;
    static NSUInteger __splitQueueCount;
    static NSUInteger counter = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __splitQueues = @[
            dispatch_queue_create("com.media-split.queue[0]", DISPATCH_QUEUE_SERIAL),
            dispatch_queue_create("com.media-split.queue[1]", DISPATCH_QUEUE_SERIAL),
            dispatch_queue_create("com.media-split.queue[2]", DISPATCH_QUEUE_SERIAL),
        ];
        __splitQueueCount = [__splitQueues count];
    });
    return __splitQueues[counter++ % __splitQueueCount];
}

+ (dispatch_queue_t)mergeQueueForRequest:(PDMediaCodecRequest *)request {
    static NSArray<dispatch_queue_t> *__mergeQueues;
    static NSUInteger __mergeQueueCount;
    static dispatch_once_t onceToken;
    static NSUInteger counter = 0;
    dispatch_once(&onceToken, ^{
        __mergeQueues = @[
            dispatch_queue_create("com.media-merge.queue[0]", DISPATCH_QUEUE_SERIAL),
            dispatch_queue_create("com.media-merge.queue[1]", DISPATCH_QUEUE_SERIAL),
            dispatch_queue_create("com.media-merge.queue[2]", DISPATCH_QUEUE_SERIAL),
        ];
        __mergeQueueCount = [__mergeQueues count];
    });
    return __mergeQueues[counter++ % __mergeQueueCount];
}

#pragma mark - Override Methods
- (instancetype)send {
    return [self sendWithDoneHandler:nil];
}

- (instancetype)sendWithDoneHandler:(void (^)(BOOL, NSError * _Nullable))doneHandler {
    self.doneHandler = doneHandler;
    [[PDMediaCodecSliceRequestManager defaultManager] addRequest:self];
    
    [self executeSplitMediaResource];
    return self;
}

- (void)cancel {
    self.doneHandler = nil;
    [_batchRequest cancel];
    _batchRequest = nil;
    [_safeRequest cancel];
    _safeRequest = nil;
    [self deleteIntermediateFilesIfNeeded];
}

#pragma mark - Private Methods
- (void)executeSplitMediaResource {
    dispatch_queue_t splitQueue = [[self class] splitQueueForRequest:self];
    dispatch_async(splitQueue, ^{
        // Split media resource
        NSURL *originalSplitMediaDirURL = [self originalSplitMediaDirURL];        
        NSLog(@"[Codec][Split-Start] fileURL = %@", self.srcURL);
        [PDMediaSplitEngine splitMediaWithSourceURL:self.srcURL
                          toDestinationDirectoryURL:originalSplitMediaDirURL
                                      sliceDuration:30.f
                                        doneHandler:^(NSError * _Nullable error, NSArray<NSURL *> * _Nullable dstURLs) {
            NSLog(@"[Codec][Split-End] splitDir = %@", originalSplitMediaDirURL);
            if (error) {
                [self sendSafeCodecRequest];
                return;
            }
            
            [self sendBatchRequestWithDstURLs:dstURLs];
        }];
    });
}

- (void)sendBatchRequestWithDstURLs:(NSArray<NSURL *> *)dstURLs {
    // Transform URLs
    NSMutableArray *batchRequests = [NSMutableArray array];
    for (NSURL *dstURL in dstURLs) {
        [batchRequests addObject:[PDMediaCodecRequest requestWithBuilder:^(id<PDMediaCodecRequestBuilder>  _Nonnull builder) {
            builder.srcURL = dstURL;
            builder.dstURL = [self afterSplitMediaURL:dstURL];
        }]];
    }
    
    NSLog(@"[Codec][Codec-Start] srcURLs = %@", dstURLs);
    // Send batch request
    self.batchRequest = [[PDMediaCodecBatchRequest requestWithBuilder:^(id<PDMediaCodecBatchRequestBuilder>  _Nonnull builder) {
        builder.batchRequests = batchRequests;
    }] sendWithDoneHandler:^(BOOL success,
                             NEMediaCodecErrorMap  _Nullable errorMap,
                             PDMediaCodecRequestMap  _Nullable successRequestMap,
                             PDMediaCodecRequestMap  _Nullable failedRequestMap) {
        NSLog(@"[Codec][Codec-End] successMap = %@", successRequestMap);
        if (!success) {
            [self sendSafeCodecRequest];
            return;
        }
        
        // Package srcURLs
        NSMutableArray *srcURLs = [NSMutableArray array];
        NSUInteger count = batchRequests.count;
        
        for (NSInteger i = 0; i < count; i++) {
            PDMediaCodecRequest *request = successRequestMap[@(i)];
            if (request.dstURL) {
                [srcURLs addObject:request.dstURL];
                // [PDCodecDebugTool saveMediaToAlbumWithPath:request.dstURL.path];
            }
        }
        
        [self mergeMediaResourcesWithSrcURLs:srcURLs];
    }];
}

- (void)mergeMediaResourcesWithSrcURLs:(NSArray<NSURL *> *)srcURLs {
    // Merge all split media to `dstURL`
    dispatch_queue_t mergeQueue = [[self class] mergeQueueForRequest:self];
    dispatch_async(mergeQueue, ^{
        NSLog(@"[Codec][Merge-Start] srcURLs = %@", srcURLs);
        [PDMediaSplitEngine mergeMediasWithSourceURLs:srcURLs
                                     toDestinationURL:self.dstURL
                                          doneHandler:^(NSError * _Nullable error, NSURL * _Nonnull dstURL) {
            NSLog(@"[Codec][Merge-End] dstURL = %@", dstURL);
            if (error) {
                [self sendSafeCodecRequest];
                return;
            }
            
            [self notifyWithResult:YES error:nil];
            [self deleteIntermediateFilesIfNeeded];
            [[PDMediaCodecSliceRequestManager defaultManager] removeRequest:self];
        }];
    });
}

- (NSURL *)originalSplitMediaDirURL {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDir = [paths objectAtIndex:0];
    NSString *dirPath = [cachesDir stringByAppendingPathComponent:[NSString stringWithFormat:@"media-codec/split/original/%@/", self.requestID]];
    NSURL *dirURL = [NSURL fileURLWithPath:dirPath];
    return dirURL;
}

- (NSURL *)afterSplitMediaURL:(NSURL *)originalURL {
    NSString *path = originalURL.path;
    NSString *dstPath = [path stringByReplacingOccurrencesOfString:@"media-codec/split/original/" withString:@"media-codec/split/after/"];
    NSURL *dstURL = [NSURL fileURLWithPath:dstPath];
    return dstURL;
}

- (void)notifyWithResult:(BOOL)result error:(NSError *)error {
    PDDispatchOnMainQueue(^{
        !self.doneHandler ?: self.doneHandler(result, error);
        [[PDMediaCodecSliceRequestManager defaultManager] removeRequest:self];
    });
}

- (void)sendSafeCodecRequest {
    self.safeRequest = [[PDMediaCodecRequest requestWithBuilder:^(id<PDMediaCodecRequestBuilder>  _Nonnull builder) {
        builder.audioCodecAttr = self.audioCodecAttr;
        builder.videoCodecAttr = self.videoCodecAttr;
        builder.srcURL = self.srcURL;
        builder.dstURL = self.dstURL;
    }] sendWithDoneHandler:^(BOOL success, NSError * _Nullable error) {
        [self notifyWithResult:success error:error];
        [self deleteIntermediateFilesIfNeeded];
    }];
}

- (void)deleteIntermediateFilesIfNeeded {
    NSArray<PDMediaCodecRequest *> *batchRequests = _batchRequest.batchRequests;
    for (PDMediaCodecRequest *request in batchRequests) {
        [[NSFileManager defaultManager] removeItemAtPath:request.srcURL.path error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:request.dstURL.path error:nil];
    }
}

@end
