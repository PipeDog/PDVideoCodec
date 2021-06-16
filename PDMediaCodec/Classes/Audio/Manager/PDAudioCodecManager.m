//
//  PDAudioCodecManager.m
//  PDMediaCodec
//
//  Created by liang on 2021/2/1.
//

#import "PDAudioCodecManager.h"
#import "PDAudioCodecRequest.h"
#import "PDMediaCodecError.h"
#import "PDAudioCodec2MP3Operation.h"
#import "PDMediaCodecUtil.h"

#define Lock() dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER)
#define Unlock() dispatch_semaphore_signal(self->_lock)

@interface PDAudioCodecManager () <PDAudioCodecOperationDelegate>

@property (nonatomic, strong) dispatch_semaphore_t lock;
@property (nonatomic, strong) NSOperationQueue *codecQueue;
@property (nonatomic, strong) NSMutableDictionary<PDAudioCodecRequestID, PDAudioCodecRequest *> *requestMap;
@property (nonatomic, strong) NSMutableDictionary<PDAudioCodecRequestID, PDAudioCodecOperation *> *operationMap;

@end

@implementation PDAudioCodecManager

static PDAudioCodecManager *__defaultManager;

+ (PDAudioCodecManager *)defaultManager {
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

- (instancetype)init {
    self = [super init];
    if (self) {
        _lock = dispatch_semaphore_create(1);
        _codecQueue = [[NSOperationQueue alloc] init];
        _codecQueue.maxConcurrentOperationCount =
                        [NSProcessInfo processInfo].activeProcessorCount;
        _requestMap = [NSMutableDictionary dictionary];
        _operationMap = [NSMutableDictionary dictionary];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

- (void)addRequest:(PDAudioCodecRequest *)request {
    if (!request.requestID) {
        NSAssert(NO, @"Invalid argument `request`, check it!");
        return;
    }
    
    PDAudioCodecOperation *operation = [self operationForRequest:request];
    
    if (!operation) {
        NSError *error = PDErrorWithDomain(PDCodecErrorDomain,
                                           PDInvalidArgumentErrorCode,
                                           @"Unsupport file type for request %@!", request);
        PDDispatchOnMainQueue(^{
            !request.doneHandler ?: request.doneHandler(NO, error);
        });
        return;
    }
    
    Lock();
    self.requestMap[request.requestID] = request;
    self.operationMap[request.requestID] = operation;
    Unlock();
    
    [self.codecQueue addOperation:operation];
}

- (void)cancelRequest:(PDAudioCodecRequest *)request {
    if (!request.requestID) {
        NSAssert(NO, @"Invalid argument `request`, check it!");
        return;
    }
    
    Lock();
    PDAudioCodecOperation *operation = self.operationMap[request.requestID];
    self.operationMap[request.requestID] = nil;
    self.requestMap[request.requestID] = nil;
    Unlock();
    
    [operation cancel];
}

- (void)cancenAllRequests {
    Lock();
    NSArray<PDAudioCodecRequest *> *allRequests = [self.requestMap allValues];
    Unlock();
    
    for (PDAudioCodecRequest *request in allRequests) {
        [self cancelRequest:request];
    }
}

#pragma mark - Setter Methods
- (void)setMaxConcurrentCodecCount:(NSInteger)maxConcurrentCodecCount {
    Lock();
    _codecQueue.maxConcurrentOperationCount = maxConcurrentCodecCount;
    Unlock();
}

#pragma mark - Private Methods
- (void)applicationWillResignActive:(NSNotification *)notification {
    [self cancenAllRequests];
}

- (PDAudioCodecOperation *)operationForRequest:(PDAudioCodecRequest *)request {
    if ([request.outputFileType isEqualToString:NEAudioFileTypeMP3]) {
        return [[PDAudioCodec2MP3Operation alloc] initWithRequest:request delegate:self];
    }
    
    // TODO: 补充不同文件类型转码
    NSAssert(NO, @"Unsupport file type!");
    return nil;
}

#pragma mark - PDAudioCodecOperationDelegate
- (void)operationDidFinishCodec:(PDAudioCodecOperation *)operation {
    PDAudioCodecRequest *request = operation.request;
    
    Lock();
    self.requestMap[request.requestID] = nil;
    self.operationMap[request.requestID] = nil;
    Unlock();
}

- (void)operation:(PDAudioCodecOperation *)operation didFailCodecWithError:(NSError *)error {
    PDAudioCodecRequest *request = operation.request;
    
    Lock();
    self.requestMap[request.requestID] = nil;
    self.operationMap[request.requestID] = nil;
    Unlock();
}

@end
