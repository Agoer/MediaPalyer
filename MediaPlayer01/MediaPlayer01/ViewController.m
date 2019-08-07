//
//  ViewController.m
//  MediaPlayer01
//
//  Created by yixin on 2019/8/7.
//  Copyright © 2019 IUTeam. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>

//前置摄像头
@property (strong, nonatomic)AVCaptureDeviceInput *captureDeviceInput;

//视频输出
@property (strong, nonatomic)AVCaptureVideoDataOutput *captureVideoDataOutput;

//采集管理类
@property (strong, nonatomic)AVCaptureSession *captureSession;

//AVCaptureSession用来建立和维护AVCaptureInput和AVCaptureOutput之间的连接的
@property (strong, nonatomic)AVCaptureConnection *captureConnection;

//预览采集到的视频图像的
@property (strong, nonatomic)AVCaptureVideoPreviewLayer *videoPreviewLayer;

@property (assign, nonatomic) BOOL isCapturing;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //视频输入设定：
//    AVMediaTypeVideo
//    指定视频
    
//    AVMediaTypeAudio
//    指定音频
//
//
//    AVMediaTypeText
//    指定文本
//
//
//    AVMediaTypeClosedCaption
//    指定闭路内容
//
//
//    AVMediaTypeSubtitle
//    指定字幕
//
//
//    AVMediaTypeTimecode
//    指定一个时间代码
//
//
//    AVMediaTypeMetadata
//    指定元数据
//
//
//    AVMediaTypeMuxed
//    指定mux媒体
//
//
//    AVMediaTypeMetadataObject
//
//
//
//    AVMediaTypeDepthData
//
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    //设置前置摄像头，或者设置 后置摄像头
    //AVCaptureDevicePositionBack 、AVCaptureDevicePositionFront
    NSArray *captureDeviceArray = [cameras filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"position == %d", AVCaptureDevicePositionBack]];
    if (!captureDeviceArray.count)
    {
        NSLog(@"获取前置摄像头失败");
        return;
    }
    AVCaptureDevice *camera = captureDeviceArray.firstObject;
    
    NSError *errorMessage = nil;
    self.captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&errorMessage];
    if (errorMessage) {
        NSLog(@"AVCaptureDevice转AVCaptureDeviceInput失败");
        return;
    }
    
    //视频输出设定
    self.captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc]init];
    
    //YUV 格式返回
    NSDictionary *videoSetting = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)};
    
    [self.captureVideoDataOutput setVideoSettings:videoSetting];
    
    dispatch_queue_t outputQueue = dispatch_queue_create("ACVideoCaptureOutputQueue", DISPATCH_QUEUE_SERIAL);
    [self.captureVideoDataOutput setSampleBufferDelegate:self queue:outputQueue];
    self.captureVideoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    // Do any additional setup after loading the view.
    
//    初始化AVCaptureSession并设置输入输出
    self.captureSession = [[AVCaptureSession alloc]init];
    self.captureSession.usesApplicationAudioSession = NO;
    if ([self.captureSession canAddInput:self.captureDeviceInput]) {
        [self.captureSession addInput:self.captureDeviceInput];
    }
    if ([self.captureSession canAddOutput:self.captureVideoDataOutput]) {
        [self.captureSession addOutput:self.captureVideoDataOutput];
    }
    //设置分辨率
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    }
    
    // 获取连接并设置视频方向为竖屏方向
    self.captureConnection = [self.captureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    self.captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    // 设置是否为镜像，前置摄像头采集到的数据本来就是翻转的，这里设置为镜像把画面转回来
    if (camera.position == AVCaptureDevicePositionFront && self.captureConnection.supportsVideoMirroring) {
        self.captureConnection.videoMirrored = YES;
    }
    // 获取预览Layer并设置视频方向，注意self.videoPreviewLayer.connection跟self.captureConnection不是同一个对象，要分开设置
    self.videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [self.view.layer insertSublayer:self.videoPreviewLayer atIndex:0];

    self.videoPreviewLayer.frame = self.view.layer.bounds;
    
    [self startCapture];
}

- (BOOL)startCapture {
    if (self.isCapturing) {
        return NO;
    }
    //摄像头权限
    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (videoAuthStatus != AVAuthorizationStatusAuthorized) {
        return NO;
    }
    [self.captureSession startRunning];
    self.isCapturing = YES;
    return NO;
}

- (IBAction)autoFocusRangeRestrictionButtonPressed:(id)sender {
    AVCaptureDevice *device = self.captureDeviceInput.device;
//            device.autoFocusRangeRestriction
}

- (IBAction)whiteBalanceModeButtonPressed:(id)sender {
    AVCaptureDevice *device = self.captureDeviceInput.device;
//        device.whiteBalanceMode
}

- (IBAction)exposureModeButtonPressed:(id)sender {
    AVCaptureDevice *device = self.captureDeviceInput.device;
//    device.exposureMode
}

- (IBAction)focusModeButtonPressed:(id)sender {
    // 获取所有摄像头
    if(!self.captureDeviceInput) {
        return;
    }
    AVCaptureDevice *device = self.captureDeviceInput.device;
    NSError *errorProperty = nil;
    if ([device isFocusModeSupported:AVCaptureFocusModeLocked]) {
        BOOL result = NO;
        result = [device lockForConfiguration:&errorProperty];
        if (result) {
            //do some thing
        } else {
            NSLog(@" ERROR CODE:%ld", (long)errorProperty.code);
        }
        [device unlockForConfiguration];
    } else {
        NSLog(@"AVCaptureFocusModeLocked is not Supported");
    }
    
}

- (IBAction)flashModeButtonPressed:(id)sender {
    // 获取所有摄像头
    if(!self.captureDeviceInput) {
        return;
    }
    AVCaptureDevice *device = self.captureDeviceInput.device;
    NSError *errorProperty = nil;
    if([device hasFlash]) {
        if ([device isFlashAvailable]) {
            if ([device isFlashModeSupported:AVCaptureFlashModeOn]) {
                BOOL result = NO;
                result = [device lockForConfiguration:&errorProperty];
                if (result) {
                    switch (device.flashMode) {
                        case AVCaptureFlashModeOn:
                            [device setFlashMode:AVCaptureFlashModeOff];
                            [device setTorchMode:AVCaptureTorchModeOff];
                            break;
                        case AVCaptureFlashModeOff:
                            [device setFlashMode:AVCaptureFlashModeOn];
                            [device setTorchMode:AVCaptureTorchModeOn];
                            break;
                    }
                   
                } else {
                    NSLog(@"ERROR : CONFIGURATION CAPTURE DEVICE FLASH FAILURE, ERROR CODE:%ld", (long)errorProperty.code);
                }
                [device unlockForConfiguration];
            } else {
                NSLog(@"AVCaptureFlashModeOn is not Supported");
            }
            
        } else {
            NSLog(@"ERROR : FLASH is not Available");
        }
    } else {
        NSLog(@"ERROR : HAVE NO FLASH");
    }
    
}

- (IBAction)devicePositionButtonPressed:(id)sender {
    // 获取所有摄像头
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    // 获取当前摄像头方向
    AVCaptureDevicePosition currentPosition = self.captureDeviceInput.device.position;
    AVCaptureDevicePosition toPosition = AVCaptureDevicePositionUnspecified;
    if (currentPosition == AVCaptureDevicePositionBack || currentPosition == AVCaptureDevicePositionUnspecified)
    {
        toPosition = AVCaptureDevicePositionFront;
    } else {
        toPosition = AVCaptureDevicePositionBack;
    }
    NSArray *captureDeviceArray = [cameras filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"position == %d", toPosition]];
    if (captureDeviceArray.count == 0)
    {
        NSLog(@"改变摄像头前后失败");
        return;
    }
    NSError *error = nil;
    AVCaptureDevice *camera = captureDeviceArray.firstObject;
    // 开始配置
    [self.captureSession beginConfiguration];
    AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&error];
    [self.captureSession removeInput:self.captureDeviceInput];
    if ([self.captureSession canAddInput:newInput])
    {
        [self.captureSession addInput:newInput];
        self.captureDeviceInput = newInput;
    }
    // 提交配置
    [self.captureSession commitConfiguration];
    
    // 重新获取连接并设置视频的方向、是否镜像
    self.captureConnection = [self.captureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    self.captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    if (camera.position == AVCaptureDevicePositionFront && self.captureConnection.supportsVideoMirroring)
    {
        self.captureConnection.videoMirrored = YES;
    }
}



#pragma mark- AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
//    NSLog(@"采集中...");
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    NSLog(@"丢弃帧中...");
}


@end
