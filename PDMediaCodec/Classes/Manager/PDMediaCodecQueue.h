//
//  PDMediaCodecQueue.h
//  PDMediaCodec
//
//  Created by liang on 2021/1/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PDMediaCodecRequest;

/// @class PDMediaCodecQueue
/// @brief 媒体资源编码队列
@interface PDMediaCodecQueue : NSObject

@property (nonatomic, strong, readonly) NSString *name;

- (instancetype)initWithName:(NSString * _Nullable)name NS_DESIGNATED_INITIALIZER;

- (void)addRequest:(PDMediaCodecRequest *)request;
- (void)removeRequest:(PDMediaCodecRequest *)request;
- (BOOL)containsRequest:(PDMediaCodecRequest *)request;
- (PDMediaCodecRequest * _Nullable)popHeadRequest;
- (void)removeAllRequests;
- (NSUInteger)count;

@end

NS_ASSUME_NONNULL_END
