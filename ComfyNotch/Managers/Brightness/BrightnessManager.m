#import "BrightnessManager.h"
#import <dlfcn.h>
#import <ApplicationServices/ApplicationServices.h>

typedef int (*GetBrightnessFn)(CGDirectDisplayID, float *);
typedef int (*SetBrightnessFn)(CGDirectDisplayID, float);
typedef int (*RegisterFn)(CGDirectDisplayID, CGDirectDisplayID, CFNotificationCallback);

@interface BrightnessManager ()
@property (nonatomic) GetBrightnessFn getBrightnessFn;
@property (nonatomic) SetBrightnessFn setBrightnessFn;
@property (nonatomic) RegisterFn registerFn;
@end

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
    void *handle = dlopen(NULL, RTLD_LAZY);
    self.getBrightnessFn = (GetBrightnessFn)dlsym(handle, "DisplayServicesGetBrightness");
    self.setBrightnessFn = (SetBrightnessFn)dlsym(handle, "DisplayServicesSetBrightness");
    self.registerFn = (RegisterFn)dlsym(handle, "DisplayServicesRegisterForBrightnessChangeNotifications");
    dlclose(handle);

    if (!self.getBrightnessFn || !self.setBrightnessFn || !self.registerFn) {
        NSLog(@"❌ One or more DisplayServices symbols could not be loaded.");
        return;
    }

    [self updateCurrentBrightness];
    [self registerListener];
}

- (void)updateCurrentBrightness {
    float value = [self brightness]; // Actually store the brightness
    self.currentBrightness = value;
}

- (float)brightness {
    float level = 0.0;
    if (self.getBrightnessFn) {
        self.getBrightnessFn(CGMainDisplayID(), &level);
    } else {
        NSLog(@"❌ getBrightnessFn is nil.");
    }
    return level;
}

- (void)setBrightness:(float)level {
    if (self.setBrightnessFn) {
        self.setBrightnessFn(CGMainDisplayID(), level);
    } else {
        NSLog(@"❌ setBrightnessFn is nil.");
    }
}

- (void)registerListener {
    if (self.registerFn) {
        self.registerFn(CGMainDisplayID(), CGMainDisplayID(), BrightnessCallback);
    } else {
        NSLog(@"❌ registerFn is nil.");
    }
}


- (float)getCurrentBrightnessLevel {
    return [self brightness];
}

- (void)stop {
    self.getBrightnessFn = NULL;
    self.setBrightnessFn = NULL;
    self.registerFn = NULL;
}

@end
