
#import "RNMlKit.h"

#import <React/RCTBridge.h>

#import <GoogleMLKit/MLKit.h>

@implementation RNMlKit

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

static NSString *const detectionNoResultsMessage = @"Something went wrong";

RCT_REMAP_METHOD(deviceTextRecognition, deviceTextRecognition:(NSString *)imagePath resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    if (!imagePath) {
        resolve(@NO);
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //FIRVision *vision = [FIRVision vision];
        //FIRVisionTextRecognizer *textRecognizer = [vision onDeviceTextRecognizer];

        MLKTextRecognizer *textRecognizer = [MLKTextRecognizer textRecognizer];
        NSDictionary *d = [[NSDictionary alloc] init];
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:imagePath]];
        UIImage *image = [UIImage imageWithData:imageData];

        if (!image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                resolve(@NO);
            });
            return;
        }

        
        MLKVisionImage *handler = [[MLKVisionImage alloc] initWithImage:image];
        handler.orientation = image.imageOrientation;

        [textRecognizer processImage:handler completion:^(MLKText *_Nullable result, NSError *_Nullable error) {
            if (error != nil || result == nil) {
                NSString *errorString = error ? error.localizedDescription : detectionNoResultsMessage;
                NSDictionary *pData = @{
                                        @"error": [NSMutableString stringWithFormat:@"On-Device text detection failed with error: %@", errorString],
                                        };
                // Running on background thread, don't call UIKit
                dispatch_async(dispatch_get_main_queue(), ^{
                    resolve(pData);
                });
                return;
            }

            CGRect boundingBox;
            CGSize size;
            CGPoint origin;
            NSMutableArray *output = [NSMutableArray array];

            for (MLKTextBlock *block in result.blocks) {
                NSMutableDictionary *blocks = [NSMutableDictionary dictionary];
                NSMutableDictionary *bounding = [NSMutableDictionary dictionary];
                NSString *blockText = block.text;

                bounding[@"left"]=[NSString stringWithFormat: @"%f", block.cornerPoints[0].CGVectorValue.dx];
                bounding[@"top"]=[NSString stringWithFormat: @"%f", block.cornerPoints[0].CGVectorValue.dy];

                bounding[@"width"]=[NSString stringWithFormat: @"%f", block.cornerPoints[2].CGVectorValue.dx-block.cornerPoints[0].CGVectorValue.dx];
                bounding[@"height"]=[NSString stringWithFormat: @"%f", block.cornerPoints[2].CGVectorValue.dy - block.cornerPoints[0].CGVectorValue.dy];

                blocks[@"resultText"] = result.text;
                blocks[@"blockText"] = block.text;
                blocks[@"blockCoordinates"] = bounding;

                [output addObject:blocks];

                for (MLKTextLine *line in block.lines) {
                    NSMutableDictionary *lines = [NSMutableDictionary dictionary];
                    lines[@"lineText"] = line.text;
                    [output addObject:lines];

                    for (MLKTextElement *element in line.elements) {
                        NSMutableDictionary *elements = [NSMutableDictionary dictionary];
                        elements[@"elementText"] = element.text;
                        [output addObject:elements];

                    }
                }
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                resolve(output);
            });
        }];
    });
    
}

@end
