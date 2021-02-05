//
//  PDAudioCodecRequest.m
//  PDMediaCodec
//
//  Created by liang on 2021/2/1.
//

#import "PDAudioCodecRequest.h"
#import "PDAudioCodecManager.h"

NEAudioFileType const NEAudioFileTypeMP3 = @"mp3";
NEAudioFileType const NEAudioFileTypeWAV = @"wav";
NEAudioFileType const NEAudioFileTypeCAF = @"caf";
NEAudioFileType const NEAudioFileTypeM4A = @"m4a";

@implementation PDAudioCodecRequest {
    PDAudioCodecRequestID _requestID;
}

@synthesize srcURL = _srcURL;
@synthesize dstURL = _dstURL;
@synthesize outputFileType = _outputFileType;
@synthesize doneHandler = _doneHandler;

- (instancetype)init {
    self = [super init];
    if (self) {
        _outputFileType = NEAudioFileTypeMP3;
    }
    return self;
}

- (instancetype)send {
    return [self sendWithDoneHandler:nil];
}

- (instancetype)sendWithDoneHandler:(void (^)(BOOL, NSError * _Nullable))doneHandler {
    self.doneHandler = doneHandler;
    [[PDAudioCodecManager defaultManager] addRequest:self];
    return self;
}

- (void)cancel {
    [[PDAudioCodecManager defaultManager] cancelRequest:self];
}

- (PDAudioCodecRequestID)requestID {
    if (!_requestID) {
        _requestID = [NSString stringWithFormat:@"%lu", (unsigned long)[self hash]];
    }
    return _requestID;
}

- (NSString *)description {
    NSMutableString *format = [NSMutableString string];
    [format appendString:@"\n<request : \n"];
    [format appendFormat:@"\t srcURL = %@, \n", self.srcURL];
    [format appendFormat:@"\t dstURL = %@, \n", self.dstURL];
    [format appendFormat:@"\t requestID = %@, \n", self.requestID];
    [format appendString:@">\n"];
    return format;
}

@end
