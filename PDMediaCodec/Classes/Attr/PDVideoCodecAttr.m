//
//  PDVideoCodecAttr.m
//  PDMediaCodec
//
//  Created by liang: on 2021/1/21.
//

#import "PDVideoCodecAttr.h"
#import <AVFoundation/AVFoundation.h>

CGFloat const PDVideoCodecVideoAutoFixWidthValue = -1;
CGFloat const PDVideoCodecVideoAutoFixHeightValue = -1;

@implementation PDVideoCodecAttr

/*
    NSDictionary *decompressionVideoSettings = @{
        (id)kCVPixelBufferPixelFormatTypeKey     : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_422YpCbCr8],
        (id)kCVPixelBufferIOSurfacePropertiesKey : [NSDictionary dictionary]
    };
 
 
 
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
    NSDictionary *compressionSettings = nil;
    // If the video track had a format description, attempt to grab the clean aperture settings and pixel aspect ratio used by the video.
    if (formatDescription) {
        NSDictionary *cleanAperture = nil;
        NSDictionary *pixelAspectRatio = nil;
        CFDictionaryRef cleanApertureFromCMFormatDescription = CMFormatDescriptionGetExtension(formatDescription, kCMFormatDescriptionExtension_CleanAperture);
        if (cleanApertureFromCMFormatDescription) {
            cleanAperture = @{
                AVVideoCleanApertureWidthKey            : (id)CFDictionaryGetValue(cleanApertureFromCMFormatDescription, kCMFormatDescriptionKey_CleanApertureWidth),
                AVVideoCleanApertureHeightKey           : (id)CFDictionaryGetValue(cleanApertureFromCMFormatDescription, kCMFormatDescriptionKey_CleanApertureHeight),
                AVVideoCleanApertureHorizontalOffsetKey : (id)CFDictionaryGetValue(cleanApertureFromCMFormatDescription, kCMFormatDescriptionKey_CleanApertureHorizontalOffset),
                AVVideoCleanApertureVerticalOffsetKey   : (id)CFDictionaryGetValue(cleanApertureFromCMFormatDescription, kCMFormatDescriptionKey_CleanApertureVerticalOffset)
            };
        }
        CFDictionaryRef pixelAspectRatioFromCMFormatDescription = CMFormatDescriptionGetExtension(formatDescription, kCMFormatDescriptionExtension_PixelAspectRatio);
        if (pixelAspectRatioFromCMFormatDescription) {
            pixelAspectRatio = @{
                AVVideoPixelAspectRatioHorizontalSpacingKey : (id)CFDictionaryGetValue(pixelAspectRatioFromCMFormatDescription, kCMFormatDescriptionKey_PixelAspectRatioHorizontalSpacing),
                AVVideoPixelAspectRatioVerticalSpacingKey   : (id)CFDictionaryGetValue(pixelAspectRatioFromCMFormatDescription, kCMFormatDescriptionKey_PixelAspectRatioVerticalSpacing)
            };
        }
        // Add whichever settings we could grab from the format description to the compression settings dictionary.
        if (cleanAperture || pixelAspectRatio) {
            NSMutableDictionary *mutableCompressionSettings = [NSMutableDictionary dictionary];
            if (cleanAperture)
                [mutableCompressionSettings setObject:cleanAperture forKey:AVVideoCleanApertureKey];
            if (pixelAspectRatio)
                [mutableCompressionSettings setObject:pixelAspectRatio forKey:AVVideoPixelAspectRatioKey];
            compressionSettings = mutableCompressionSettings;
        }
    }
    // Create the video settings dictionary for H.264.
    NSMutableDictionary *videoSettings = (NSMutableDictionary *) @{
        AVVideoCodecKey  : AVVideoCodecH264,
        AVVideoWidthKey  : [NSNumber numberWithDouble:trackDimensions.width],
        AVVideoHeightKey : [NSNumber numberWithDouble:trackDimensions.height]
    };
    // Put the compression settings into the video settings dictionary if we were able to grab them.
    if (compressionSettings) {
        [videoSettings setObject:compressionSettings forKey:AVVideoCompressionPropertiesKey];
    }
 */

+ (instancetype)defaultCodecAttr {
    PDVideoCodecAttr *attr = [[PDVideoCodecAttr alloc] init];
    
    attr.trackOutputSettings = @{
        (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_422YpCbCr8),
        (id)kCVPixelBufferIOSurfacePropertiesKey :@{}
    };
    
    attr.writeOutputSettings = ({
        NSDictionary *compressionProperties = @{
            AVVideoAverageBitRateKey: @(200 * 8 * 1024),
            AVVideoExpectedSourceFrameRateKey: @25,
            AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
        };
        
        NSDictionary *writeOutputSettings = @{
    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_11_0
            AVVideoCodecKey: AVVideoCodecTypeH264,
    #else
            AVVideoCodecKey: AVVideoCodecH264,
    #endif
            AVVideoWidthKey: @(PDVideoCodecVideoAutoFixWidthValue),
            AVVideoHeightKey: @(PDVideoCodecVideoAutoFixHeightValue),
            AVVideoCompressionPropertiesKey: compressionProperties,
            AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
        };
        
        writeOutputSettings;
    });
        
    return attr;
}

@end
