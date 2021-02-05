//
//  PDAudioCodecAttr.m
//  PDMediaCodec
//
//  Created by liang: on 2021/1/21.
//

#import "PDAudioCodecAttr.h"
#import <AVFoundation/AVFoundation.h>

@implementation PDAudioCodecAttr

/*
    NSDictionary *decompressionAudioSettings = @{
        AVFormatIDKey : [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM]
    };
 
    AudioChannelLayout stereoChannelLayout = {
        .mChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
        .mChannelBitmap = 0,
        .mNumberChannelDescriptions = 0
    };
    NSData *channelLayoutAsData = [NSData dataWithBytes:&stereoChannelLayout length:offsetof(AudioChannelLayout, mChannelDescriptions)];
    NSDictionary *compressionAudioSettings = @{
        AVFormatIDKey         : [NSNumber numberWithUnsignedInt:kAudioFormatMPEG4AAC],
        AVEncoderBitRateKey   : [NSNumber numberWithInteger:128000],
        AVSampleRateKey       : [NSNumber numberWithInteger:44100],
        AVChannelLayoutKey    : channelLayoutAsData,
        AVNumberOfChannelsKey : [NSNumber numberWithUnsignedInteger:2]
    };
 */

+ (instancetype)defaultCodecAttr {
    PDAudioCodecAttr *attr = [[PDAudioCodecAttr alloc] init];
    
    attr.trackOutputSettings = @{
        AVFormatIDKey : @(kAudioFormatLinearPCM)
    };
    
    attr.writeOutputSettings = ({
        AudioChannelLayout stereoChannelLayout = {
            .mChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
            .mChannelBitmap = 0,
            .mNumberChannelDescriptions = 0,
        };
        
        NSData *layoutData = [NSData dataWithBytes:&stereoChannelLayout length:offsetof(AudioChannelLayout, mChannelDescriptions)];
        NSDictionary *writeOutputSettings = @{
            AVFormatIDKey: @(kAudioFormatMPEG4AAC),
            AVEncoderBitRateKey: @96000,
            AVSampleRateKey: @44100,
            AVChannelLayoutKey: layoutData,
            AVNumberOfChannelsKey: @2,
        };
        
        writeOutputSettings;
    });
    
    return attr;
}

@end
