//
//  FDSViewController.m
//  FaceDetectSample
//
//  Created by 金子 直人 on 2013/08/07.
//  Copyright (c) 2013年 Naoto Kaneko. All rights reserved.
//

#import "FDSViewController.h"
#import <CoreImage/CoreImage.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <QuartzCore/QuartzCore.h>

@interface FDSViewController ()

@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic) CIDetector *faceDetector;

@end

@implementation FDSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 顔検出器を初期化する
    NSDictionary *detectorOptions = @{CIDetectorAccuracy : CIDetectorAccuracyLow};
    self.faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    
    [self setupAVCapture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Local methods

- (void)setupAVCapture
{
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
    
    // 出力フォーマットを指定する
    videoDataOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]};
    
    // 処理に時間がかかるフレームを破棄する
    videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    
    // フレームを処理するデリゲート先とキューを指定する
    [videoDataOutput setSampleBufferDelegate:self queue:dispatch_queue_create("captureOutputQueue", NULL)];
    if ([self.session canAddOutput:videoDataOutput]) {
        [self.session addOutput:videoDataOutput];
    }
    
    // プレビューを表示するレイヤーを初期化する
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    CGSize rotatedSize = [self rotatedViewSize];
    self.previewLayer.frame = CGRectMake(0, 0, rotatedSize.width, rotatedSize.height);
    
    // アスペクト比を維持しつつ画面いっぱいに表示する
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    // プレビューの向きをデバイスの向きに合わせる
    self.previewLayer.connection.videoOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    // 1秒間あたり15回画像をキャプチャする
    self.previewLayer.connection.videoMinFrameDuration = CMTimeMake(1, 15);
    
    [self.view.layer addSublayer:self.previewLayer];
    
    // 入出力を開始する
    [self.session startRunning];
}

- (CGSize)rotatedViewSize
{
    BOOL isPortrait = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]);
    CGFloat width = CGRectGetWidth(self.view.frame);
    CGFloat height = CGRectGetHeight(self.view.frame);
    
    float max = MAX(width, height);
    float min = MIN(width, height);
    
    return isPortrait ? CGSizeMake(min, max) : CGSizeMake(max, min);
}

- (void)drawRectOnLayer:(CALayer *)layer center:(CGPoint)center
{
    CGFloat width = 30;
    CGFloat height = 30;
    
    CALayer *sublayer = [CALayer layer];
    sublayer.frame = CGRectMake(center.x - width / 2, center.y - height / 2, width, height);
    sublayer.backgroundColor = [[UIColor clearColor] CGColor];
    sublayer.borderColor = [[UIColor redColor] CGColor];
    sublayer.borderWidth = 2.0;
    
    // 削除するときのために名前をつける
    sublayer.name = @"FaceLayer";
    
    [layer addSublayer:sublayer];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

// キャプチャしたフレームを処理する
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // CIImageを取得する
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
    
    if (attachments) {
        CFRelease(attachments);
    }
    
    // 検出する際の画像の向きを指定する
    int exifOrientation = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 5 : 3;
    NSDictionary *imageOptions = @{CIDetectorImageOrientation : [NSNumber numberWithInt:exifOrientation]};
    
    // 顔検出を実行する
    NSArray *features = [self.faceDetector featuresInImage:ciImage options:imageOptions];
    
    if (features.count == 0) {
        NSLog(@"-");
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            // 以前に描画された図形を消去する
            NSArray *sublayers = [NSArray arrayWithArray:self.previewLayer.sublayers];
            for (CALayer *layer in sublayers) {
                if ([layer.name isEqualToString:@"FaceLayer"]) {
                    [layer removeFromSuperlayer];
                }
            }
        });
        
        return;
    } else {
        NSLog(@"Face detected");
    }
    
    // UIはメインスレッドで更新する
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        // 以前に描画された図形を消去する
        NSArray *sublayers = [NSArray arrayWithArray:self.previewLayer.sublayers];
        for (CALayer *layer in sublayers) {
            if ([layer.name isEqualToString:@"FaceLayer"]) {
                [layer removeFromSuperlayer];
            }
        }
        
        // 検出された顔の上に図形を描画する
        for (CIFaceFeature *feature in features) {
            if ([feature hasLeftEyePosition]) {
                [self drawRectOnLayer:self.previewLayer center:feature.leftEyePosition];
            }
            
            if ([feature hasRightEyePosition]) {
                [self drawRectOnLayer:self.previewLayer center:feature.rightEyePosition];
            }
            
            if ([feature hasMouthPosition]) {
                [self drawRectOnLayer:self.previewLayer center:feature.mouthPosition];
            }
        }
    });
}

@end
