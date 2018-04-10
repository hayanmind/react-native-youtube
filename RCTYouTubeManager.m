#import "RCTYouTubeManager.h"
#import "RCTYouTube.h"
#if __has_include(<React/RCTAssert.h>)
#import <React/RCTUIManager.h>
#else // backwards compatibility for RN < 0.40
#import "RCTUIManager.h"
#endif

@implementation RCTYouTubeManager

RCT_EXPORT_MODULE();

@synthesize bridge = _bridge;

NSMutableDictionary<NSNumber *, NSTimer *> *reactTagToTimerForPolling;
NSMutableDictionary<NSNumber *, id> *reactTagToEndTimeReachedObserver;

- (UIView *)view {
    return [[RCTYouTube alloc] initWithBridge:self.bridge];
}

- (dispatch_queue_t)methodQueue {
    return _bridge.uiManager.methodQueue;
}

- (void) checkCurrentTime:(NSTimer *)timer {
    NSDictionary *data = (NSDictionary*)[timer userInfo];

    RCTYouTube *youtube = (RCTYouTube*)data[@"youtube"];
    NSNumber *endTimeInSec = (NSNumber*)data[@"endTimeInSec"];
    NSString *observerName = (NSString*)data[@"observerName"];
    NSNumber *reactTag = (NSNumber*)data[@"reactTag"];
    
    NSNumber *currentTimeInSec = [NSNumber numberWithFloat:[youtube currentTime]];
    if (currentTimeInSec) {
        if ([currentTimeInSec doubleValue] >= [endTimeInSec doubleValue]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:observerName object:nil];
            [timer invalidate];
            [reactTagToTimerForPolling removeObjectForKey:reactTag];
        }
    }
}

RCT_EXPORT_VIEW_PROPERTY(playerParams, NSDictionary);
RCT_EXPORT_VIEW_PROPERTY(videoId, NSString);
RCT_EXPORT_VIEW_PROPERTY(videoIds, NSArray);
RCT_EXPORT_VIEW_PROPERTY(playlistId, NSString);
RCT_EXPORT_VIEW_PROPERTY(play, BOOL);
RCT_EXPORT_VIEW_PROPERTY(loopProp, BOOL);

RCT_EXPORT_VIEW_PROPERTY(onError, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onReady, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onChangeState, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onChangeQuality, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onChangeFullscreen, RCTDirectEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onProgress, RCTDirectEventBlock);

RCT_EXPORT_METHOD(playAndPauseAt:(nonnull NSNumber *)reactTag
                  endTimeInSec:(nonnull NSNumber *)endTimeInSec
                  periodInSec:(nonnull NSNumber *)periodInSec
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        RCTYouTube *youtube = (RCTYouTube*)viewRegistry[reactTag];
        if ([youtube isKindOfClass:[RCTYouTube class]]) {
            NSNotificationCenter * __weak center = [NSNotificationCenter defaultCenter];
            NSString *observerName = [NSString stringWithFormat:@"endTimeReachedObserverFor%d", [reactTag intValue]];
            id __block endTimeReachedObserver = [center addObserverForName:observerName
                                                            object:nil
                                                             queue:nil
                                                        usingBlock:^(NSNotification *note){
                                                            [youtube pauseVideo];
                                                            [center removeObserver:endTimeReachedObserver];
                                                            [reactTagToEndTimeReachedObserver removeObjectForKey:reactTag];
                                                            resolve(nil);
                                                        }];
            if(reactTagToEndTimeReachedObserver == nil) {
                reactTagToEndTimeReachedObserver = [NSMutableDictionary dictionary];
            }
            reactTagToEndTimeReachedObserver[reactTag] = endTimeReachedObserver;

            NSDictionary *data = @{
                                   @"youtube": youtube,
                                   @"endTimeInSec": endTimeInSec,
                                   @"observerName": observerName,
                                   @"reactTag": reactTag
                                   };
            
            NSTimer *timerForPolling = [NSTimer scheduledTimerWithTimeInterval:[periodInSec doubleValue]
                                             target:self
                                           selector:@selector(checkCurrentTime:)
                                           userInfo:data
                                            repeats:YES];
            
            if(reactTagToTimerForPolling == nil) {
                reactTagToTimerForPolling = [NSMutableDictionary dictionary];
            }
            reactTagToTimerForPolling[reactTag] = timerForPolling;
            
            [youtube playVideo];
        } else {
            RCTLogError(@"Cannot playAndPauseAt: %@ (tag #%@) is not RCTYouTube", youtube, reactTag);
            NSError *error = nil;
            reject(@"Error playAndPauseAt of video from RCTYouTube", @"", error);
        }
    }];
}

RCT_EXPORT_METHOD(cancelPlayAndPauseAt:(nonnull NSNumber *)reactTag)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        RCTYouTube *youtube = (RCTYouTube*)viewRegistry[reactTag];
        if ([youtube isKindOfClass:[RCTYouTube class]]) {
            id endTimeReachedObserver = reactTagToEndTimeReachedObserver[reactTag];
            if (endTimeReachedObserver) {
                [[NSNotificationCenter defaultCenter] removeObserver:endTimeReachedObserver];
                [reactTagToEndTimeReachedObserver removeObjectForKey:reactTag];
            }
            
            NSTimer *timerForPolling = reactTagToTimerForPolling[reactTag];
            if (timerForPolling) {
                [timerForPolling invalidate];
                [reactTagToTimerForPolling removeObjectForKey:reactTag];
            }
            
            [youtube pauseVideo];
        } else {
            RCTLogError(@"Cannot cancelPlayAndPauseAt: %@ (tag #%@) is not RCTYouTube", youtube, reactTag);
        }
    }];
}

RCT_EXPORT_METHOD(play:(nonnull NSNumber *)reactTag)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        RCTYouTube *youtube = (RCTYouTube*)viewRegistry[reactTag];
        if ([youtube isKindOfClass:[RCTYouTube class]]) {
            [youtube playVideo];
        } else {
            RCTLogError(@"Cannot playVideo: %@ (tag #%@) is not RCTYouTube", youtube, reactTag);
        }
    }];
}

RCT_EXPORT_METHOD(pause:(nonnull NSNumber *)reactTag)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        RCTYouTube *youtube = (RCTYouTube*)viewRegistry[reactTag];
        if ([youtube isKindOfClass:[RCTYouTube class]]) {
            [youtube pauseVideo];
        } else {
            RCTLogError(@"Cannot pauseVideo: %@ (tag #%@) is not RCTYouTube", youtube, reactTag);
        }
    }];
}

RCT_EXPORT_METHOD(seekTo:(nonnull NSNumber *)reactTag seconds:(nonnull NSNumber *)seconds)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        RCTYouTube *youtube = (RCTYouTube*)viewRegistry[reactTag];
        if ([youtube isKindOfClass:[RCTYouTube class]]) {
            [youtube seekToSeconds:seconds.floatValue allowSeekAhead:YES];
        } else {
            RCTLogError(@"Cannot seekTo: %@ (tag #%@) is not RCTYouTube", youtube, reactTag);
        }
    }];
}

RCT_EXPORT_METHOD(nextVideo:(nonnull NSNumber *)reactTag)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        RCTYouTube *youtube = (RCTYouTube*)viewRegistry[reactTag];
        if ([youtube isKindOfClass:[RCTYouTube class]]) {
            [youtube nextVideo];
        } else {
            RCTLogError(@"Cannot nextVideo: %@ (tag #%@) is not RCTYouTube", youtube, reactTag);
        }
    }];
}

RCT_EXPORT_METHOD(previousVideo:(nonnull NSNumber *)reactTag)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        RCTYouTube *youtube = (RCTYouTube*)viewRegistry[reactTag];
        if ([youtube isKindOfClass:[RCTYouTube class]]) {
            [youtube previousVideo];
        } else {
            RCTLogError(@"Cannot previousVideo: %@ (tag #%@) is not RCTYouTube", youtube, reactTag);
        }
    }];
}

RCT_EXPORT_METHOD(playVideoAt:(nonnull NSNumber *)reactTag index:(nonnull NSNumber *)index)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        RCTYouTube *youtube = (RCTYouTube*)viewRegistry[reactTag];
        if ([youtube isKindOfClass:[RCTYouTube class]]) {
            [youtube playVideoAt:(int)[index integerValue]];
        } else {
            RCTLogError(@"Cannot playVideoAt: %@ (tag #%@) is not RCTYouTube", youtube, reactTag);
        }
    }];
}

RCT_EXPORT_METHOD(videosIndex:(nonnull NSNumber *)reactTag resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        RCTYouTube *youtube = (RCTYouTube*)viewRegistry[reactTag];
        if ([youtube isKindOfClass:[RCTYouTube class]]) {
            NSNumber *index = [NSNumber numberWithInt:[youtube playlistIndex]];
            if (index) {
                resolve(index);
            } else {
                NSError *error = nil;
                reject(@"Error getting index of video from RCTYouTube", @"", error);
            }
        } else {
            RCTLogError(@"Cannot videosIndex: %@ (tag #%@) is not RCTYouTube", youtube, reactTag);
        }
    }];
}

RCT_EXPORT_METHOD(currentTime:(nonnull NSNumber *)reactTag resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        RCTYouTube *youtube = (RCTYouTube*)viewRegistry[reactTag];
        if ([youtube isKindOfClass:[RCTYouTube class]]) {
            NSNumber *index = [NSNumber numberWithFloat:[youtube currentTime]];
            if (index) {
                resolve(index);
            } else {
                NSError *error = nil;
                reject(@"Error getting current time of video from RCTYouTube", @"", error);
            }
        } else {
            RCTLogError(@"Cannot currentTime: %@ (tag #%@) is not RCTYouTube", youtube, reactTag);
        }
    }];
}

@end
