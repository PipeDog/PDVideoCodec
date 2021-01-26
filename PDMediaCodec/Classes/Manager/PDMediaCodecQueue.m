//
//  PDMediaCodecQueue.m
//  PDMediaCodec
//
//  Created by liang on 2021/1/22.
//

#import "PDMediaCodecQueue.h"
#import "PDMediaCodecRequest.h"

@implementation PDMediaCodecQueue {
    NSMutableArray<PDMediaCodecRequest *> *_requests;
}

- (instancetype)init {
    return [self initWithName:nil];
}

- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        _name = [name copy];
        _requests = [NSMutableArray array];
    }
    return self;
}

- (void)addRequest:(PDMediaCodecRequest *)request {
    [_requests addObject:request];
}

- (void)removeRequest:(PDMediaCodecRequest *)request {
    [_requests removeObject:request];
}

- (BOOL)containsRequest:(PDMediaCodecRequest *)request {
    return [_requests containsObject:request];
}

- (PDMediaCodecRequest *)popHeadRequest {
    PDMediaCodecRequest *request = _requests.firstObject;
    if (request) { [_requests removeObjectAtIndex:0]; }
    return request;
}

- (void)removeAllRequests {
    [_requests removeAllObjects];
}

- (NSUInteger)count {
    NSUInteger count = _requests.count;
    return count;
}

@end
