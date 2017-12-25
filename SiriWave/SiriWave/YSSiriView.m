//
//  YSSiriView.m
//  SiriWave
//
//  Created by 杨森 on 2017/12/22.
//  Copyright © 2017年 yangsen. All rights reserved.
//

#import "YSSiriView.h"
#import <pthread/pthread.h>

@interface YSSiriLayer : CAShapeLayer

@property (nonatomic ,assign)CGFloat layerXScale;
@property (nonatomic ,assign)CGFloat height;

@end
@implementation YSSiriLayer
- (void)setHeight:(CGFloat)height{
    if (height < 0) {
        _height = 0;
    }else{
        _height = height;
    }
}
- (void)newUIData{
    if (_height < 0.02) {
        _height -= 0.005;
    }
    else{
        _height -= 0.02;
    }
        
    if (_layerXScale < 0.1){
        
    }
    else if(_layerXScale < 0.4){
        _layerXScale += 0.003;
    }
    else{
        _layerXScale -= 0.003;
    }
}
@end

@interface YSSiriView()
{
    CGFloat _lastPower;
    CGFloat _lineHalfH;
    CAShapeLayer *_lineLayer;
    NSMutableArray <YSSiriLayer *>*_subLayers;
}
@end
@implementation YSSiriView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setupData];
        [self setupUI];
    }
    return self;
}

- (void)setupData{
    _lineHalfH = 1.5;
    _lastPower = 0;
    _subLayers = [NSMutableArray array];
}
- (void)setupUI{
    CGFloat centerY = CGRectGetMidY(self.frame);
    _lineLayer = [self createSublayerWithColor:[UIColor whiteColor]];;
    _lineLayer.path = [self waveLineWithCenterY:centerY];
    [self.layer addSublayer:_lineLayer];
}

- (CGFloat)normalizedPowerLevelFromDecibels:(CGFloat)decibels
{
    if (decibels < -60.0f || decibels == 0.0f) {
        return 0.0f;
    }
    return powf((powf(10.0f, 0.05f * decibels) - powf(10.0f, 0.05f * -60.0f)) * (1.0f / (1.0f - powf(10.0f, 0.05f * -60.0f))), 1.0f / 2.0f);
}
- (void)updateWithSoundPower:(CGFloat)soundPower{

    soundPower = [self normalizedPowerLevelFromDecibels:soundPower]*8;
    NSLog(@"power:%.2lf",soundPower);
    CGFloat maxPower = 50;
    if (soundPower > maxPower) {
        soundPower = maxPower;
    }
    CGFloat centerY = CGRectGetMidY(self.frame);
    pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
    pthread_mutex_lock(&mutex);
    NSArray *subLayers = [_subLayers copy];
    for (YSSiriLayer *layer in subLayers) {
        if (layer.height <= 0) {
            [layer removeFromSuperlayer];
            [_subLayers removeObject:layer];
        }else{
            [layer newUIData];
            CGMutablePathRef path = NULL;
            [self mainOfWaveWithPath:&path centerY:centerY controlPointScale:CGPointMake(layer.layerXScale, (soundPower-_lastPower)/maxPower + layer.height)];
            layer.path = path;
            CGPathRelease(path);
        }
    }
    if ((_subLayers.count > 15)||
        (_subLayers.count > 10 && soundPower < 0.98) ||
        (_subLayers.count > 6 && soundPower < 0.5)   ||
        (_subLayers.count > 3 && soundPower < 0.01)  ||
        (soundPower-_lastPower <= 0 && soundPower > 0.01)) {
        pthread_mutex_unlock(&mutex);
        _lastPower = soundPower;
        return;
    }
    NSArray *colorArr = @[
                          [UIColor yellowColor],
                          [UIColor greenColor],
                          [UIColor blueColor],
                          [UIColor magentaColor],
                          [UIColor orangeColor],
                          [UIColor cyanColor],
                          ];
    UIColor *color = colorArr[arc4random()%6];
    NSInteger layerX   = arc4random()%100;
    YSSiriLayer *layer = [self createSublayerWithColor:color];
    CGPathRelease(layer.path);
    layer.path = NULL;
    CGMutablePathRef path = NULL;
    [self mainOfWaveWithPath:&path centerY:centerY controlPointScale:CGPointMake(layerX/100.0, soundPower)];
    layer.path = path;
    CGPathRelease(path);
    layer.layerXScale = layerX/100.0;
    layer.height      = soundPower;
    [self.layer insertSublayer:layer atIndex:1];
    [_subLayers addObject:layer];
    pthread_mutex_unlock(&mutex);
}

- (YSSiriLayer *)createSublayerWithColor:(UIColor *)color{

    YSSiriLayer *layer = [YSSiriLayer layer];
    layer.frame         = self.bounds;
    layer.fillColor     = [color colorWithAlphaComponent:0.4].CGColor;
    return layer;
}

- (CGMutablePathRef)waveLineWithCenterY:(CGFloat)centerY{
    
    CGFloat selfW = self.frame.size.width;
    
    CGFloat lineMaxX  = selfW/5;
    
    CGFloat marginLeft = 15;
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, marginLeft, centerY);
    CGPathAddLineToPoint(path, NULL, lineMaxX, centerY - _lineHalfH);
    CGPathAddLineToPoint(path, NULL, selfW - lineMaxX, centerY - _lineHalfH);
    CGPathAddLineToPoint(path, NULL, selfW - marginLeft, centerY);
    CGPathAddLineToPoint(path, NULL, selfW - lineMaxX, centerY + _lineHalfH);
    CGPathAddLineToPoint(path, NULL, lineMaxX, centerY + _lineHalfH);
    CGPathAddLineToPoint(path, NULL, marginLeft, centerY);

    return path;
}

- (CGMutablePathRef)mainOfWaveWithPath:(CGMutablePathRef *)path_p centerY:(CGFloat)centerY controlPointScale:(CGPoint)controlPointScale{
    
    CGFloat selfW = self.frame.size.width;
    CGFloat selfH = self.frame.size.height;
    CGFloat mainMaxH = [UIScreen mainScreen].bounds.size.height * 0.02;
    if (mainMaxH > selfH/2-2) {
        mainMaxH = selfH/2-2;
    }
    
    CGFloat space     = 6;
    CGFloat mainX     = selfW/5 - space;
    CGFloat mainMaxX  = selfW*4.0/5 + space;
    CGFloat waveW     = selfW/5;
    
    CGPoint controlPoint = CGPointMake(controlPointScale.x*mainMaxX + mainX, controlPointScale.y*mainMaxH + centerY);
    controlPoint.x = MAX(controlPoint.x, mainX+space+waveW/3);
    controlPoint.x = MIN(controlPoint.x, mainMaxX-space-waveW/3);

    CGFloat cp_1X = controlPoint.x-waveW/2;
    if (cp_1X < mainX+space) {
        cp_1X = mainX+space;
    }
    CGFloat cp_2X = controlPoint.x+waveW/2;
    if (cp_2X > mainMaxX-space) {
        cp_2X = mainMaxX-space;
    }
    CGFloat point_H = space/2;
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, mainX, centerY);
    // 上半部分
    CGPathAddLineToPoint(path, NULL, cp_1X, centerY-point_H);
//    CGPathAddQuadCurveToPoint(path, NULL, cp_1X, centerY, cp_1X, centerY-point_H);
    
    CGPathAddQuadCurveToPoint(path, NULL, controlPoint.x, 2*centerY- controlPoint.y, cp_2X, centerY-point_H);
    CGPathAddLineToPoint(path, NULL, mainMaxX, centerY);
//    CGPathAddQuadCurveToPoint(path, NULL, cp_2X, centerY, mainMaxX, centerY);
    
    CGPathMoveToPoint(path, NULL, mainX, centerY);
    // 下半部分
    CGPathAddLineToPoint(path, NULL, cp_1X, centerY+point_H);
//    CGPathAddQuadCurveToPoint(path, NULL, cp_1X, centerY, cp_1X, centerY+point_H);
    CGPathAddQuadCurveToPoint(path, NULL, controlPoint.x, controlPoint.y, cp_2X, centerY+point_H);
    CGPathAddLineToPoint(path, NULL, mainMaxX, centerY);
//    CGPathAddQuadCurveToPoint(path, NULL, cp_2X, centerY, mainMaxX, centerY);
    *path_p = path;
//    CGPathRelease(path);
    return NULL;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
