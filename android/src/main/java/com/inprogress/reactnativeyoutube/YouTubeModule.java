package com.inprogress.reactnativeyoutube;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.uimanager.IllegalViewOperationException;
import com.facebook.react.uimanager.NativeViewHierarchyManager;
import com.facebook.react.uimanager.UIBlock;
import com.facebook.react.uimanager.UIManagerModule;

import java.util.HashMap;
import java.util.Map;
import java.util.Timer;
import java.util.TimerTask;


public class YouTubeModule extends ReactContextBaseJavaModule {

    private static final String E_MODULE_ERROR = "E_MODULE_ERROR";

    private ReactApplicationContext mReactContext;

    private Map<Integer, Timer> reactTagToTimerForPolling = new HashMap<Integer, Timer>();

    public YouTubeModule(ReactApplicationContext reactContext) {
        super(reactContext);
        mReactContext = reactContext;
    }

    @Override
    public String getName() {
        return "YouTubeModule";
    }

    @ReactMethod
    public void play(final int reactTag) {
        UIManagerModule uiManager = mReactContext.getNativeModule(UIManagerModule.class);
        uiManager.addUIBlock(new UIBlock() {
            public void execute (NativeViewHierarchyManager nvhm) {
                YouTubeView youTubeView = (YouTubeView) nvhm.resolveView(reactTag);
                youTubeView.play();
            }
        });
    }

    @ReactMethod
    public void pause(final int reactTag) {
        UIManagerModule uiManager = mReactContext.getNativeModule(UIManagerModule.class);
        uiManager.addUIBlock(new UIBlock() {
            public void execute (NativeViewHierarchyManager nvhm) {
                YouTubeView youTubeView = (YouTubeView) nvhm.resolveView(reactTag);
                youTubeView.pause();
            }
        });
    }

    @ReactMethod
    public void playAndPauseAt(final int reactTag, final float endTimeInSec, final float periodInSec, final Promise promise) {
        try {
            UIManagerModule uiManager = mReactContext.getNativeModule(UIManagerModule.class);
            uiManager.addUIBlock(new UIBlock() {
                public void execute (NativeViewHierarchyManager nvhm) {
                    final YouTubeView youTubeView = (YouTubeView) nvhm.resolveView(reactTag);

                    final Timer timerForPolling = new Timer();
                    reactTagToTimerForPolling.put(reactTag, timerForPolling);

                    TimerTask pausePlayerAtEndTime = new TimerTask() {

                        @Override
                        public void run() {
                            float currentTimeInSec = youTubeView.getCurrentTime();
                            if (currentTimeInSec >= endTimeInSec) {
                                youTubeView.pause();
                                timerForPolling.cancel();
                                reactTagToTimerForPolling.remove(reactTag);
                                promise.resolve(null);
                            }
                        }
                    };
                    timerForPolling.scheduleAtFixedRate(pausePlayerAtEndTime, 0, (long) (periodInSec * 1000));
                    youTubeView.play();
                }
            });
        } catch (IllegalViewOperationException e) {
            promise.reject(E_MODULE_ERROR, e);
        }
    }

    @ReactMethod
    public void cancelPlayAndPauseAt(final int reactTag) {
        UIManagerModule uiManager = mReactContext.getNativeModule(UIManagerModule.class);
        uiManager.addUIBlock(new UIBlock() {
            public void execute (NativeViewHierarchyManager nvhm) {
                YouTubeView youTubeView = (YouTubeView) nvhm.resolveView(reactTag);

                Timer timerForPolling = reactTagToTimerForPolling.get(reactTag);
                if (timerForPolling != null) {
                    timerForPolling.cancel();
                    reactTagToTimerForPolling.remove(reactTag);
                }
                youTubeView.pause();
            }
        });
    }

    @ReactMethod
    public void videosIndex(final int reactTag, final Promise promise) {
        try {
            UIManagerModule uiManager = mReactContext.getNativeModule(UIManagerModule.class);
            uiManager.addUIBlock(new UIBlock() {
                public void execute (NativeViewHierarchyManager nvhm) {
                    YouTubeView youTubeView = (YouTubeView) nvhm.resolveView(reactTag);
                    YouTubeManager youTubeManager = (YouTubeManager) nvhm.resolveViewManager(reactTag);
                    int index = youTubeManager.getVideosIndex(youTubeView);
                    promise.resolve(index);
                }
            });
        } catch (IllegalViewOperationException e) {
            promise.reject(E_MODULE_ERROR, e);
        }
    }

    @ReactMethod
    public void currentTime(final int reactTag, final Promise promise) {
        try {
            UIManagerModule uiManager = mReactContext.getNativeModule(UIManagerModule.class);
            uiManager.addUIBlock(new UIBlock() {
                public void execute (NativeViewHierarchyManager nvhm) {
                    YouTubeView youTubeView = (YouTubeView) nvhm.resolveView(reactTag);
                    YouTubeManager youTubeManager = (YouTubeManager) nvhm.resolveViewManager(reactTag);
                    float currentTime = youTubeManager.getCurrentTime(youTubeView);
                    promise.resolve(currentTime);
                }
            });
        } catch (IllegalViewOperationException e) {
            promise.reject(E_MODULE_ERROR, e);
        }
    }

    @ReactMethod
    public void duration(final int reactTag, final Promise promise) {
        try {
            UIManagerModule uiManager = mReactContext.getNativeModule(UIManagerModule.class);
            uiManager.addUIBlock(new UIBlock() {
                public void execute (NativeViewHierarchyManager nvhm) {
                    YouTubeView youTubeView = (YouTubeView) nvhm.resolveView(reactTag);
                    YouTubeManager youTubeManager = (YouTubeManager) nvhm.resolveViewManager(reactTag);
                    float duration = youTubeManager.getDuration(youTubeView);
                    promise.resolve(duration);
                }
            });
        } catch (IllegalViewOperationException e) {
            promise.reject(E_MODULE_ERROR, e);
        }
    }
}
