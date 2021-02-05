//
//  PDAudioCodecOperation.h
//  PDMediaCodec
//
//  Created by liang on 2021/2/3.
//

#import <Foundation/Foundation.h>
#import "PDAudioCodecRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class PDAudioCodecOperation;

/// @enum NEAudioCodecState
/// @brief 音频转码状态
typedef NS_ENUM(NSUInteger, NEAudioCodecState) {
    NEAudioCodecStateInitial    = 0,
    NEAudioCodecStateStarted    = 1,
    NEAudioCodecStateExecuting  = NEAudioCodecStateStarted,
    NEAudioCodecStateFinished   = 2,
    NEAudioCodecStateFailed     = 3,
    NEAudioCodecStateCancelled  = 4,
};

@protocol PDAudioCodecOperationDelegate <NSObject>

- (void)operationDidFinishCodec:(PDAudioCodecOperation *)operation;
- (void)operation:(PDAudioCodecOperation *)operation didFailCodecWithError:(NSError *)error;

@end

/// @class PDAudioCodecOperation
/// @brief 音频转码操作基类（具体转码操作需要继承自本类）
@interface PDAudioCodecOperation : NSOperation

@property (nonatomic, weak, readonly, nullable) PDAudioCodecRequest *request;
@property (nonatomic, weak, readonly, nullable) id<PDAudioCodecOperationDelegate> delegate;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithRequest:(PDAudioCodecRequest *)request delegate:(id<PDAudioCodecOperationDelegate>)delegate NS_DESIGNATED_INITIALIZER;

- (BOOL)prepareRunningContextWithError:(NSError **)error;
- (void)notifyWithResult:(BOOL)result error:(NSError * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
