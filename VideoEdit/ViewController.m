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

@property (weak, nonatomic) IBOutlet UITextField *textField;

@property (nonatomic, strong) NSURL *selectedVideoURL;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVAssetExportSession *assetExport;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(20, 20, 200, 30)];
//    [self.view addSubview:self.textField];
    
    [self configAVPlayer];
    
}

-(void)configAVPlayer {
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
    NSString *input = self.textField.text;
    NSLog(@"DEBUG: %@", input);
    if (self.selectedVideoURL) {
        NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];

        // Set a custom filename for the exported video
        NSString *exportedFilename = [NSString stringWithFormat:@"exported_%ld.mov", (long)[[NSDate date] timeIntervalSince1970]];
        NSString *exportedPath = [documentsDirectory stringByAppendingPathComponent:exportedFilename];

        // Export the original video to the user's directory
//        [self exportVideoAtPath:self.selectedVideoURL toPath:exportedPath];
//        UIImage *exportImage = [UIImage imageNamed: @"export"];
//        [self mergeTextOverlay: exportImage video: self.selectedVideoURL exportPath: exportedPath];
        [self mergeTextOverlay:self.selectedVideoURL exportPath: exportedPath];
//        [self MixVideoWithText:self.selectedVideoURL];
    }
}

- (void)exportVideoAtPath:(NSURL *)videoURL toPath:(NSString *)exportedPath {
    //    AVURLAsset *videoAsset = [AVURLAsset assetWithURL:videoURL];
    //    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:videoAsset presetName:AVAssetExportPresetHighestQuality];
    //    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    //    exportSession.outputURL = [NSURL fileURLWithPath:exportedPath];
    //
    //    [exportSession exportAsynchronouslyWithCompletionHandler:^{
    //        dispatch_async(dispatch_get_main_queue(), ^{
    //            if (exportSession.status == AVAssetExportSessionStatusCompleted) {
    //                NSLog(@"Video export successful! Exported to: %@", exportedPath);
    //            } else {
    //                NSLog(@"Video export failed: %@", exportSession.error);
    //            }
    //        });
    //    }];
    
    // Create an attributed string
//    NSAttributedString *waterfallText = [[NSAttributedString alloc] initWithString:@"Waterfall!" attributes: attributes];
    NSAttributedString *text = [[NSAttributedString alloc] initWithString: self.textField.text];
    
    // Convert attributed string to a CIImage
    CIFilter *textFilter = [CIFilter filterWithName:@"CIFilter.attributedTextImageGenerator"];
    [textFilter setValue:text forKey:@"inputText"];
    [textFilter setValue:@(4.0) forKey:@"inputScaleFactor"];
    // Compose text over the video image
//    [request finishWithComposedVideoFrame:positionedText context:nil];
    
    AVAsset *videoAsset = [AVAsset assetWithURL:videoURL];
    
    AVMutableVideoComposition *textComposition = [AVMutableVideoComposition videoCompositionWithAsset:videoAsset applyingCIFiltersWithHandler:^(AVAsynchronousCIImageFilteringRequest * _Nonnull request) {
        // Center text and move 200 px from the origin
        // Source image is 720 x 1280
        CIImage *positionedText = [textFilter.outputImage imageByApplyingTransform:CGAffineTransformMakeTranslation((request.renderSize.width - textFilter.outputImage.extent.size.width) / 2, 200)];
//        [request finishWithImage:request.sourceImage context: nil];
        [request finishWithImage:[positionedText imageByCompositingOverImage: request.sourceImage] context: nil];
    }];
    
    AVPlayerItem *videoItem = [AVPlayerItem playerItemWithAsset:videoAsset];
    videoItem.videoComposition = textComposition;
//    self.player = [AVPlayer playerWithPlayerItem: videoItem];
    
    [self.player replaceCurrentItemWithPlayerItem: videoItem];
    [self.player play];
}

//- (void) mergeTextOverlay:(UIImage*)image video:(NSURL*)videoURL exportPath: (NSString *) exportPath {
- (void) mergeTextOverlay: (NSURL*)videoURL exportPath: (NSString *) exportPath {
    if (videoURL == nil) return;

    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:videoURL options:nil];
    AVMutableComposition* mixComposition = [AVMutableComposition composition];

    AVMutableCompositionTrack* compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo  preferredTrackID:kCMPersistentTrackID_Invalid];

    AVAssetTrack* clipVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                                   ofTrack:clipVideoTrack
                                    atTime:kCMTimeZero error:nil];

    [compositionVideoTrack setPreferredTransform:[[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] preferredTransform]];

    //  create the layer with the watermark image
//    CALayer* aLayer = [CALayer layer];
//    aLayer.contents = (id)image.CGImage;
//    aLayer.frame = CGRectMake(50, 100, image.size.width, image.size.height);
//    aLayer.opacity = 0.9;

    //sorts the layer in proper order

    AVAssetTrack* videoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize videoSize = [videoTrack naturalSize];
    CALayer *parentLayer = [CALayer layer];
    
    
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    
    [parentLayer addSublayer:videoLayer];
//    [parentLayer addSublayer:aLayer];


    // create text Layer
    CATextLayer* titleLayer = [CATextLayer layer];
    titleLayer.backgroundColor = [UIColor clearColor].CGColor;
    titleLayer.string = @"Dummy text";
    titleLayer.font = CFBridgingRetain(@"Helvetica");
    titleLayer.fontSize = 28;
    titleLayer.shadowOpacity = 0.5;
    titleLayer.alignmentMode = kCAAlignmentCenter;
    titleLayer.frame = CGRectMake(0, 50, videoSize.width, videoSize.height / 6);

    [parentLayer addSublayer:titleLayer];

    //create the composition and add the instructions to insert the layer:

    AVMutableVideoComposition* videoComp = [AVMutableVideoComposition videoComposition];
    videoComp.renderSize = videoSize;
    videoComp.frameDuration = CMTimeMake(1, 30);
    videoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];

    /// instruction
    AVMutableVideoCompositionInstruction* instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];

    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);
    AVAssetTrack* mixVideoTrack = [[mixComposition tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:mixVideoTrack];
    instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
    videoComp.instructions = [NSArray arrayWithObject: instruction];

    // export video
//    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality]
    self.assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];
    self.assetExport.videoComposition = videoComp;

    NSLog (@"created exporter. supportedFileTypes: %@", _assetExport.supportedFileTypes);

//    NSString* videoName = @"NewWatermarkedVideo.mov";
//
//    NSString* exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:videoName];
//    NSURL* exportUrl = [NSURL fileURLWithPath:exportPath];

//    if ([[NSFileManager defaultManager] fileExistsAtPath:exportPath])
//        [[NSFileManager defaultManager] removeItemAtPath:exportPath error:nil];

    NSURL *exportURL = [NSURL fileURLWithPath: exportPath];
    self.assetExport.outputFileType = AVFileTypeQuickTimeMovie;
    self.assetExport.outputURL = exportURL;
    self.assetExport.shouldOptimizeForNetworkUse = YES;

    
    NSLog(@"DEBUG: Photo path: %@", exportPath);
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
             case AVAssetExportSessionStatusCompleted:
                 NSLog(@"Created new water mark image");
//                 _playButton.hidden = NO;
                 break;
             case AVAssetExportSessionStatusFailed:
                 NSLog(@"Failed- %@", self.assetExport.error);
                 break;
             case AVAssetExportSessionStatusCancelled:
                 NSLog(@"Cancelled");
                 break;
            }
     }
     ];
}

-(void)MixVideoWithText: (NSURL*) url {
    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:url options:nil];
    AVMutableComposition* mixComposition = [AVMutableComposition composition];

    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *clipVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    AVAssetTrack *clipAudioTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    //If you need audio as well add the Asset Track for audio here

    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:clipVideoTrack atTime:kCMTimeZero error:nil];
    [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:clipAudioTrack atTime:kCMTimeZero error:nil];

    [compositionVideoTrack setPreferredTransform:[[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] preferredTransform]];

    CGSize sizeOfVideo=[videoAsset naturalSize];

    //TextLayer defines the text they want to add in Video
    //Text of watermark
    CATextLayer *textOfvideo=[[CATextLayer alloc] init];
    textOfvideo.string = @"Dummy text";//text is shows the text that you want add in video.
    [textOfvideo setFont:(__bridge CFTypeRef)([UIFont fontWithName:[NSString stringWithFormat:@"%@",@"Helvetica"] size:13])];//fontUsed is the name of font
    [textOfvideo setFrame:CGRectMake(0, 0, sizeOfVideo.width, sizeOfVideo.height/6)];
    [textOfvideo setAlignmentMode:kCAAlignmentCenter];
    [textOfvideo setForegroundColor: UIColor.whiteColor.CGColor];

    //Image of watermark
    UIImage *myImage=[UIImage imageNamed:@"one.png"];
    CALayer *layerCa = [CALayer layer];
    layerCa.contents = (id)myImage.CGImage;
    layerCa.frame = CGRectMake(0, 0, sizeOfVideo.width, sizeOfVideo.height);
    layerCa.opacity = 1.0;

    CALayer *optionalLayer=[CALayer layer];
    [optionalLayer addSublayer:textOfvideo];
    optionalLayer.frame=CGRectMake(0, 0, sizeOfVideo.width, sizeOfVideo.height);
    [optionalLayer setMasksToBounds:YES];

    CALayer *parentLayer=[CALayer layer];
    CALayer *videoLayer=[CALayer layer];
    parentLayer.frame=CGRectMake(0, 0, sizeOfVideo.width, sizeOfVideo.height);
    videoLayer.frame=CGRectMake(0, 0, sizeOfVideo.width, sizeOfVideo.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:optionalLayer];
    [parentLayer addSublayer:layerCa];

    AVMutableVideoComposition *videoComposition=[AVMutableVideoComposition videoComposition] ;
    videoComposition.frameDuration=CMTimeMake(1, 30);
    videoComposition.renderSize=sizeOfVideo;
    videoComposition.animationTool=[AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];

    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);
    AVAssetTrack *videoTrack = [[mixComposition tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
    videoComposition.instructions = [NSArray arrayWithObject: instruction];

    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
    NSString *destinationPath = [documentsDirectory stringByAppendingFormat:@"/output_%@.mov", [dateFormatter stringFromDate:[NSDate date]]];

    NSLog(@"destination: %@", destinationPath);
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetMediumQuality];
    exportSession.videoComposition=videoComposition;

    exportSession.outputURL = [NSURL fileURLWithPath:destinationPath];
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
    switch (exportSession.status)
    {
        case AVAssetExportSessionStatusCompleted:
            NSLog(@"Export OK");
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(destinationPath)) {
                UISaveVideoAtPathToSavedPhotosAlbum(destinationPath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
            }
            break;
        case AVAssetExportSessionStatusFailed:
            NSLog (@"AVAssetExportSessionStatusFailed: %@", exportSession.error);
            break;
        case AVAssetExportSessionStatusCancelled:
            NSLog(@"Export Cancelled");
            break;
    }
  }];
}

//------------------------------------------------------
//- (void)addAnimation
//{
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:videoName ofType:ext];
//
//    AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:filePath]  options:nil];
//
//    AVMutableComposition* mixComposition = [AVMutableComposition composition];
//
//    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
//
//    AVAssetTrack *clipVideoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
//
//    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:clipVideoTrack atTime:kCMTimeZero error:nil];
//
//    [compositionVideoTrack setPreferredTransform:[[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] preferredTransform]];
//
//    CGSize videoSize = [clipVideoTrack naturalSize];
//
//    UIImage *myImage = [UIImage imageNamed:@"29.png"];
//    CALayer *aLayer = [CALayer layer];
//    aLayer.contents = (id)myImage.CGImage;
//    aLayer.frame = CGRectMake(videoSize.width - 65, videoSize.height - 75, 57, 57);
//    aLayer.opacity = 0.65;
//    CALayer *parentLayer = [CALayer layer];
//    CALayer *videoLayer = [CALayer layer];
//    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
//    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
//    [parentLayer addSublayer:videoLayer];
//    [parentLayer addSublayer:aLayer];
//
//    CATextLayer *titleLayer = [CATextLayer layer];
//    titleLayer.string = @"Text goes here";
//    titleLayer.font = CFBridgingRetain(@"Helvetica");
//    titleLayer.fontSize = videoSize.height / 6;
//    //?? titleLayer.shadowOpacity = 0.5;
//    titleLayer.alignmentMode = kCAAlignmentCenter;
//    titleLayer.bounds = CGRectMake(0, 0, videoSize.width, videoSize.height / 6); //You may need to adjust this for proper display
//    [parentLayer addSublayer:titleLayer]; //ONLY IF WE ADDED TEXT
//
//    AVMutableVideoComposition* videoComp = [AVMutableVideoComposition videoComposition];
//    videoComp.renderSize = videoSize;
//    videoComp.frameDuration = CMTimeMake(1, 30);
//    videoComp.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
//
//    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
//    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [mixComposition duration]);
//    AVAssetTrack *videoTrack = [[mixComposition tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
//    AVMutableVideoCompositionLayerInstruction* layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
//    instruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
//    videoComp.instructions = [NSArray arrayWithObject: instruction];
//
//    AVAssetExportSession *assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];//AVAssetExportPresetPassthrough
//    assetExport.videoComposition = videoComp;
//
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString* VideoName = [NSString stringWithFormat:@"%@/mynewwatermarkedvideo.mp4",documentsDirectory];
//
//
//    //NSString *exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:VideoName];
//    NSURL *exportUrl = [NSURL fileURLWithPath:VideoName];
//
//    if ([[NSFileManager defaultManager] fileExistsAtPath:VideoName])
//    {
//        [[NSFileManager defaultManager] removeItemAtPath:VideoName error:nil];
//    }
//
//    assetExport.outputFileType = AVFileTypeQuickTimeMovie;
//    assetExport.outputURL = exportUrl;
//    assetExport.shouldOptimizeForNetworkUse = YES;
//
//    //[strRecordedFilename setString: exportPath];
//
//    [assetExport exportAsynchronouslyWithCompletionHandler:
//     ^(void ) {
//         dispatch_async(dispatch_get_main_queue(), ^{
//             [self exportDidFinish:assetExport];
//         });
//     }
//     ];
//}
//
//-(void)exportDidFinish:(AVAssetExportSession*)session
//{
//    NSURL *exportUrl = session.outputURL;
//    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//
//    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:exportUrl])
//    {
//        [library writeVideoAtPathToSavedPhotosAlbum:exportUrl completionBlock:^(NSURL *assetURL, NSError *error)
//         {
//             dispatch_async(dispatch_get_main_queue(), ^{
//                 if (error) {
//                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed"
//                                                                    delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//                     [alert show];
//                 } else {
//                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Saved" message:@"Saved To Photo Album"
//                                                                    delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//                     [alert show];
//                 }
//             });
//         }];
//
//    }
//    NSLog(@"Completed");
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AlertView" message:@"Video is edited successfully." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//    [alert show];
//}
//
@end
