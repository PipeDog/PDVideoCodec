#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "lame.h"
#import "PDAudioCodecManager.h"
#import "PDAudioCodec2MP3Operation.h"
#import "PDAudioCodecOperation.h"
#import "PDAudioCodecBatchRequest.h"
#import "PDAudioCodecRequest+Build.h"
#import "PDAudioCodecRequest.h"
#import "PDMediaCodec.h"
#import "PDAudioCodecAttr.h"
#import "PDVideoCodecAttr.h"
#import "PDCodecDebugTool.h"
#import "PDMediaCodecExecutor.h"
#import "PDMediaCodecManager.h"
#import "PDMediaCodecQueue.h"
#import "PDMediaCodecBatchRequest.h"
#import "PDMediaCodecRequest+Build.h"
#import "PDMediaCodecRequest.h"
#import "PDMediaCodecSliceRequest.h"
#import "PDMediaCodecError.h"
#import "PDMediaCodecUtil.h"
#import "PDMediaSplitEngine.h"

FOUNDATION_EXPORT double PDMediaCodecVersionNumber;
FOUNDATION_EXPORT const unsigned char PDMediaCodecVersionString[];

