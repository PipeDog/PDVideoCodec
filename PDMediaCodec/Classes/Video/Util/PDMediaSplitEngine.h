//
//  PDMediaSplitEngine.h
//  PDMediaCodec
//
//  Created by liang on 2021/1/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// @class PDMediaSplitEngine
/// @brief 视频分割、合成引擎
@interface PDMediaSplitEngine : NSObject

+ (void)splitMediaWithSourceURL:(NSURL *)srcURL
      toDestinationDirectoryURL:(NSURL *)dstDirURL
                  sliceDuration:(NSTimeInterval)sliceDuration
                    doneHandler:(void (^)(NSError * _Nullable error, NSArray<NSURL *> * _Nullable dstURLs))doneHandler;

+ (void)mergeMediasWithSourceURLs:(NSArray<NSURL *> *)srcURLs
                 toDestinationURL:(NSURL *)dstURL
                      doneHandler:(void (^)(NSError * _Nullable error, NSURL *dstURL))doneHandler;

@end

NS_ASSUME_NONNULL_END
