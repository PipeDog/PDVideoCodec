//
//  PDMediaCodecBatchRequest.h
//  PDMediaCodec
//
//  Created by liang on 2021/1/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PDMediaCodecRequest;

typedef NSString * PDMediaCodecRequestID;
typedef NSNumber * PDMediaCodecRequestIndex;
typedef NSDictionary<PDMediaCodecRequestIndex, NSError *> * NEMediaCodecErrorMap;
typedef NSDictionary<PDMediaCodecRequestIndex, PDMediaCodecRequest *> * PDMediaCodecRequestMap;

typedef void (^PDMediaCodecBatchRequestBlock)(BOOL success,
                                              NEMediaCodecErrorMap _Nullable errorMap,
                                              PDMediaCodecRequestMap _Nullable successRequestMap,
                                              PDMediaCodecRequestMap _Nullable failedRequestMap);

@protocol PDMediaCodecBatchRequestBuilder <NSObject>

@property (nonatomic, copy) NSArray<PDMediaCodecRequest *> *batchRequests;

@end

/// @class PDMediaCodecBatchRequest
/// @brief 处理批量编码场景
@interface PDMediaCodecBatchRequest : NSObject

@property (nonatomic, copy) NSArray<PDMediaCodecRequest *> *batchRequests;

+ (instancetype)requestWithBuilder:(void (^)(id<PDMediaCodecBatchRequestBuilder> builder))block;

- (instancetype)send;
- (instancetype)sendWithDoneHandler:(PDMediaCodecBatchRequestBlock _Nullable)doneHandler;

- (void)cancel;
- (PDMediaCodecRequestID)requestID;

@end

NS_ASSUME_NONNULL_END
