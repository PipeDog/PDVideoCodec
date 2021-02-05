//
//  PDAudioCodecRequest.h
//  PDMediaCodec
//
//  Created by liang on 2021/2/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString * NEAudioFileType NS_TYPED_ENUM;

FOUNDATION_EXPORT NEAudioFileType const NEAudioFileTypeMP3;
FOUNDATION_EXPORT NEAudioFileType const NEAudioFileTypeWAV;
FOUNDATION_EXPORT NEAudioFileType const NEAudioFileTypeCAF;
FOUNDATION_EXPORT NEAudioFileType const NEAudioFileTypeM4A;

typedef NSString * PDAudioCodecRequestID;

@protocol PDAudioCodecRequest <NSObject>

@property (nonatomic, strong) NSURL *srcURL;
@property (nonatomic, strong) NSURL *dstURL;
@property (nonatomic, strong) NEAudioFileType outputFileType;
@property (nonatomic, copy, nullable) void (^doneHandler)(BOOL success, NSError * _Nullable error);

@end

/// @class PDAudioCodecRequest
/// @brief 音频转码请求
@interface PDAudioCodecRequest : NSObject <PDAudioCodecRequest>

- (instancetype)send;
- (instancetype)sendWithDoneHandler:(void (^ _Nullable)(BOOL success, NSError * _Nullable error))doneHandler;

- (void)cancel; // Will execute `doneHandler` block when invoke `- cancel` method.
- (PDAudioCodecRequestID)requestID;

@end

NS_ASSUME_NONNULL_END
