#import "BrightnessManager.h"
#import <dlfcn.h>
#import <ApplicationServices/ApplicationServices.h>

typedef int (*GetBrightnessFn)(CGDirectDisplayID, float *);
typedef int (*SetBrightnessFn)(CGDirectDisplayID, float);
typedef int (*RegisterFn)(CGDirectDisplayID, CGDirectDisplayID, CFNotificationCallback);
typedef int (*UnregisterFn)(CGDirectDisplayID, CGDirectDisplayID);

@interface BrightnessManager ()
@property (nonatomic) GetBrightnessFn getBrightnessFn;
@property (nonatomic) SetBrightnessFn setBrightnessFn;
@property (nonatomic) RegisterFn registerFn;
@property (nonatomic) UnregisterFn unregisterFn;
@property (nonatomic) void *displayServicesHandle;
@property (nonatomic) BOOL isListening;
@end

// C-level brightness change callback
static void BrightnessCallback(CFNotificationCenterRef center,
                               void *observer,
                               CFNotificationName name,
                               const void *object,
                               CFDictionaryRef userInfo) {
    BrightnessManager *manager = [BrightnessManager sharedInstance];
    if ([NSThread isMainThread]) {
        [manager updateCurrentBrightness];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [manager updateCurrentBrightness];
        });
    }
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
    if (self.isListening) return;
    
    self.displayServicesHandle = dlopen(NULL, RTLD_LAZY);
    if (!self.displayServicesHandle) {
        NSLog(@"❌ Failed to dlopen.");
        return;
    }
    
    self.getBrightnessFn = (GetBrightnessFn)dlsym(self.displayServicesHandle, "DisplayServicesGetBrightness");
    self.setBrightnessFn = (SetBrightnessFn)dlsym(self.displayServicesHandle, "DisplayServicesSetBrightness");
    self.registerFn      = (RegisterFn)dlsym(self.displayServicesHandle, "DisplayServicesRegisterForBrightnessChangeNotifications");
    self.unregisterFn    = (UnregisterFn)dlsym(self.displayServicesHandle, "DisplayServicesUnregisterForBrightnessChangeNotifications");
    
    if (!self.getBrightnessFn || !self.setBrightnessFn || !self.registerFn || !self.unregisterFn) {
        NSLog(@"❌ One or more DisplayServices symbols could not be loaded.");
        return;
    }
    
    int result = self.registerFn(CGMainDisplayID(), CGMainDisplayID(), BrightnessCallback);
    if (result != 0) {
        NSLog(@"❌ Failed to register for brightness changes (code %d)", result);
    } else {
        NSLog(@"✅ Registered for brightness notifications");
        self.isListening = YES;
    }
    
    [self updateCurrentBrightness];
}

- (void)stop {
    if (!self.isListening || !self.unregisterFn) return;
    
    int result = self.unregisterFn(CGMainDisplayID(), CGMainDisplayID());
    if (result != 0) {
        NSLog(@"⚠️ Failed to unregister (code %d)", result);
    } else {
        NSLog(@"✅ Unregistered from brightness notifications");
        self.isListening = NO;
    }
    
    self.getBrightnessFn = NULL;
    self.setBrightnessFn = NULL;
    self.registerFn = NULL;
    self.unregisterFn = NULL;
    
    if (self.displayServicesHandle) {
        // Not strictly required, but if you want to clean up:
        // dlclose(self.displayServicesHandle);
        self.displayServicesHandle = NULL;
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
