//
//  PDAudioCodec2MP3Operation.m
//  PDMediaCodec
//
//  Created by liang on 2021/2/3.
//

#import "PDAudioCodec2MP3Operation.h"
#import "PDMediaCodecError.h"
#import "lame.h"

@interface PDAudioCodec2MP3Operation ()

@property (atomic, assign) NEAudioCodecState state;

@end

@implementation PDAudioCodec2MP3Operation

@synthesize state = _state;

- (instancetype)initWithRequest:(PDAudioCodecRequest *)request delegate:(id<PDAudioCodecOperationDelegate>)delegate {
    self = [super initWithRequest:request delegate:delegate];
    if (self) {
        _state = NEAudioCodecStateInitial;
    }
    return self;
}

- (void)main {
    self.state = NEAudioCodecStateStarted;
    
    NSError *outError;
    if (![self prepareRunningContextWithError:&outError]) {
        self.state = NEAudioCodecStateFailed;
        [self notifyWithResult:NO error:outError];
        return;
    }
    
    @try {
        FILE *fwav = fopen([self.request.srcURL.path cStringUsingEncoding:NSASCIIStringEncoding], "rb");
        FILE *fmp3 = fopen([self.request.dstURL.path cStringUsingEncoding:NSASCIIStringEncoding], "wb+");
        
        // Skip PCM header
        fseek(fwav, 4 * 1024, SEEK_CUR);
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        int channel = 1;
        
        short int wav_buffer[PCM_SIZE*channel];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        // Set sample rate
        lame_set_in_samplerate(lame , 8000);
        lame_set_out_samplerate(lame, 8000);
        lame_set_num_channels(lame, channel);
        lame_set_brate(lame, 32);
        
        // Set MP3 codec mode
        lame_init_params(lame);
        
        long read;
        int write;
        do {
            // Stop codec if cancelled.
            if (self.state == NEAudioCodecStateCancelled) {
                break;
            }
            
            read = fread(wav_buffer, sizeof(short int)*channel, PCM_SIZE, fwav);
            if (read != 0) {
                write = lame_encode_buffer(lame, wav_buffer, NULL, (int)read, mp3_buffer, MP3_SIZE);
            } else {
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            }
            fwrite(mp3_buffer, sizeof(unsigned char), write, fmp3);
        } while (read != 0);
        
        lame_close(lame);
        fclose(fwav);
        fclose(fmp3);
    } @catch (NSException *exception) {
        self.state = NEAudioCodecStateFailed;
        NSError *error = PDErrorWithDomain(PDCodecErrorDomain,
                                           PDCodecFailedErrorCode,
                                           @"Codec audio catch exception = %@, request = `%@`!", exception, self.request);
        [self notifyWithResult:NO error:error];
    } @finally {
        [self checkStateThenNotifyRequest];
    }
}

- (void)cancel {
    [super cancel];
    
    NEAudioCodecState oldState = self.state;
    self.state = NEAudioCodecStateCancelled;
    
    if (oldState != NEAudioCodecStateExecuting) {
        NSError *error = PDErrorWithDomain(PDCodecErrorDomain,
                                           PDCodecCancelledErrorCode,
                                           @"Codec audio cancelled, request = `%@`!", self.request);
        [self notifyWithResult:NO error:error];
    }
}

#pragma mark - Private Methods
- (void)checkStateThenNotifyRequest {
    // Cancelled
    if (self.state == NEAudioCodecStateCancelled) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.request.dstURL.path]) {
            [[NSFileManager defaultManager] removeItemAtPath:self.request.dstURL.path error:nil];
        }
        
        NSError *error = PDErrorWithDomain(PDCodecErrorDomain,
                                           PDCodecCancelledErrorCode,
                                           @"Codec audio cancelled, request = `%@`!", self.request);
        [self notifyWithResult:NO error:error];
        return;
    }
    
    // Finished, check local file
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.request.dstURL.path] ||
        [[NSFileManager defaultManager] attributesOfItemAtPath:self.request.dstURL.path error:nil].fileSize <= 0) {
        self.state = NEAudioCodecStateFailed;
        NSError *error = PDErrorWithDomain(PDCodecErrorDomain,
                                           PDCodecFailedErrorCode,
                                           @"Codec audio failed for request `%@`!", self.request);
        [self notifyWithResult:NO error:error];
        return;
    }
    
    // Finished, file valid
    self.state = NEAudioCodecStateFinished;
    [self notifyWithResult:YES error:nil];
}

@end
