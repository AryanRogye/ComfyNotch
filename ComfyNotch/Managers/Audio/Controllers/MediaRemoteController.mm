//
//  MediaRemoteController.c
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/5/25.
//

//#ifdef __cplusplus
//extern "C" {
//#endif
//    
//#include "MediaRemoteController.h"
//#include "CoreFoundation/CoreFoundation.h"
//#include "stdio.h"
//#include <dlfcn.h>
//    
//    static void *handle = NULL;
//    
//    typedef void (^NowPlayingCallbackBlock)(CFDictionaryRef);
//    typedef void (*MRNowPlayingInfoFn)(dispatch_queue_t, NowPlayingCallbackBlock);
//    
//    
//    static MRNowPlayingInfoFn MRMediaRemoteGetNowPlayingInfo = NULL;
//    
//    void comfy_openMediaRemoteAPI(void) {
//        if (handle) return;
//        
//        handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW);
//        if (!handle) {
//            printf("❌ Failed to open MediaRemote\n");
//            return;
//        }
//        
//        MRMediaRemoteGetNowPlayingInfo = (MRNowPlayingInfoFn)dlsym(handle, "MRMediaRemoteGetNowPlayingInfo");
//        
//        if (!MRMediaRemoteGetNowPlayingInfo) {
//            printf("❌ Failed to find MRMediaRemoteGetNowPlayingInfo\n");
//        }
//    }
//    
//    void comfy_closeMediaRemoteAPI(void) {
//        if (handle) {
//            dlclose(handle);
//            handle = NULL;
//        }
//    }
//    
//    static void nowPlayingCallback(CFDictionaryRef info) {
//        if (info) {
//            CFShow(info);
//        }
//    }
//    
//    bool comfy_getNowPlayingInfoMM(void) {
//        if (!MRMediaRemoteGetNowPlayingInfo) {
//            printf("❌ MRMediaRemoteGetNowPlayingInfo is NULL\n");
//            return false;
//        }
//        
//        // Remove this line - you already loaded the symbol in comfy_openMediaRemoteAPI()
//        // MRMediaRemoteGetNowPlayingInfo = (MRNowPlayingInfoFn)dlsym(handle, "MRMediaRemoteGetNowPlayingInfo");
//        
//        MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef info) {
//            if (info) {
//                CFShow(info);
//            } else {
//                printf("No media playing or access denied\n");
//            }
//        });
//        
//        return true;
//    }
//    
//    
//#ifdef __cplusplus
//}
//#endif


#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <objc/runtime.h>

// MediaRemote function prototypes
typedef void (^MRMediaRemoteGetNowPlayingInfoCompletion)(CFDictionaryRef information);
typedef void (*MRMediaRemoteGetNowPlayingInfoFunction)(dispatch_queue_t queue, MRMediaRemoteGetNowPlayingInfoCompletion completion);

typedef void (^MRMediaRemoteGetNowPlayingApplicationIsPlayingCompletion)(Boolean isPlaying);
typedef void (*MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction)(dispatch_queue_t queue, MRMediaRemoteGetNowPlayingApplicationIsPlayingCompletion completion);

typedef void (*MRMediaRemoteSendCommandFunction)(unsigned int command, CFDictionaryRef userInfo);

// Command constants
#define kMRPlay 0
#define kMRPause 1
#define kMRTogglePlayPause 2
#define kMRStop 3
#define kMRNextTrack 4
#define kMRPreviousTrack 5

@interface MediaRemoteController : NSObject

@property (nonatomic, strong) NSMutableDictionary *nowPlayingInfo;
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, copy) void (^updateCallback)(NSDictionary *info, BOOL playing);

+ (instancetype)sharedController;
- (BOOL)initializeMediaRemote;
- (void)getNowPlayingInfo:(void (^)(BOOL success))completion;
- (void)sendPlayCommand;
- (void)sendPauseCommand;
- (void)sendTogglePlayPauseCommand;
- (void)sendNextTrackCommand;
- (void)sendPreviousTrackCommand;
- (void)startMonitoring;
- (void)stopMonitoring;

@end

@implementation MediaRemoteController {
    void *_mediaRemoteHandle;
    MRMediaRemoteGetNowPlayingInfoFunction _getNowPlayingInfo;
    MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction _getIsPlaying;
    MRMediaRemoteSendCommandFunction _sendCommand;
    NSTimer *_monitoringTimer;
}

+ (instancetype)sharedController {
    static MediaRemoteController *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[MediaRemoteController alloc] init];
    });
    return shared;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _nowPlayingInfo = [[NSMutableDictionary alloc] init];
        _isPlaying = NO;
    }
    return self;
}

- (BOOL)initializeMediaRemote {
    if (_mediaRemoteHandle) {
        return YES; // Already initialized
    }
    
    // Try multiple potential paths
    NSArray *possiblePaths = @[
        @"/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote",
         @"/System/Library/PrivateFrameworks/MediaRemote.framework/Versions/A/MediaRemote"
    ];
    
    for (NSString *path in possiblePaths) {
        _mediaRemoteHandle = dlopen([path UTF8String], RTLD_NOW | RTLD_LOCAL);
        if (_mediaRemoteHandle) {
            NSLog(@"Successfully loaded MediaRemote from: %@", path);
            break;
        }
    }
    
    if (!_mediaRemoteHandle) {
        NSLog(@"Failed to load MediaRemote framework");
        return NO;
    }
    
    // Load function symbols
    _getNowPlayingInfo = (MRMediaRemoteGetNowPlayingInfoFunction)dlsym(_mediaRemoteHandle, "MRMediaRemoteGetNowPlayingInfo");
    _getIsPlaying = (MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction)dlsym(_mediaRemoteHandle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying");
    _sendCommand = (MRMediaRemoteSendCommandFunction)dlsym(_mediaRemoteHandle, "MRMediaRemoteSendCommand");
    
    if (!_getNowPlayingInfo || !_sendCommand) {
        NSLog(@"Failed to load required MediaRemote functions");
        dlclose(_mediaRemoteHandle);
        _mediaRemoteHandle = NULL;
        return NO;
    }
    
    NSLog(@"MediaRemote initialized successfully");
    return YES;
}

- (void)getNowPlayingInfo:(void (^)(BOOL success))completion {
    if (![self initializeMediaRemote]) {
        if (completion) completion(NO);
        return;
    }
    
    // Create a serial queue for MediaRemote calls
    static dispatch_queue_t mediaRemoteQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mediaRemoteQueue = dispatch_queue_create("com.comfynotch.mediaremote", DISPATCH_QUEUE_SERIAL);
    });
    
    // Get now playing info
    _getNowPlayingInfo(mediaRemoteQueue, ^(CFDictionaryRef information) {
        if (information) {
            NSDictionary *info = (__bridge NSDictionary *)information;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self->_nowPlayingInfo setDictionary:info];
                NSLog(@"Got MediaRemote info: %@", info);
                
                if (self.updateCallback) {
                    self.updateCallback(info, self->_isPlaying);
                }
                
                if (completion) completion(YES);
            });
        } else {
            NSLog(@"No MediaRemote info available");
            if (completion) completion(NO);
        }
    });
    
    // Get playing state if function is available
    if (_getIsPlaying) {
        _getIsPlaying(mediaRemoteQueue, ^(Boolean isPlaying) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_isPlaying = isPlaying;
            });
        });
    }
}

- (void)sendPlayCommand {
    if ([self initializeMediaRemote] && _sendCommand) {
        _sendCommand(kMRPlay, NULL);
    }
}

- (void)sendPauseCommand {
    if ([self initializeMediaRemote] && _sendCommand) {
        _sendCommand(kMRPause, NULL);
    }
}

- (void)sendTogglePlayPauseCommand {
    if ([self initializeMediaRemote] && _sendCommand) {
        _sendCommand(kMRTogglePlayPause, NULL);
    }
}

- (void)sendNextTrackCommand {
    if ([self initializeMediaRemote] && _sendCommand) {
        _sendCommand(kMRNextTrack, NULL);
    }
}

- (void)sendPreviousTrackCommand {
    if ([self initializeMediaRemote] && _sendCommand) {
        _sendCommand(kMRPreviousTrack, NULL);
    }
}

- (void)startMonitoring {
    [self stopMonitoring]; // Stop any existing timer
    
    _monitoringTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                       repeats:YES
                                                         block:^(NSTimer * _Nonnull timer) {
                        [self getNowPlayingInfo:nil];
                        }];
}

- (void)stopMonitoring {
    if (_monitoringTimer) {
        [_monitoringTimer invalidate];
        _monitoringTimer = nil;
    }
}

- (void)dealloc {
    [self stopMonitoring];
    if (_mediaRemoteHandle) {
        dlclose(_mediaRemoteHandle);
    }
}

@end

// C interface for Swift
extern "C" {
    MediaRemoteController* createMediaRemoteController(void) {
        return [MediaRemoteController sharedController];
    }
    
    BOOL initializeMediaRemoteController(MediaRemoteController* controller) {
        return [controller initializeMediaRemote];
    }
    
    void getNowPlayingInfoController(MediaRemoteController* controller, void (^completion)(BOOL)) {
        [controller getNowPlayingInfo:completion];
    }
    
    void startMonitoringController(MediaRemoteController* controller) {
        [controller startMonitoring];
    }
    
    void stopMonitoringController(MediaRemoteController* controller) {
        [controller stopMonitoring];
    }
    
    void sendPlayCommandController(MediaRemoteController* controller) {
        [controller sendPlayCommand];
    }
    
    void sendPauseCommandController(MediaRemoteController* controller) {
        [controller sendPauseCommand];
    }
    
    void sendTogglePlayPauseCommandController(MediaRemoteController* controller) {
        [controller sendTogglePlayPauseCommand];
    }
    
    void sendNextTrackCommandController(MediaRemoteController* controller) {
        [controller sendNextTrackCommand];
    }
    
    void sendPreviousTrackCommandController(MediaRemoteController* controller) {
        [controller sendPreviousTrackCommand];
    }
}
