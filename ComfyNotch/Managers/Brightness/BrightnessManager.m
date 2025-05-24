#import "BrightnessManager.h"
#import <ApplicationServices/ApplicationServices.h>
#import <IOKit/graphics/IOGraphicsLib.h>
#import <dlfcn.h>

typedef int (*GetBrightnessFn)(CGDirectDisplayID, float *);
typedef int (*SetBrightnessFn)(CGDirectDisplayID, float);
typedef int (*RegisterFn)(CGDirectDisplayID, CGDirectDisplayID, CFNotificationCallback);

// Forward declaration for the callback
static void BrightnessCallback(CFNotificationCenterRef center,
                               void *observer,
                               CFNotificationName name,
                               const void *object,
                               CFDictionaryRef userInfo) {
    [(BrightnessManager *)[BrightnessManager sharedInstance] updateCurrentBrightness];
}

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
    [self updateCurrentBrightness]; // Set it once on start
    [self registerListener];
}

- (void)updateCurrentBrightness {
    float value = [self brightness]; // Actually store the brightness
    self.currentBrightness = value;
}

- (float)brightness {
    void *handle = dlopen(NULL, RTLD_LAZY);
    GetBrightnessFn getBrightness = (GetBrightnessFn)dlsym(handle, "DisplayServicesGetBrightness");

    float level = 0.0;
    if (getBrightness) {
        getBrightness(CGMainDisplayID(), &level);
    } else {
        NSLog(@"❌ DisplayServicesGetBrightness not found.");
    }
    dlclose(handle);
    return level;
}

- (void)setBrightness:(float)level {
    void *handle = dlopen(NULL, RTLD_LAZY);
    SetBrightnessFn setBrightness = (SetBrightnessFn)dlsym(handle, "DisplayServicesSetBrightness");

    if (setBrightness) {
        setBrightness(CGMainDisplayID(), level);
    } else {
        NSLog(@"❌ DisplayServicesSetBrightness not found.");
    }
    dlclose(handle);
}

- (void)registerListener {
    void *handle = dlopen(NULL, RTLD_LAZY);
    RegisterFn registerFn = (RegisterFn)dlsym(handle, "DisplayServicesRegisterForBrightnessChangeNotifications");

    if (registerFn) {
        registerFn(CGMainDisplayID(), CGMainDisplayID(), BrightnessCallback);
    } else {
        NSLog(@"❌ DisplayServicesRegisterForBrightnessChangeNotifications not found.");
    }
    dlclose(handle);
}

- (float)getCurrentBrightnessLevel {
    return [self brightness];
}

@end
