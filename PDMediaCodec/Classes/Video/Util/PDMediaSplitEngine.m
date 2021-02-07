//
//  PDMediaSplitEngine.m
//  PDMediaCodec
//
//  Created by liang on 2021/1/24.
//

#import "PDMediaSplitEngine.h"
#import <AVFoundation/AVFoundation.h>
#import "PDMediaCodecError.h"
#import "PDMediaCodecUtil.h"

@implementation PDMediaSplitEngine

+ (BOOL)removeFileAtPathIfNeeded:(NSURL *)fileURL error:(NSError **)error {
    BOOL isDir = NO;
    BOOL dstExist = [[NSFileManager defaultManager] fileExistsAtPath:fileURL.path isDirectory:&isDir];
    if (dstExist && !isDir) {
        if (![[NSFileManager defaultManager] removeItemAtPath:fileURL.path error:nil]) {
            *error = PDErrorWithDomain(PDCodecErrorDomain, PDRemoveFileFailedErrorCode,
                                       @"Remove file failed!");
            return NO;
        }
    }
    
    return YES;
}

+ (BOOL)createDirAtPathIfNeeded:(NSURL *)dirURL error:(NSError **)error {
    BOOL isDir = NO;
    BOOL dstExist = [[NSFileManager defaultManager] fileExistsAtPath:dirURL.path isDirectory:&isDir];
    if (dstExist && !isDir) {
        if (![[NSFileManager defaultManager] removeItemAtPath:dirURL.path error:nil]) {
            *error = PDErrorWithDomain(PDCodecErrorDomain, PDRemoveFileFailedErrorCode,
                                       @"Remove file failed!");
            return NO;
        }
    }
    
    NSString *dirPath = dirURL.path; isDir = NO;
    BOOL dirExist = [[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&isDir];
    if (!dirExist || !isDir) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil]) {
            *error = PDErrorWithDomain(PDCodecErrorDomain, PDCreateDirFailedErrorCode,
                                       @"Create dir path failed!");
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Public Methods
+ (void)splitMediaWithSourceURL:(NSURL *)srcURL
      toDestinationDirectoryURL:(NSURL *)dstDirURL
                  sliceDuration:(NSTimeInterval)sliceDuration
                    doneHandler:(void (^)(NSError * _Nullable, NSArray<NSURL *> * _Nullable))doneHandler {
    NSError *error;
    if (![self createDirAtPathIfNeeded:dstDirURL error:&error]) {
        !doneHandler ?: doneHandler(error, nil);
        return;
    }
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:srcURL options:nil];
    BOOL supportVideo = [asset tracksWithMediaType:AVMediaTypeVideo].count > 0;
    BOOL supportAudio = [asset tracksWithMediaType:AVMediaTypeAudio].count > 0;
    
    if (!supportVideo && !supportAudio) {
        PDDispatchOnMainQueue(^{
            NSAssert(NO, @"Unrecognized media type!");
            NSError *error = PDErrorWithDomain(PDCodecErrorDomain, PDUnrecognizedMediaTypeErrorCode,
                                               @"Unrecognized media type for srcURL `%@`!", srcURL);
            !doneHandler ?: doneHandler(error, nil);
        });
        return;
    }
    
    Float64 duration = CMTimeGetSeconds(asset.duration);
    if (duration <= sliceDuration) {
        NSError *error = PDErrorWithDomain(PDCodecErrorDomain, PDCodecCancelledErrorCode,
                                           @"Small media file, send normal codec request!");
        !doneHandler ?: doneHandler(error, nil);
        return;
    }
    
    __block NSError *outError;
    NSMutableDictionary<NSNumber *, NSURL *> *dstURLMap = [NSMutableDictionary dictionary];
    NSInteger sectionCount = ceil(duration / sliceDuration);
    dispatch_semaphore_t lock = dispatch_semaphore_create(1);
    dispatch_group_t group = dispatch_group_create();
    
    for (NSInteger i = 0; i < sectionCount; i++) {
        CGFloat endTime = (i + 1) * sliceDuration;
        if (i == sectionCount) { endTime = duration; }
        
        dispatch_group_enter(group);
        [self splitMediaWithAsset:asset
                containsVideoType:supportVideo
                      toDstDirURL:dstDirURL
                          atIndex:i
                        startTime:i * sliceDuration
                          endTime:endTime
                      doneHandler:^(BOOL success, NSError *error, NSURL *dstURL) {
            
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
            if (error) {
                outError = error;
            } else {
                dstURLMap[@(i)] = dstURL;
            }
            dispatch_semaphore_signal(lock);
            dispatch_group_leave(group);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSMutableArray *dstURLs = [NSMutableArray array];
        for (NSInteger i = 0; i < sectionCount; i++) {
            NSURL *dstURL = dstURLMap[@(i)];
            if (dstURL) {
                [dstURLs addObject:dstURL];
            }
        }
        
        !doneHandler ?: doneHandler(outError, dstURLs);
    });
}

+ (void)mergeMediasWithSourceURLs:(NSArray<NSURL *> *)srcURLs
                 toDestinationURL:(NSURL *)dstURL
                      doneHandler:(void (^)(NSError * _Nullable, NSURL * _Nonnull))doneHandler {
    if (!srcURLs.count) {
        NSError *error = PDErrorWithDomain(PDCodecErrorDomain, PDInvalidArgumentErrorCode,
                                           @"Invalid argument `srcURLs`!");
        !doneHandler ?: doneHandler(error, dstURL);
        return;
    }
    
    NSError *error;
    if (![self removeFileAtPathIfNeeded:dstURL error:&error]) {
        !doneHandler ?: doneHandler(error, dstURL);
        return;
    }
    
    AVMutableComposition *composition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                     preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                     preferredTrackID:kCMPersistentTrackID_Invalid];
    __block CMTime currentTime = kCMTimeZero;
    __block CGSize size = CGSizeZero;
    __block int32_t highestFrameRate = 0;
    __block BOOL supportVideo = NO;
    __block BOOL supportAudio = NO;
    
    [srcURLs enumerateObjectsUsingBlock:^(NSURL *fileURL, NSUInteger idx, BOOL *stop) {
        NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey: @YES};
        AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:fileURL options:options];
        AVAssetTrack *videoAsset = [[sourceAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        AVAssetTrack *audioAsset = [[sourceAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        
        if (!supportVideo && videoAsset) { supportVideo = YES; }
        if (!supportAudio && audioAsset) { supportAudio = YES; }
        if (CGSizeEqualToSize(size, CGSizeZero)) { size = videoAsset.naturalSize; }
        
        int32_t currentFrameRate = (int)roundf(videoAsset.nominalFrameRate);
        highestFrameRate = (currentFrameRate > highestFrameRate) ? currentFrameRate : highestFrameRate;
        
        CMTime trimmingTime = CMTimeMake(lround(videoAsset.naturalTimeScale / videoAsset.nominalFrameRate), videoAsset.naturalTimeScale);
        CMTimeRange timeRange = CMTimeRangeMake(trimmingTime, CMTimeSubtract(videoAsset.timeRange.duration, trimmingTime));
        
        NSError *videoError;
        [videoTrack insertTimeRange:timeRange ofTrack:videoAsset atTime:currentTime error:&videoError];
        
        NSError *audioError;
        [audioTrack insertTimeRange:timeRange ofTrack:audioAsset atTime:currentTime error:&audioError];
        
        currentTime = CMTimeAdd(currentTime, timeRange.duration);
    }];
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    exportSession.outputURL = dstURL;
    exportSession.outputFileType = supportVideo ? AVFileTypeMPEG4 : AVFileTypeMPEGLayer3;
    exportSession.shouldOptimizeForNetworkUse = YES;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (exportSession.status) {
                case AVAssetExportSessionStatusCompleted: {
                    !doneHandler ?: doneHandler(nil, dstURL);
                } break;
                case AVAssetExportSessionStatusCancelled: {
                    NSError *cancelError = PDErrorWithDomain(PDCodecErrorDomain, PDCodecCancelledErrorCode,
                                                             @"Cancel merge media resources!");
                    !doneHandler ?: doneHandler(cancelError, dstURL);
                } break;
                case AVAssetExportSessionStatusFailed: default: {
                    !doneHandler ?: doneHandler(exportSession.error, dstURL);
                } break;
            }
        });
    }];
}

#pragma mark - Private Methods
+ (void)splitMediaWithAsset:(AVURLAsset *)asset
          containsVideoType:(BOOL)containsVideoType
                toDstDirURL:(NSURL *)dstDirURL
                    atIndex:(NSInteger)index
                  startTime:(CGFloat)startTime
                    endTime:(CGFloat)endTime
                doneHandler:(void (^)(BOOL success, NSError *error, NSURL *dstURL))doneHandler {
    
    NSString *dirPath = dstDirURL.path;
    NSString *fileName = [NSString stringWithFormat:@"section-%zd.%@",
                          index, containsVideoType ? @"mp4" : @"mp3"];
    NSString *dstPath = [dirPath stringByAppendingPathComponent:fileName];
    NSURL *dstURL = [NSURL fileURLWithPath:dstPath];
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetPassthrough];
    exportSession.outputURL = dstURL;
    exportSession.outputFileType = containsVideoType ? AVFileTypeMPEG4 : AVFileTypeMPEGLayer3;
    exportSession.shouldOptimizeForNetworkUse = YES;
    
    CMTime start = CMTimeMakeWithSeconds(startTime, asset.duration.timescale);
    CMTime duration = CMTimeMakeWithSeconds(endTime - startTime, asset.duration.timescale);
    CMTimeRange range = CMTimeRangeMake(start, duration);
    exportSession.timeRange = range;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        switch ([exportSession status]) {
            case AVAssetExportSessionStatusCancelled: {
                NSError *error = PDErrorWithDomain(PDCodecErrorDomain, PDCodecCancelledErrorCode,
                                                   @"Cancel split media at index `%zd`", index);
                !doneHandler ?: doneHandler(NO, error, dstURL);
            } break;
            case AVAssetExportSessionStatusCompleted: {
                !doneHandler ?: doneHandler(YES, nil, dstURL);
            } break;
            case AVAssetExportSessionStatusFailed: default: {
                !doneHandler ?: doneHandler(NO, exportSession.error, dstURL);
            } break;
        }
    }];
}

@end
