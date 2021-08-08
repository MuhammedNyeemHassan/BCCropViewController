//
//  BCCropViewController.m
//  BCPicker
//
//  Created by Somoy Das Gupta on 25/7/21.
//

#import "BCCropViewController.h"
#import "BCCropCanvasView.h"

@interface BCCropViewController ()

@property (weak, nonatomic) IBOutlet BCCropCanvasView *cropCanvasView;

//BCCropMenuView Outlets

@end

@implementation BCCropViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self commonInit];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    [self prepareCropCanvasview];
}

- (void)commonInit {
    self.view.backgroundColor = UIColor.clearColor;
}

//MARK:- Prepare views
- (void)prepareCropCanvasview {
    _cropCanvasView.inputImage = _selectedImage;
}

//MARK:- Property Setters
- (void)setSelectedImage:(UIImage *)selectedImage {
    _selectedImage = selectedImage;
}

//MARK:- Button Actions
- (IBAction)doneButtonPressed:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

//MARK:- BCCropMenuView Actions

//MARK:- BCCropMenuView subview Delegates
@end
