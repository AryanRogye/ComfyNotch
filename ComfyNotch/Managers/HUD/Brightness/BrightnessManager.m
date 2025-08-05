#import "BrightnessManager.h"
#import "ComfyNotch-Swift.h"
#import <dlfcn.h>
#import <ApplicationServices/ApplicationServices.h>

typedef int (*GetBrightnessFn)(CGDirectDisplayID, float *);
typedef int (*SetBrightnessFn)(CGDirectDisplayID, float);

@interface BrightnessManager ()
@property (nonatomic) GetBrightnessFn getBrightnessFn;
@property (nonatomic) SetBrightnessFn setBrightnessFn;
@property (nonatomic) void *displayServicesHandle;
@end

@implementation BrightnessManager

+ (instancetype)sharedInstance {
    static BrightnessManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)start {
    self.displayServicesHandle = dlopen(NULL, RTLD_LAZY);
    if (!self.displayServicesHandle) {
        NSLog(@"❌ Failed to dlopen.");
        return;
    }
    
    self.getBrightnessFn = (GetBrightnessFn)dlsym(self.displayServicesHandle, "DisplayServicesGetBrightness");
    self.setBrightnessFn = (SetBrightnessFn)dlsym(self.displayServicesHandle, "DisplayServicesSetBrightness");
    
    if (!self.getBrightnessFn || !self.setBrightnessFn) {
        NSLog(@"❌ Brightness functions could not be loaded.");
        return;
    }
    
    [self updateCurrentBrightness];
}

- (void)stop {
    self.getBrightnessFn = NULL;
    self.setBrightnessFn = NULL;
    
    if (self.displayServicesHandle) {
        self.displayServicesHandle = NULL;
    }
}

- (void)handleMediaKeyCode:(int)keyCode {
    switch (keyCode) {
        case NX_KEYTYPE_BRIGHTNESS_DOWN:
        case NX_KEYTYPE_BRIGHTNESS_UP:
        case NX_KEYTYPE_ILLUMINATION_DOWN:
        case NX_KEYTYPE_ILLUMINATION_UP: {
            NSLog(@"🔆 Brightness key pressed: %d", keyCode);
            
            [self updateCurrentBrightness];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"TriggerBrightnessHUD"
                                                                    object:nil
                                                                  userInfo:nil];
            });
            
            [[UIManagerBridge shared] triggerBrightnessLayout];
            [[UIManagerBridge shared] setBrightness:[self getCurrentBrightnessLevel]];
            
            break;
        }
        default:
            break;
    }
}

- (float)brightness {
    float level = 0.0;
    if (self.getBrightnessFn) {
        int result = self.getBrightnessFn(CGMainDisplayID(), &level);
        if (result != 0) {
            NSLog(@"❌ Failed to get brightness (code %d)", result);
        }
    }
    return level;
}

- (void)setBrightness:(float)level {
    if (self.setBrightnessFn) {
        int result = self.setBrightnessFn(CGMainDisplayID(), level);
        if (result != 0) {
            NSLog(@"❌ Failed to set brightness (code %d)", result);
        }
    }
}

- (void)updateCurrentBrightness {
    self.currentBrightness = [self brightness];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BrightnessDidChange"
                                                        object:self
                                                      userInfo:@{@"value": @(self.currentBrightness)}];
}

- (float)getCurrentBrightnessLevel {
    return self.currentBrightness;
}

@end
