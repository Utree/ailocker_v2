//
//  CapturedImageController.h
//  AiLocker
//
//  Created by sekiya on 2019/03/23.
//  Copyright © 2019 sekiya. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// TensorFlow Lite was migrated out of `contrib/` directory. The change
// wasn't reflected in newest CocoaPod release yet (1.12.0).
// Change this to 0 when using a TFLite version which is newer than 1.12.0.
// TODO(ycling): Remove the macro when we release the next version.
#ifndef TFLITE_USE_CONTRIB_LITE
#define TFLITE_USE_CONTRIB_LITE 1
#endif

// Set TFLITE_USE_GPU_DELEGATE to 1 to use TFLite GPU Delegate.
// Note: TFLite GPU Delegate binary isn't releast yet, and we're working
// on it.
#ifndef TFLITE_USE_GPU_DELEGATE
#define TFLITE_USE_GPU_DELEGATE 0
#endif

#if TFLITE_USE_GPU_DELEGATE && TFLITE_USE_CONTRIB_LITE
// Sanity check.
#error "GPU Delegate only works with newer TFLite " \
"after migrating out of contrib"
#endif

@interface CapturedImageController : NSObject {
    NSMutableDictionary* oldPredictionValues;
    NSMutableArray* labelLayers;
    
    //    std::vector<std::string> labels;
    double total_latency;
    int total_count;
}

-(NSString*)abc:(CVPixelBufferRef)pixelBuffer;
-(void) loadModel;

@end
