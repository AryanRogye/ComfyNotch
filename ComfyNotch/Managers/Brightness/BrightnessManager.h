//
//  BrightnessManager.h
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/24/25.
//

#ifndef BrightnessManager_h
#define BrightnessManager_h

#import <Foundation/Foundation.h>

@interface BrightnessManager : NSObject

@property (nonatomic) float currentBrightness;

+ (instancetype)sharedInstance;

- (void)start;
- (void)stop;
- (void)setBrightness:(float)level;
- (float)getCurrentBrightnessLevel;
- (void)updateCurrentBrightness;

@end

#endif /* BrightnessManager_h */
