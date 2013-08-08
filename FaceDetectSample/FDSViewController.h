//
//  FDSViewController.h
//  FaceDetectSample
//
//  Created by 金子 直人 on 2013/08/07.
//  Copyright (c) 2013年 Naoto Kaneko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

enum {
    PHOTOS_EXIF_0ROW_TOP_0COL_LEFT = 1,
    PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT = 2,
    PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT = 3,
    PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT = 4,
    PHOTOS_EXIF_0ROW_LEFT_0COL_TOP = 5,
    PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP = 6,
    PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM = 7,
    PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM = 8
};

@interface FDSViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>

@end
