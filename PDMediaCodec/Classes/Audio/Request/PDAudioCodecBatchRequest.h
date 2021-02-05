//
//  PDAudioCodecBatchRequest.h
//  PDMediaCodec
//
//  Created by liang on 2021/2/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PDAudioCodecRequest;

typedef NSString * PDAudioCodecRequestID;
typedef NSNumber * PDAudioCodecRequestIndex;
typedef NSDictionary<PDAudioCodecRequestIndex, NSError *> * NEAudioCodecErrorMap;
typedef NSDictionary<PDAudioCodecRequestIndex, PDAudioCodecRequest *> * PDAudioCodecRequestMap;

typedef void (^PDAudioCodecBatchRequestBlock)(BOOL success,
                                              NEAudioCodecErrorMap _Nullable errorMap,
                                              PDAudioCodecRequestMap _Nullable successRequestMap,
                                              PDAudioCodecRequestMap _Nullable failedRequestMap);

@protocol PDAudioCodecBatchRequestBuilder <NSObject>

@property (nonatomic, copy) NSArray<PDAudioCodecRequest *> *batchRequests;

@end

/// @class PDAudioCodecBatchRequest
/// @brief 音频批量转码请求
@interface PDAudioCodecBatchRequest : NSObject

@property (nonatomic, copy) NSArray<PDAudioCodecRequest *> *batchRequests;

+ (instancetype)requestWithBuilder:(void (^)(id<PDAudioCodecBatchRequestBuilder> builder))block;

- (instancetype)send;
- (instancetype)sendWithDoneHandler:(PDAudioCodecBatchRequestBlock _Nullable)doneHandler;

- (void)cancel;
- (PDAudioCodecRequestID)requestID;

@end

NS_ASSUME_NONNULL_END
