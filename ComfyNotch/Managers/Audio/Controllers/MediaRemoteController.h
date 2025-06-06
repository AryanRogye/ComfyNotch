
#ifndef MediaRemoteControllerBridge_h
#define MediaRemoteControllerBridge_h

#ifdef __cplusplus
extern "C" {
#endif

// Treat as opaque pointer — we don't expose the class directly to C/Swift
typedef void * MediaRemoteControllerRef;

MediaRemoteControllerRef createMediaRemoteController(void);
BOOL initializeMediaRemoteController(MediaRemoteControllerRef controller);
void getNowPlayingInfoController(MediaRemoteControllerRef controller, void (^completion)(BOOL));
void startMonitoringController(MediaRemoteControllerRef controller);
void stopMonitoringController(MediaRemoteControllerRef controller);
void sendPlayCommandController(MediaRemoteControllerRef controller);
void sendPauseCommandController(MediaRemoteControllerRef controller);
void sendTogglePlayPauseCommandController(MediaRemoteControllerRef controller);
void sendNextTrackCommandController(MediaRemoteControllerRef controller);
void sendPreviousTrackCommandController(MediaRemoteControllerRef controller);

#ifdef __cplusplus
}
#endif

#endif
