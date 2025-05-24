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

+ (instancetype)sharedInstance;

@property (nonatomic, assign) float currentBrightness;

- (void)setBrightness:(float)value;
- (void)start;
- (float)getCurrentBrightnessLevel;
- (void)updateCurrentBrightness;

@end

#endif /* BrightnessManager_h */
