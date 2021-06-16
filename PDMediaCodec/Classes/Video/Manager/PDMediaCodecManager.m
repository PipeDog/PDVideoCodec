//
//  PDMediaCodecManager.m
//  PDMediaCodec
//
//  Created by liang: on 2021/1/21.
//

#import "PDMediaCodecManager.h"
#import "PDMediaCodecRequest.h"
#import "PDMediaCodecExecutor.h"
#import "PDMediaCodecQueue.h"

#define Lock() dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER)
#define Unlock() dispatch_semaphore_signal(self->_lock)

@interface PDMediaCodecManager ()

@property (nonatomic, strong) dispatch_semaphore_t lock;
@property (nonatomic, assign) NSUInteger maxConcurrentCodecCount;
@property (nonatomic, strong) NSMutableDictionary<PDMediaCodecRequestID, PDMediaCodecRequest *> *requestMap;
@property (nonatomic, strong) NSMutableDictionary<PDMediaCodecRequestID, PDMediaCodecExecutor *> *executorMap;
@property (nonatomic, strong) PDMediaCodecQueue *executingQueue;
@property (nonatomic, strong) PDMediaCodecQueue *waitingQueue;
@property (nonatomic, strong) dispatch_queue_t commitQueue;

@end

@implementation PDMediaCodecManager

static PDMediaCodecManager *__defaultManager;

+ (PDMediaCodecManager *)defaultManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (__defaultManager == nil) {
            __defaultManager = [[self alloc] init];
        }
    });
    return __defaultManager;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    @synchronized (self) {
        if (__defaultManager == nil) {
            __defaultManager = [super allocWithZone:zone];
        }
    }
    return __defaultManager;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _lock = dispatch_semaphore_create(1);
        _maxConcurrentCodecCount = [NSProcessInfo processInfo].activeProcessorCount;
        _requestMap = [NSMutableDictionary dictionary];
        _executorMap = [NSMutableDictionary dictionary];
        _executingQueue = [[PDMediaCodecQueue alloc] initWithName:@"com.codec-queue.executing"];
        _waitingQueue = [[PDMediaCodecQueue alloc] initWithName:@"com.codec-queue.waiting"];
        _commitQueue = dispatch_queue_create("com.codec-commit.queue", DISPATCH_QUEUE_SERIAL);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    Lock();
    NSArray<PDMediaCodecRequest *> *allRequests = [self.requestMap.allValues copy];
    Unlock();
    
    for (PDMediaCodecRequest *request in allRequests) {
        [request cancel];
    }
}

- (void)addRequest:(PDMediaCodecRequest *)request {
    if (!request.requestID) {
        NSAssert(NO, @"Invalid argument `request`, check it!");
        return;
    }
    
    Lock();
    PDMediaCodecExecutor *executor = self.executorMap[request.requestID];
    if (executor) { [executor cancel]; }
    
    BOOL shouldWaiting = self.executingQueue.count >= self.maxConcurrentCodecCount;
    Unlock();
    
    // Reaches maximum number count of concurrency.
    if (shouldWaiting) {
        Lock();
        [self.waitingQueue addRequest:request];
        Unlock();
        return;
    }
    
    executor = [[PDMediaCodecExecutor alloc] initWithRequest:request];
    
    Lock();
    [self.executingQueue addRequest:request];
    self.requestMap[request.requestID] = request;
    self.executorMap[request.requestID] = executor;
    Unlock();
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.commitQueue, ^{
        [weakSelf executeCodecByExecutor:executor forRequest:request];
    });
}

- (void)cancelRequest:(PDMediaCodecRequest *)request {
    if (!request.requestID) {
        NSAssert(NO, @"Invalid argument `request`, check it!");
        return;
    }
    
    Lock();
    PDMediaCodecExecutor *executor = self.executorMap[request.requestID];
    if (executor) { [executor cancel]; }
    
    [self.executingQueue removeRequest:request];
    [self.waitingQueue removeRequest:request];
    self.requestMap[request.requestID] = nil;
    self.executorMap[request.requestID] = nil;
    Unlock();
}

#pragma mark - Tool Methods
- (void)executeCodecByExecutor:(PDMediaCodecExecutor *)executor forRequest:(PDMediaCodecRequest *)request {
    NSLog(@"[Codec][RealCodec-Start] srcURL = %@", request.srcURL);
    
    __weak typeof(self) weakSelf = self;
    [executor executeWithDoneHandler:^(BOOL success, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        
        NSLog(@"[Codec][RealCodec-End] srcURL = %@", request.srcURL);
        
        Lock();
        [strongSelf.executingQueue removeRequest:request];
        strongSelf.requestMap[request.requestID] = nil;
        strongSelf.executorMap[request.requestID] = nil;
        
        PDMediaCodecRequest *nextRequest = strongSelf.waitingQueue.popHeadRequest;
        Unlock();
        
        if (!nextRequest) { return; }
        [strongSelf addRequest:nextRequest];
    }];
}

#pragma mark - Setter Methods
- (void)setMaxConcurrentCodecCount:(NSUInteger)maxConcurrentCodecCount {
    Lock();
    _maxConcurrentCodecCount = maxConcurrentCodecCount;
    Unlock();
}

@end
