//
//  PDMediaCodecExecutor.m
//  PDMediaCodec
//
//  Created by liang on 2021/1/21.
//
//  http://www.devzhang.cn/2016/09/20/Asset%E7%9A%84%E9%87%8D%E7%BC%96%E7%A0%81%E5%8F%8A%E5%AF%BC%E5%87%BA/
//

#import "PDMediaCodecExecutor.h"
#import "PDMediaCodecRequest.h"
#import <AVFoundation/AVFoundation.h>
#import "PDMediaCodecError.h"
#import "PDMediaCodecUtil.h"

static inline BOOL PDFloatEqualToFloat(CGFloat f1, CGFloat f2) {
    return fabs(f1 - f2) < 0.000001f;
}

@interface PDMediaCodecExecutor ()

@property (nonatomic, copy) void (^doneHandler)(BOOL success, NSError * _Nullable error);
@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, strong) dispatch_queue_t mainSerializationQueue;
@property (nonatomic, strong) dispatch_queue_t rwAudioSerializationQueue;
@property (nonatomic, strong) dispatch_queue_t rwVideoSerializationQueue;
@property (nonatomic, assign) BOOL cancelled;
@property (nonatomic, strong) NSURL *outputURL;
@property (nonatomic, strong) AVAssetReader *assetReader;
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetReaderTrackOutput *assetReaderAudioOutput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterAudioInput;
@property (nonatomic, strong) AVAssetReaderTrackOutput *assetReaderVideoOutput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterVideoInput;
@property (nonatomic, strong) dispatch_group_t dispatchGroup;
@property (nonatomic, assign) BOOL audioFinished;
@property (nonatomic, assign) BOOL videoFinished;

@end

@implementation PDMediaCodecExecutor

- (instancetype)initWithRequest:(PDMediaCodecRequest *)request {
    if (!request.requestID) {
        NSAssert(NO, @"Invalid argument `request`, check it!");
        return nil;
    }
    
    self = [super init];
    if (self) {
        _request = request;
        
        // Create the main serialization queue.
        NSString *serializationQueueDescription = [NSString stringWithFormat:@"com.codec-commit.queue[%@]", _request.requestID];
        self.mainSerializationQueue = dispatch_queue_create([serializationQueueDescription UTF8String], DISPATCH_QUEUE_SERIAL);
        
        // Create the serialization queue to use for reading and writing the audio data.
        NSString *rwAudioSerializationQueueDescription = [NSString stringWithFormat:@"com.codec-audio.queue[%@]",  _request.requestID];
        self.rwAudioSerializationQueue = dispatch_queue_create([rwAudioSerializationQueueDescription UTF8String], DISPATCH_QUEUE_SERIAL);
        
        // Create the serialization queue to use for reading and writing the video data.
        NSString *rwVideoSerializationQueueDescription = [NSString stringWithFormat:@"com.codec-video.queue[%@]",  _request.requestID];
        self.rwVideoSerializationQueue = dispatch_queue_create([rwVideoSerializationQueueDescription UTF8String], DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - Public Methods
- (void)executeWithDoneHandler:(void (^)(BOOL, NSError * _Nullable))doneHandler {
    NSAssert(_request, @"Invalid executor, do not call execute method again!");
    self.doneHandler = doneHandler;
    
    NSError *outError;
    if (![self prepareRunningContextWithError:&outError]) {
        [self notifyWithResult:NO error:outError];
        return;
    }
    
    [self setupConfigurationThenStartRunning];
}

#pragma mark - Tool Methods
- (BOOL)prepareRunningContextWithError:(NSError **)error {
    BOOL isDir = NO;
    BOOL srcExist = [[NSFileManager defaultManager] fileExistsAtPath:_request.srcURL.path isDirectory:&isDir];
    if (!srcExist || isDir) {
        *error = PDErrorWithDomain(PDCodecErrorDomain, PDInvalidArgumentErrorCode,
                                   @"Can not found local file for request `%@`!", self.request);
        return NO;
    }
    
    unsigned long long fileSize = [[NSFileManager defaultManager] attributesOfItemAtPath:_request.srcURL.path error:nil].fileSize;
    if (!fileSize) {
        *error = PDErrorWithDomain(PDCodecErrorDomain, PDInvalidArgumentErrorCode,
                                   @"Src file size is invalid for request `%@`!", self.request);
        return NO;
    }
    
    isDir = NO;
    BOOL dstExist = [[NSFileManager defaultManager] fileExistsAtPath:_request.dstURL.path isDirectory:&isDir];
    if (dstExist && !isDir) {
        if (![[NSFileManager defaultManager] removeItemAtPath:_request.dstURL.path error:nil]) {
            *error = PDErrorWithDomain(PDCodecErrorDomain, PDRemoveFileFailedErrorCode,
                                       @"Remove file failed for request `%@`!", self.request);
            return NO;
        }
    }
    
    NSString *dirPath = [_request.dstURL.path stringByDeletingLastPathComponent]; isDir = NO;
    BOOL dirExist = [[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&isDir];
    if (!dirExist || !isDir) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil]) {
            *error = PDErrorWithDomain(PDCodecErrorDomain, PDCreateDirFailedErrorCode,
                                       @"Create dir path failed for request `%@`!", self.request);
            return NO;
        }
    }
    
    return YES;
}

- (void)setupConfigurationThenStartRunning {
    self.asset = [AVAsset assetWithURL:_request.srcURL];
    self.cancelled = NO;
    self.outputURL = _request.dstURL;
    
    dispatch_async(self.mainSerializationQueue, ^{
        NSError *localError = nil;
        BOOL success = [self setupAssetReaderAndAssetWriter:&localError];
        if (success) {
            success = [self startAssetReaderAndWriter:&localError];
        }
        if (!success) {
            [self readingAndWritingDidFinishSuccessfully:success withError:localError];
        }
    });
}

- (BOOL)setupAssetReaderAndAssetWriter:(NSError **)outError {
    // Create and initialize the asset reader.
    self.assetReader = [[AVAssetReader alloc] initWithAsset:self.asset error:outError];
    BOOL success = (self.assetReader != nil);
    if (success) {
        // If the asset reader was successfully initialized, do the same for the asset writer.
        self.assetWriter = [[AVAssetWriter alloc] initWithURL:self.outputURL fileType:self.request.outputFileType error:outError];
        success = (self.assetWriter != nil);
    }
    
    if (success) {
        // If the reader and writer were successfully initialized, grab the audio and video asset tracks that will be used.
        AVAssetTrack *assetAudioTrack = nil, *assetVideoTrack = nil;
        NSArray *audioTracks = [self.asset tracksWithMediaType:AVMediaTypeAudio];
        if ([audioTracks count] > 0) {
            assetAudioTrack = [audioTracks objectAtIndex:0];
        }
        
        NSArray *videoTracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
        if ([videoTracks count] > 0) {
            assetVideoTrack = [videoTracks objectAtIndex:0];
        }
        
        if (assetAudioTrack) {
            // If there is an audio track to read, set the decompression settings to Linear PCM and create the asset reader output.
            NSDictionary *decompressionAudioSettings = self.request.audioCodecAttr.trackOutputSettings;
            self.assetReaderAudioOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:assetAudioTrack outputSettings:decompressionAudioSettings];
            [self.assetReader addOutput:self.assetReaderAudioOutput];
            
            // Then, set the compression settings to 128kbps AAC and create the asset writer input.
            NSDictionary *compressionAudioSettings = self.request.audioCodecAttr.writeOutputSettings;
            self.assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:[assetAudioTrack mediaType] outputSettings:compressionAudioSettings];
            [self.assetWriter addInput:self.assetWriterAudioInput];
        }
        
        if (assetVideoTrack) {
            // If there is a video track to read, set the decompression settings for YUV and create the asset reader output.
            NSDictionary *decompressionVideoSettings = self.request.videoCodecAttr.trackOutputSettings;
            self.assetReaderVideoOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:assetVideoTrack outputSettings:decompressionVideoSettings];
            [self.assetReader addOutput:self.assetReaderVideoOutput];
            
            // Create the asset writer input and add it to the asset writer.
            // Fix video size
            CGAffineTransform transform = assetVideoTrack.preferredTransform;
            NSMutableDictionary *videoSettings = [self.request.videoCodecAttr.writeOutputSettings mutableCopy];
            
            if ([videoSettings[AVVideoWidthKey] integerValue] == (NSInteger)PDVideoCodecVideoAutoFixWidthValue ||
                [videoSettings[AVVideoHeightKey] integerValue] == (NSInteger)PDVideoCodecVideoAutoFixHeightValue) {
                
                CMFormatDescriptionRef formatDescription = NULL;
                // Grab the video format descriptions from the video track and grab the first one if it exists.
                NSArray *videoFormatDescriptions = [assetVideoTrack formatDescriptions];
                if ([videoFormatDescriptions count] > 0) {
                    formatDescription = (__bridge CMFormatDescriptionRef)[videoFormatDescriptions objectAtIndex:0];
                }
                CGSize trackDimensions = {
                    .width = 0.0,
                    .height = 0.0,
                };
                // If the video track had a format description, grab the track dimensions from there. Otherwise, grab them direcly from the track itself.
                if (formatDescription) {
                    trackDimensions = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, false, false);
                } else {
                    trackDimensions = [assetVideoTrack naturalSize];
                }
                
                if (PDFloatEqualToFloat(trackDimensions.width / trackDimensions.height, 4.f / 3.f)) {
                    videoSettings[AVVideoWidthKey] = @(640.f);
                    videoSettings[AVVideoHeightKey] = @(480.f);
                } else if (PDFloatEqualToFloat(trackDimensions.width / trackDimensions.height, 3.f / 4.f)) {
                    videoSettings[AVVideoWidthKey] = @(480.f);
                    videoSettings[AVVideoHeightKey] = @(640.f);
                } else if (PDFloatEqualToFloat(trackDimensions.width / trackDimensions.height, 16.f / 9.f)) {
                    videoSettings[AVVideoWidthKey] = @(960.f);
                    videoSettings[AVVideoHeightKey] = @(540.f);
                } else if (PDFloatEqualToFloat(trackDimensions.width / trackDimensions.height, 9.f / 16.f)) {
                    videoSettings[AVVideoWidthKey] = @(540.f);
                    videoSettings[AVVideoHeightKey] = @(960.f);
                } else {
                    videoSettings[AVVideoWidthKey] = @(trackDimensions.width);
                    videoSettings[AVVideoHeightKey] = @(trackDimensions.height);
                }
            }
            
            self.assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:[assetVideoTrack mediaType] outputSettings:videoSettings];
            self.assetWriterVideoInput.transform = transform;
            [self.assetWriter addInput:self.assetWriterVideoInput];
        }
    }
    return success;
}

- (BOOL)startAssetReaderAndWriter:(NSError **)outError {
    BOOL success = YES;
    // Attempt to start the asset reader.
    success = [self.assetReader startReading];
    if (!success) {
        *outError = [self.assetReader error];
    }
    if (success) {
        // If the reader started successfully, attempt to start the asset writer.
        success = [self.assetWriter startWriting];
        if (!success) {
            *outError = [self.assetWriter error];
        }
    }
    
    if (success) {
        // If the asset reader and writer both started successfully, create the dispatch group where the reencoding will take place and start a sample-writing session.
        self.dispatchGroup = dispatch_group_create();
        [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
        self.audioFinished = NO;
        self.videoFinished = NO;
        
        if (self.assetWriterAudioInput) {
            // If there is audio to reencode, enter the dispatch group before beginning the work.
            dispatch_group_enter(self.dispatchGroup);
            // Specify the block to execute when the asset writer is ready for audio media data, and specify the queue to call it on.
            [self.assetWriterAudioInput requestMediaDataWhenReadyOnQueue:self.rwAudioSerializationQueue usingBlock:^{
                // Because the block is called asynchronously, check to see whether its task is complete.
                if (self.audioFinished) {
                    return;
                }
                BOOL completedOrFailed = NO;
                // If the task isn't complete yet, make sure that the input is actually ready for more media data.
                while ([self.assetWriterAudioInput isReadyForMoreMediaData] && !completedOrFailed) {
                    // Get the next audio sample buffer, and append it to the output file.
                    CMSampleBufferRef sampleBuffer = [self.assetReaderAudioOutput copyNextSampleBuffer];
                    if (sampleBuffer != NULL) {
                        BOOL success = [self.assetWriterAudioInput appendSampleBuffer:sampleBuffer];
                        CFRelease(sampleBuffer);
                        sampleBuffer = NULL;
                        completedOrFailed = !success;
                    } else {
                        completedOrFailed = YES;
                    }
                }
                if (completedOrFailed && !self.audioFinished) {
                    // Mark the input as finished, but only if we haven't already done so, and then leave the dispatch group (since the audio work has finished).
                    BOOL oldFinished = self.audioFinished;
                    self.audioFinished = YES;
                    if (oldFinished == NO) {
                        [self.assetWriterAudioInput markAsFinished];
                    }
                    dispatch_group_leave(self.dispatchGroup);
                }
            }];
        }
        
        if (self.assetWriterVideoInput) {
            // If we had video to reencode, enter the dispatch group before beginning the work.
            dispatch_group_enter(self.dispatchGroup);
            // Specify the block to execute when the asset writer is ready for video media data, and specify the queue to call it on.
            [self.assetWriterVideoInput requestMediaDataWhenReadyOnQueue:self.rwVideoSerializationQueue usingBlock:^{
                // Because the block is called asynchronously, check to see whether its task is complete.
                if (self.videoFinished) {
                    return;
                }
                
                BOOL completedOrFailed = NO;
                // If the task isn't complete yet, make sure that the input is actually ready for more media data.
                while ([self.assetWriterVideoInput isReadyForMoreMediaData] && !completedOrFailed) {
                    // Get the next video sample buffer, and append it to the output file.
                    CMSampleBufferRef sampleBuffer = [self.assetReaderVideoOutput copyNextSampleBuffer];
                    if (sampleBuffer != NULL) {
                        BOOL success = [self.assetWriterVideoInput appendSampleBuffer:sampleBuffer];
                        CFRelease(sampleBuffer);
                        sampleBuffer = NULL;
                        completedOrFailed = !success;
                    } else {
                        completedOrFailed = YES;
                    }
                }
                if (completedOrFailed && !self.videoFinished) {
                    // Mark the input as finished, but only if we haven't already done so, and then leave the dispatch group (since the video work has finished).
                    BOOL oldFinished = self.videoFinished;
                    self.videoFinished = YES;
                    if (oldFinished == NO) {
                        [self.assetWriterVideoInput markAsFinished];
                    }
                    dispatch_group_leave(self.dispatchGroup);
                }
            }];
        }
        
        // Set up the notification that the dispatch group will send when the audio and video work have both finished.
        dispatch_group_notify(self.dispatchGroup, self.mainSerializationQueue, ^{
            __block BOOL finalSuccess = YES;
            __block NSError *finalError = nil;
            // Check to see if the work has finished due to cancellation.
            if (self.cancelled) {
                // If so, cancel the reader and writer.
                [self.assetReader cancelReading];
                [self.assetWriter cancelWriting];
                
                if ([[NSFileManager defaultManager] fileExistsAtPath:self.request.dstURL.path]) {
                    [[NSFileManager defaultManager] removeItemAtPath:self.request.dstURL.path error:nil];
                }
                
                finalSuccess = NO;
                finalError = PDErrorWithDomain(PDCodecErrorDomain, PDCodecCancelledErrorCode,
                                               @"Codec media resource cancelled for request `%@`!", self.request);
                // Call the method to handle completion, and pass in the appropriate parameters to indicate whether reencoding was successful.
                [self readingAndWritingDidFinishSuccessfully:finalSuccess withError:finalError];
                return;
            }
            
            // If cancellation didn't occur, first make sure that the asset reader didn't fail.
            if ([self.assetReader status] == AVAssetReaderStatusFailed) {
                finalSuccess = NO;
                finalError = ([self.assetReader error] ?:
                              PDErrorWithDomain(PDCodecErrorDomain, PDCodecFailedErrorCode,
                                                @"Codec video failed for request `%@`!", self.request));
                [self readingAndWritingDidFinishSuccessfully:finalSuccess withError:finalError];
                return;
            }
            
            __weak typeof(self) weakSelf = self;
            [self.assetWriter finishWritingWithCompletionHandler:^{
                finalError = [self.assetReader error];
                finalSuccess = finalError ? NO : YES;
                [weakSelf readingAndWritingDidFinishSuccessfully:finalSuccess withError:finalError];
            }];
        });
    }
    // Return success here to indicate whether the asset reader and writer were started successfully.
    return success;
}

- (void)readingAndWritingDidFinishSuccessfully:(BOOL)success withError:(NSError *)error {
    if (!success) {
        // If the reencoding process failed, we need to cancel the asset reader and writer.
        [self.assetReader cancelReading];
        [self.assetWriter cancelWriting];
        [self notifyWithResult:NO error:error];
    } else {
        // Reencoding was successful, reset booleans.
        self.cancelled = NO;
        self.videoFinished = NO;
        self.audioFinished = NO;
        [self notifyWithResult:YES error:nil];
    }
}

- (void)cancel {
    // Handle cancellation asynchronously, but serialize it with the main queue.
    dispatch_async(self.mainSerializationQueue, ^{
        // Handle cancellation asynchronously again, but this time serialize it with the audio queue.
        dispatch_async(self.rwAudioSerializationQueue, ^{
            // If we had audio data to reencode, we need to cancel the audio work.
            if (self.assetWriterAudioInput && !self.audioFinished) {
                // Update the Boolean property indicating the task is complete and mark the input as finished if it hasn't already been marked as such.
                BOOL oldFinished = self.audioFinished;
                self.audioFinished = YES;
                if (oldFinished == NO) {
                    [self.assetWriterAudioInput markAsFinished];
                }
                // Leave the dispatch group since the audio work is finished now.
                dispatch_group_leave(self.dispatchGroup);
            }
        });
        
        // Handle cancellation asynchronously again, but this time serialize it with the video queue.
        dispatch_async(self.rwVideoSerializationQueue, ^{
            if (self.assetWriterVideoInput && !self.videoFinished) {
                // Update the Boolean property indicating the task is complete and mark the input as finished if it hasn't already been marked as such.
                BOOL oldFinished = self.videoFinished;
                self.videoFinished = YES;
                if (oldFinished == NO) {
                    [self.assetWriterVideoInput markAsFinished];
                }
                // Leave the dispatch group, since the video work is finished now.
                dispatch_group_leave(self.dispatchGroup);
            }
        });
        
        // Set the cancelled Boolean property to YES to cancel any work on the main queue as well.
        self.cancelled = YES;
    });
}

- (void)notifyWithResult:(BOOL)result error:(NSError *)error {
    PDDispatchOnMainQueue(^{
        !self.request.doneHandler ?: self.request.doneHandler(result, error);
        !self.doneHandler ?: self.doneHandler(result, error);
    });
}

@end
