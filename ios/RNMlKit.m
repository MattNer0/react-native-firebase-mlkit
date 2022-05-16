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

        MLKTextRecognizer *textRecognizer = [MLKTextRecognizer textRecognizer];
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

            NSMutableArray *textBlocks = [[NSMutableArray alloc] init];
            for (MLKTextBlock *textBlock in result.blocks) {
                NSDictionary *textBlockDict = 
                @{@"type": @"block", @"value" : textBlock.text, @"bounds" : [self processBounds:textBlock.frame], @"components" : [self processLine:textBlock.lines]};
                [textBlocks addObject:textBlockDict];
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                resolve(textBlocks);
            });
        }];
    });
    
}


- (NSArray *)processLine:(NSArray *)lines
{
  NSMutableArray *lineBlocks = [[NSMutableArray alloc] init];
  for (MLKTextLine *textLine in lines) {
        NSDictionary *textLineDict = 
        @{@"type": @"line", @"value" : textLine.text, @"bounds" : [self processBounds:textLine.frame], @"components" : [self processElement:textLine.elements]};
        [lineBlocks addObject:textLineDict];
  }
  return lineBlocks;
}

- (NSArray *)processElement:(NSArray *)elements
{
  NSMutableArray *elementBlocks = [[NSMutableArray alloc] init];
  for (MLKTextElement *textElement in elements) {
        NSDictionary *textElementDict = 
        @{@"type": @"element", @"value" : textElement.text, @"bounds" : [self processBounds:textElement.frame]};
        [elementBlocks addObject:textElementDict];
  }
  return elementBlocks;
}

- (NSDictionary *)processBounds:(CGRect)bounds
{
  float width = bounds.size.width;
  float height = bounds.size.height;
  float originX = bounds.origin.x;
  float originY = bounds.origin.y;
  NSDictionary *boundsDict =
  @{
    @"size" : 
              @{
                @"width" : @(width), 
                @"height" : @(height)
                }, 
    @"origin" : 
              @{
                @"x" : @(originX),
                @"y" : @(originY)
                }
    };
  return boundsDict;
}

@end
