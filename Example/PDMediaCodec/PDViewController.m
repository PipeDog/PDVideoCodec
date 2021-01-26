//
//  PDViewController.m
//  PDMediaCodec
//
//  Created by liang on 01/26/2021.
//  Copyright (c) 2021 liang. All rights reserved.
//

#import "PDViewController.h"
#import <PDMediaCodec.h>

@interface PDViewController ()

@end

@implementation PDViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)normalCodec {
    [[PDMediaCodecRequest requestWithBuilder:^(id<PDMediaCodecRequestBuilder>  _Nonnull builder) {
        builder.srcURL = [NSURL URLWithString:@""];
        builder.dstURL = [NSURL URLWithString:@""];
    }] sendWithDoneHandler:^(BOOL success, NSError * _Nullable error) {
        if (!success || error) {
            return;
        }
        
        // codec success...
    }];
}

- (void)batchCodec {
    [[PDMediaCodecBatchRequest requestWithBuilder:^(id<PDMediaCodecBatchRequestBuilder>  _Nonnull builder) {
        builder.batchRequests = @[
            // xxx
        ];
    }] sendWithDoneHandler:^(BOOL success,
                             NEMediaCodecErrorMap  _Nullable errorMap,
                             PDMediaCodecRequestMap  _Nullable successRequestMap,
                             PDMediaCodecRequestMap  _Nullable failedRequestMap) {
        // TODO: codec finished...
    }];
}

- (void)sliceCodec {
    [[PDMediaCodecSliceRequest requestWithBuilder:^(id<PDMediaCodecRequestBuilder>  _Nonnull builder) {
        builder.srcURL = [NSURL URLWithString:@""];
        builder.dstURL = [NSURL URLWithString:@""];
    }] sendWithDoneHandler:^(BOOL success, NSError * _Nullable error) {
        // TODO: codec finished...
    }];
}

@end
