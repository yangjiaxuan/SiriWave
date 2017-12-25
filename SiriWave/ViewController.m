//
//  ViewController.m
//  SiriWave
//
//  Created by 杨森 on 2017/12/22.
//  Copyright © 2017年 yangsen. All rights reserved.
//

#import "ViewController.h"
#import "YSSiriView.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()
{
    YSSiriView *_siriView;
}
@property (nonatomic, strong) AVAudioRecorder *recorder;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;
    _siriView = [[YSSiriView alloc] initWithFrame:CGRectMake(0, 64, screenW, screenH-64)];
    _siriView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_siriView];
    
    NSDictionary *settings = @{AVSampleRateKey:          [NSNumber numberWithFloat: 44100.0],
                               AVFormatIDKey:            [NSNumber numberWithInt: kAudioFormatAppleLossless],
                               AVNumberOfChannelsKey:    [NSNumber numberWithInt: 2],
                               AVEncoderAudioQualityKey: [NSNumber numberWithInt: AVAudioQualityMin]};
    
    NSError *error;
    NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
    self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    
    if (error) {
        NSLog(@"Error setting category: %@", [error description]);
        return;
    }
    
    CADisplayLink *displaylink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateMeters)];
    [displaylink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];

    [self.recorder prepareToRecord];
    [self.recorder setMeteringEnabled:YES];
    [self.recorder record];
}



- (void)updateMeters
{
    [self.recorder updateMeters];
    [_siriView updateWithSoundPower:[self.recorder averagePowerForChannel:0]];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
}

@end
