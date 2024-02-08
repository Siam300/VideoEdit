//
//  ViewController.m
//  VideoEdit
//
//  Created by Auto on 8/2/24.
//

#import "ViewController.h"
#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@interface ViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) NSURL *selectedVideoURL;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(20, 20, 200, 30)];
    [self.view addSubview:self.textField];

    // Create AVPlayer and AVPlayerLayer
    self.player = [AVPlayer playerWithURL:self.selectedVideoURL];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = CGRectMake(0, 100, self.view.frame.size.width, 300);
    [self.view.layer addSublayer:self.playerLayer];
}

- (IBAction)textField:(id)sender {
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    self.selectedVideoURL = info[UIImagePickerControllerMediaURL];
    [self playSelectedVideo];
}

- (void)playSelectedVideo {
    [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:self.selectedVideoURL]];
    [self.player play];
}

- (IBAction)selectVideo:(id)sender {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    imagePicker.mediaTypes = @[(NSString *)kUTTypeMovie];
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (IBAction)saveAndExportVideo:(id)sender {
    if (self.selectedVideoURL) {
        NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];

        // Set a custom filename for the exported video
        NSString *exportedFilename = [NSString stringWithFormat:@"exported_%ld.mov", (long)[[NSDate date] timeIntervalSince1970]];
        NSString *exportedPath = [documentsDirectory stringByAppendingPathComponent:exportedFilename];

        // Export the original video to the user's directory
        [self exportVideoAtPath:self.selectedVideoURL toPath:exportedPath];
    }
}

- (void)exportVideoAtPath:(NSURL *)videoURL toPath:(NSString *)exportedPath {
    AVURLAsset *videoAsset = [AVURLAsset assetWithURL:videoURL];

    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:videoAsset presetName:AVAssetExportPresetHighestQuality];
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    exportSession.outputURL = [NSURL fileURLWithPath:exportedPath];

    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                NSLog(@"Video export successful! Exported to: %@", exportedPath);
            } else {
                NSLog(@"Video export failed: %@", exportSession.error);
            }
        });
    }];
}

- (void)addTextOverlayToVideo:(AVAssetExportSession *)exportSession {
    
}

@end
