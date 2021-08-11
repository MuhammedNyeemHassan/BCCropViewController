//
//  ViewController.m
//  BCCropViewController
//
//  Created by Somoy Das Gupta on 3/8/21.
//

#import "ViewController.h"
#import "BCPicker.h"
#import "BCCropViewController.h"

@interface ViewController ()<BCPickerControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)pickImageButtonPressed:(UIButton *)sender {
    
    UINavigationController *uinav = (UINavigationController*)[[UIStoryboard storyboardWithName:@"BCPicker" bundle:nil] instantiateViewControllerWithIdentifier:@"BCPickerNavigationController"];
    uinav.modalPresentationStyle = UIModalPresentationFullScreen;
    BCPicker *bcPicker = uinav.viewControllers[0];
    bcPicker.pickerOptions = Photos | Colors | Unsplash | Pixabay;
    bcPicker.delegate = self;
    bcPicker.navigationBarTitleFont = [UIFont fontWithName:@"SFProDisplay-Bold" size:15.0];
    
    //Menu view Properties
    bcPicker.menuFont = [UIFont fontWithName:@"SFProDisplay-Regular" size:14.0];
    bcPicker.menuSelectedFont = [UIFont fontWithName:@"SFProDisplay-Regular" size:14.0];
    
    //Photo Picker Properties
    bcPicker.photoPickerAccessoryViewType = BCPPhotoAlbumView;
    bcPicker.albumFont = [UIFont fontWithName:@"SFProDisplay-Regular" size:15.0];
    bcPicker.selectedAlbumFont = [UIFont fontWithName:@"SFProDisplay-Medium" size:14.0];
    
    bcPicker.colorGroupTitles = @[@"Color", @"Gradient"];
    bcPicker.colorPlistGroupArray = @[@[@"Basic_color.plist", @"Cool_color.plist", @"Warm_color.plist", @"Brand_color.plist"], @[@"Gradient_color.plist", @"NCColorViewGradient.plist"]];
    
    bcPicker.apiSearchTextFont = [UIFont fontWithName:@"SFProDisplay-Medium" size:14.0];
    bcPicker.apiPhotoTitleFont =[UIFont fontWithName:@"SFProDisplay-Regular" size:14.0];
    bcPicker.unsplashAPIKey = @"MDZDFht52MrOo_evEGFxl4MMiYLKiPhH868EZktPRvg";
    bcPicker.pixabayAPIKey = @"20094913-f6e150763af3f3ad3a2feace3";
    
    [self presentViewController:uinav animated:true completion:nil];
}

- (void)bcPicker:(BCPicker *)picker didPickImage:(UIImage *)image {
    
    if (image) {
        
        [picker dismissViewControllerAnimated:YES completion:^{
            
            BCCropViewController *cropVC = (BCCropViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"BCCropViewController"];
            cropVC.selectedImage = [self normalizedImage:image];
            cropVC.modalPresentationStyle = UIModalPresentationFullScreen;
            [self.navigationController presentViewController:cropVC animated:YES completion:nil];
        }];
    }
}

- (UIImage *)normalizedImage:(UIImage *)image {
    if (image.imageOrientation == UIImageOrientationUp) return image;

    UIGraphicsBeginImageContextWithOptions(image.size, YES, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}


- (void)bcPicker:(BCPicker *)picker didPickColor:(BCPColorType)type hexArray:(NSArray<NSString *> *)hexStrings {
    
}

@end
