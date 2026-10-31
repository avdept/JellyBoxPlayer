#import <Flutter/Flutter.h>

#ifndef AUDIO_SESSION_MICROPHONE
    #define AUDIO_SESSION_MICROPHONE 0
#endif

@interface DarwinAudioSession : NSObject

@property (readonly, nonatomic) FlutterMethodChannel *channel;

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar;

@end
