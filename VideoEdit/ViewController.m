//
//  ViewController.m
//  VideoEdit
//
//  Created by Auto on 5/2/24.
//

#import "ViewController.h"
#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@interface ViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, UIColorPickerViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *textField;

@property (weak, nonatomic) IBOutlet UILabel *outputLabel;

@property (weak, nonatomic) IBOutlet UIButton *textColorBtn;
@property (weak, nonatomic) IBOutlet UIButton *bgColorBtn;

@property (nonatomic, strong) NSURL *selectedVideoURL;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVAssetExportSession *assetExport;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *bgColor;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configAVPlayer];
    
    self.textField.delegate = self;
    
    self.textColor = UIColor.whiteColor;
    self.bgColor = UIColor.redColor;
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.textField) {
        [textField resignFirstResponder];
        return NO;
    }
    return YES;
}

-(void)configAVPlayer {
    // Create AVPlayer and AVPlayerLayer
    self.player = [AVPlayer playerWithURL:self.selectedVideoURL];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = CGRectMake(0, 150, self.view.frame.size.width, 300);
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

- (IBAction)textColorAction:(id)sender {
    UIColor *color = [self getRandomColor];
    self.textColor = color;
    [self.textColorBtn setBackgroundColor: color];
}

- (CGFloat)randomValue {
    // Generate a random integer between 0 and UINT32_MAX
    uint32_t randomInt = arc4random_uniform(UINT32_MAX);
    
    // Normalize the random integer to a CGFloat between 0 and 1
    CGFloat randomValue = (CGFloat)randomInt / (CGFloat)UINT32_MAX;
    return randomValue;
}

-(UIColor *) getRandomColor {
    UIColor *tempColor = UIColor.redColor;
    tempColor = [[UIColor alloc] initWithRed:[self randomValue] green:[self randomValue] blue:[self randomValue] alpha:1.0];
    return tempColor;
}

- (IBAction)bgColorAction:(id)sender {
    UIColor *color = [self getRandomColor];
    self.bgColor = color;
    [self.bgColorBtn setBackgroundColor: color];
}

- (IBAction)saveAndExportVideo:(id)sender {
    NSString *input = self.textField.text;
    NSLog(@"DEBUG: %@", input);
    if (self.selectedVideoURL) {
        NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        
        // Set a custom filename for the exported video
        NSString *exportedFilename = [NSString stringWithFormat:@"exported_%ld.mov", (long)[[NSDate date] timeIntervalSince1970]];
        NSString *exportedPath = [documentsDirectory stringByAppendingPathComponent:exportedFilename];
        
        [self mergeTextOverlay:self.selectedVideoURL text: input exportPath: exportedPath];
    }
}

- (void) mergeTextOverlay: (NSURL*)videoURL text: (NSString *) textInput exportPath: (NSString *) exportPath {
    if (videoURL == nil) return;
    
    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:videoURL options:nil];
    AVMutableComposition* mixComposition = [AVMutableComposition composition];
    
    AVMutableCompositionTrack* compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo  preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVAssetTrack* clipVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                                   ofTrack:clipVideoTrack
                                    atTime:kCMTimeZero error:nil];
    
    [compositionVideoTrack setPreferredTransform:[[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] preferredTransform]];
    
    //sorts the layer in proper order
    AVAssetTrack* videoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize videoSize = [videoTrack naturalSize];
    CALayer *parentLayer = [CALayer layer];
    
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    
    [parentLayer addSublayer:videoLayer];
    
    // create text Layer
    CATextLayer* titleLayer = [CATextLayer layer];
    titleLayer.backgroundColor = self.bgColor.CGColor;
    titleLayer.foregroundColor = self.textColor.CGColor;
    titleLayer.string = textInput;
    titleLayer.font = CFBridgingRetain(@"Helvetica");
    titleLayer.fontSize = 28;
    titleLayer.shadowOpacity = 0.5;
    titleLayer.alignmentMode = kCAAlignmentCenter;
    titleLayer.frame = CGRectMake(0, 50, videoSize.width, 30);
    
    [parentLayer addSublayer:titleLayer];
    
    //create the composition and add the instructions to insert the layer:
    AVMutableVideoComposition* videoComp = [AVMutableVideoComposition videoComposition];
    videoComp.renderSize = videoSize;
    videoComp.frameDuration = CMTimeMake(1, 30);
    videoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    AVMutableVideoCompositionInstruction* instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);
    AVAssetTrack* mixVideoTrack = [[mixComposition tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:mixVideoTrack];
    instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
    videoComp.instructions = [NSArray arrayWithObject: instruction];
    
    self.assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];
    self.assetExport.videoComposition = videoComp;
    
    NSLog (@"created exporter. supportedFileTypes: %@", _assetExport.supportedFileTypes);
    
    NSURL *exportURL = [NSURL fileURLWithPath: exportPath];
    self.assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    self.assetExport.outputURL = exportURL;
    self.assetExport.shouldOptimizeForNetworkUse = YES;
    
    NSLog(@"DEBUG: Photo path: %@", exportPath);
    self.outputLabel.text = @"Processing...";
    [self.assetExport exportAsynchronouslyWithCompletionHandler: ^(void ) {
        
        //Final code here
        switch (self.assetExport.status) {
            case AVAssetExportSessionStatusUnknown:
                NSLog(@"Unknown");
                break;
            case AVAssetExportSessionStatusWaiting:
                NSLog(@"Waiting");
                break;
            case AVAssetExportSessionStatusExporting:
                NSLog(@"Exporting");
                break;
                
            case AVAssetExportSessionStatusFailed:
                NSLog(@"Failed- %@", self.assetExport.error);
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"Cancelled");
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"Created new video with text");
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.outputLabel.text = @"Success";
                });
                break;
        }
    }
    ];
}

@end
