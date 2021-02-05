//
//  PDMediaCodecRequest.h
//  PDMediaCodec
//
//  Created by liang: on 2021/1/21.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVMediaFormat.h>
#import <PDVideoCodecAttr.h>
#import <PDAudioCodecAttr.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString * PDMediaCodecRequestID;

@protocol PDMediaCodecRequest <NSObject>

@property (nonatomic, strong) NSURL *srcURL;
@property (nonatomic, strong) NSURL *dstURL;
@property (nonatomic, strong) AVFileType outputFileType;
@property (nonatomic, strong) PDVideoCodecAttr *videoCodecAttr;
@property (nonatomic, strong) PDAudioCodecAttr *audioCodecAttr;
@property (nonatomic, copy, nullable) void (^doneHandler)(BOOL success, NSError * _Nullable error);

@end

/// @class PDMediaCodecRequest
/// @brief 媒体编码请求，每个请求对应一次转码过程
@interface PDMediaCodecRequest : NSObject <PDMediaCodecRequest>

- (instancetype)send;
- (instancetype)sendWithDoneHandler:(void (^ _Nullable)(BOOL success, NSError * _Nullable error))doneHandler;

- (void)cancel; // Will execute `doneHandler` block when invoke `- cancel` method.
- (PDMediaCodecRequestID)requestID;

@end

NS_ASSUME_NONNULL_END
