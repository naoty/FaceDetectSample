//
//  FDSViewController.m
//  FaceDetectSample
//
//  Created by 金子 直人 on 2013/08/07.
//  Copyright (c) 2013年 Naoto Kaneko. All rights reserved.
//

#import "FDSViewController.h"
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>

@interface FDSViewController ()

@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureVideoPreviewLayer *previewLayer;

@end

@implementation FDSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // セッションを初期化する
    self.session = [[AVCaptureSession alloc] init];
    
    // 画像の解像度を設定する
    if ([self.session canSetSessionPreset:AVCaptureSessionPresetMedium]) {
        self.session.sessionPreset = AVCaptureSessionPresetMedium;
    }
    
    // 前面カメラを取得する
    AVCaptureDevice *device;
    NSArray *captureDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *captureDevice in captureDevices) {
        if (captureDevice.position == AVCaptureDevicePositionFront) {
            device = captureDevice;
            break;
        }
    }
    if (!device) {
        device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    // 前面を入力として設定する
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    }
    
    // ビデオデータとして出力するように設定する
    AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    videoDataOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]}; // 出力フォーマットを指定する
    videoDataOutput.alwaysDiscardsLateVideoFrames = YES; // 処理に時間がかかるフレームを破棄する
    [videoDataOutput setSampleBufferDelegate:self queue:dispatch_queue_create("captureOutputQueue", NULL)]; // フレームを処理するデリゲート先とキューを指定する
    if ([self.session canAddOutput:videoDataOutput]) {
        [self.session addOutput:videoDataOutput];
    }
    
    // 1秒間あたり15回画像をキャプチャする
    AVCaptureConnection *videoConnection = [videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    videoConnection.videoMinFrameDuration = CMTimeMake(1, 15);
    
    // プレビューを表示するレイヤーを初期化する
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    CGSize rotatedSize = [self rotatedViewSize];
    self.previewLayer.frame = CGRectMake(0, 0, rotatedSize.width, rotatedSize.height);
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect; // アスペクト比を維持しつつ画面いっぱいに表示する
    self.previewLayer.connection.videoOrientation = [[UIApplication sharedApplication] statusBarOrientation]; // プレビューの向きをデバイスの向きに合わせる
    [self.view.layer addSublayer:self.previewLayer];
    
    // 入出力を開始する
    [self.session startRunning];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Local methods

- (CGSize)rotatedViewSize
{
    BOOL isPortrait = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]);
    CGFloat width = CGRectGetWidth(self.view.frame);
    CGFloat height = CGRectGetHeight(self.view.frame);
    
    float max = MAX(width, height);
    float min = MIN(width, height);
    
    return isPortrait ? CGSizeMake(min, max) : CGSizeMake(max, min);
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

// キャプチャしたフレームを処理する
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
}

@end
