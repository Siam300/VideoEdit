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
    NSLog(@"Save button tapped!");
}

- (void)addTextOverlayToVideo:(AVAssetExportSession *)exportSession {
    
}

@end
