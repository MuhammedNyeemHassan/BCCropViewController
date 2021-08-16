//
//  BCCropViewController.m
//  BCPicker
//
//  Created by Somoy Das Gupta on 25/7/21.
//

#import "BCCropViewController.h"
#import "BCCropCanvasView.h"
#import "NCSkewView.h"
#import "NCCropView.h"
#import "NCFlipView.h"
#import "NCRotationView.h"
#import "NCRulerView.h"

@interface BCCropViewController ()<NCCropViewDelegate,NCFlipViewDelegate,NCSkewViewDelegate,NCRotationViewDelegate,AdjustRotateDelegate>{
    IBOutlet NSLayoutConstraint *rulerViewHeightConstraint;
    IBOutlet NSLayoutConstraint *bottomViewAspectConstraintLow;
    IBOutlet NSLayoutConstraint *bottomViewAspectConstraintHigh;
    
    NCCropView *cropView;
    NCFlipView *flipView;
    NCSkewView *skewView;
    NCRotationView *rotationView;
    NCRulerView *rulerView;
    
    IBOutlet UIButton *cropBtn;
    IBOutlet UIButton *flipBtn;
    IBOutlet UIButton *skewBtn;
    IBOutlet UIButton *rotationBtn;
    IBOutlet UIButton *resetBtn;
    
    IBOutlet UIView *rulerViewContainer;

    SkewType skewType;
    CGFloat skewH;
    CGFloat skewV;
    CGFloat skew360;
    int lastSelectedBtnTag;
    BOOL horizontalFlip;
    BOOL verticalFlip;
    BOOL shouldSkew;
    int count ;   //Count to help rotation
    int degreeVal; // Ruler Value Change;





}

@property (weak, nonatomic) IBOutlet BCCropCanvasView *cropCanvasView;
@property (weak,nonatomic) IBOutlet UIView *optionsContainerView;
//BCCropMenuView Outlets

@end

@implementation BCCropViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(closeButtonPressed:)];
    self.navigationItem.leftBarButtonItem = closeItem;
    
    [self commonInit];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];

}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    if (!_cropCanvasView.inputImage) {
        [self prepareCropCanvasview];
    }
}

- (void)commonInit {
    self.view.backgroundColor = UIColor.clearColor;
    [self showCropOptions:cropBtn];

}

//MARK:- Foreground Notifier

-(void)applicationWillEnterForeground{
    if (rotationView.alpha || skewView.alpha) {
        rulerViewHeightConstraint.constant =  60*RATIO;
        bottomViewAspectConstraintLow.active = NO;
        bottomViewAspectConstraintHigh.active = YES;
        [UIView animateWithDuration:0.25 animations:^{
            [self.view layoutIfNeeded];
        }completion:^(BOOL finished) {
            if (finished) {
            }
        }];
    }
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

- (void)closeButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doneButtonPressed:(UIButton *)sender {
    UIImage *image = [_cropCanvasView saveModelAndApply];
    [self shareImage:image fromViewController:self];
}

- (void)shareImage:(UIImage *)image fromViewController:(UIViewController *)viewController
{
    if(image)
    {
        UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:nil];
        [activity popoverPresentationController].sourceView = viewController.view;
        [activity popoverPresentationController].sourceRect = viewController.view.frame;
        [viewController presentViewController:activity animated:true completion:nil];
    }
}

//MARK:- BCCropMenuView Actions

-(id)loadFromNib:(NSString *)name classToLoad:(Class)classToLoad {
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:name owner:self options:nil];
    for (id object in bundle) {
        if ([object isKindOfClass:classToLoad]) {
            return object;
        }
    }
    return nil;
}


-(void)showCropView{
    [self hideRulerView];
    if (cropView == nil) {
        cropView = [self loadFromNib:@"NCCropView" classToLoad:[NCCropView class]];
        cropView.frame = _optionsContainerView.bounds;
        cropView.delgate = self;
        [_optionsContainerView addSubview:cropView];
    }
    [self hideAllOtherOptions];
    [cropView setAlpha:1.0];
    
}

-(void)showFlipView{
    [self hideRulerView];
    if (flipView == nil) {
        flipView = [self loadFromNib:@"NCFlipView" classToLoad:[NCFlipView class]];
        flipView.frame = _optionsContainerView.bounds;
        flipView.delegate = self;
        [_optionsContainerView addSubview:flipView];
    }
    
//    if (_cropDataModel.flipH) {
//        [flipView selectFlipHBtn];
//    }
//    if (_cropDataModel.flipV) {
//        [flipView selectFlipVBtn];
//    }
    
    [self hideAllOtherOptions];
    [flipView setAlpha:1.0];
}

-(void)showRotationView{
    skewType = skew360;
    [self showRulerView];
    if (rotationView == nil) {
        rotationView = [self loadFromNib:@"NCRotationView" classToLoad:[NCRotationView class]];
        rotationView.frame = _optionsContainerView.bounds;
        rotationView.delegate = self;
        [_optionsContainerView addSubview:rotationView];
    }
    [self hideAllOtherOptions];
    [rotationView setAlpha:1.0];
    [self apply360Skew];
//    if (_cropDataModel.rotationValue) {
//        [rulerView setRulerValue:skew360];
//    }

}

-(void)showSkewView{
//    [self calculateZoomScaleForSkew];
    [self showRulerView];
    if (skewView == nil) {
        skewView = [self loadFromNib:@"NCSkewView" classToLoad:[NCSkewView class]];
        skewView.frame = _optionsContainerView.bounds;
        skewView.delegate = self;
        [_optionsContainerView addSubview:skewView];
    }
    [self hideAllOtherOptions];
    [skewView setAlpha:1.0];
    [rulerView setIsSkew:YES];
    switch (skewType) {
        case HorizontalSkew:
            [self applyHorizontalSkew];
            break;
        case VerticalSkew:
            [self applyVerticalSkew];
            break;
        case Skew360:
            [self apply360Skew];
            break;

        default:
            break;
    }
}

-(void)showRulerView{
    if (rulerView == nil) {
        
        count= 0 ;
        rulerView = [self loadFromNib:@"NCRulerView" classToLoad:[NCRulerView class]];
        rulerView.frame = rulerViewContainer.bounds;
        [rulerView rulerSetup];
        rulerView.delegate = self;
        [rulerViewContainer addSubview:rulerView];
        NSString *str =  [[NSNumber numberWithInt:(int)0] stringValue];
        str = [str stringByAppendingFormat:@"%@",@"\u00B0"];
        rulerView.angleText = str;
//        [rulerView setIsSkew:YES];
//        [rulerView.rotateRulerView setValue:0];
    }
    rulerView.alpha = 1.0;
    rulerView.frame = rulerViewContainer.bounds;
    rulerViewHeightConstraint.constant =  60*RATIO;
    bottomViewAspectConstraintLow.active = NO;
    bottomViewAspectConstraintHigh.active = YES;
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    }completion:^(BOOL finished) {
        if (finished) {
            self->shouldSkew = YES;
        }
    }];
}

-(void)hideRulerView{
    rulerView.frame = rulerViewContainer.bounds;
    rulerViewHeightConstraint.constant =  0.0;
    self->rulerView.alpha = 0.0;
    bottomViewAspectConstraintLow.active = YES;
    bottomViewAspectConstraintHigh.active = NO;
}


-(void)hideAllOtherOptions{
    [cropView setAlpha:0.0];
    [flipView setAlpha:0.0];
    [skewView setAlpha:0.0];
    [rotationView setAlpha:0.0];
}


- (void)deselectAllBtns {
    [flipBtn setSelected:NO];
    [cropBtn setSelected:NO];
    [skewBtn setSelected:NO];
    [rotationBtn setSelected:NO];
}

-(IBAction)showCropOptions:(id)sender{
    [self deselectAllBtns];
    UIButton *selectedBtn = (UIButton *)sender;
    lastSelectedBtnTag = selectedBtn.tag;
    [selectedBtn setSelected:YES];
    switch (selectedBtn.tag) {
        case 0:
//            [tweakView.scrollView setMinimumZoomScale:1.0];
            [self showCropView];
            break;
        case 1:
//            [tweakView.scrollView setMinimumZoomScale:1.0];
            [self showFlipView];
            break;
        case 2:
//            [tweakView.scrollView setMinimumZoomScale:1.0];
            [self showRotationView];
            break;
        case 3:
            [self showSkewView];
            break;

        default:
            break;
    }
}


//MARK:- BCCropMenuView subview Delegates

#pragma mark FlipView Delegates

-(void)flipViewFlippedHorizontally{
    horizontalFlip = horizontalFlip^1;
    [_cropCanvasView flipImageHorizontal];
    resetBtn.enabled = YES;
}

-(void)flipViewFlippedVeritcally{
    verticalFlip = verticalFlip^1;
    [_cropCanvasView flipImageVertical];
    resetBtn.enabled = YES;
}

#pragma mark Rotation Delegates

-(void)rotateToLeftNinty{
    [rulerView rotateContentNintyDegreesWithClockWise:NO];
}

-(void)rotateToRightNinty{
    [rulerView rotateContentNintyDegreesWithClockWise:YES];
}

#pragma mark SkewView Delegates

-(void)applyHorizontalSkew{
    skewType = HorizontalSkew;
    [rulerView setIsSkew:YES];
    [rulerView setRulerValue:skewH];
}

-(void)applyVerticalSkew{
    skewType = VerticalSkew;
    [rulerView setIsSkew:YES];
    [rulerView setRulerValue:skewV];
}

-(void)apply360Skew{
    skewType = Skew360;
    [rulerView setIsSkew:NO];
    [rulerView setRulerValue:skew360];

}

#pragma mark CropView Delegates

-(void)cropView:(NCCropView *)cropView didSelectRatio:(NSString *)ratio{

}

#pragma mark Rulerview Delegates

-(void)setAdjustRotate:(CGFloat)rValues{
    
    
    NSLog(@"rotate 360***%f",rValues);
    if ((rValues <= 0.1 && rValues >= -0.1) || rValues >= 180.0f ||rValues <= -180.0f) {
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    }
    if (skewView.alpha) {
        if(skewType == Skew360)
        {
            if (count>2) {
                NSString *str =  [[NSNumber numberWithInt:(int)rValues] stringValue];
                str = [str stringByAppendingFormat:@"%@",@"\u00B0"];
                rulerView.angleText = str;
                [_cropCanvasView rotateImageLayer:rValues];
                skew360 =rValues;
            }else{
                count ++;
            }
        }
        else if(skewType == HorizontalSkew){
            NSString *str =  [[NSNumber numberWithInt:(int)rValues] stringValue];
            str = [str stringByAppendingFormat:@"%@",@"\u00B0"];
            rulerView.angleText = str;
            [_cropCanvasView skewImageLayerHorizontally:rValues];
            skewH = rValues;
        }
        else{
            NSString *str =  [[NSNumber numberWithInt:(int)rValues] stringValue];
            str = [str stringByAppendingFormat:@"%@",@"\u00B0"];
            rulerView.angleText = str;
            [_cropCanvasView skewImageLayerVertically:rValues];
            skewV = rValues;
        }
    }else{
        if (count>2) {
            NSString *str =  [[NSNumber numberWithInt:(int)rValues] stringValue];
            str = [str stringByAppendingFormat:@"%@",@"\u00B0"];
            rulerView.angleText = str;
            [_cropCanvasView rotateImageLayer:rValues];
            skew360 =rValues;
        }else{
            count ++;
        }
    }
    

}

-(void)update{
    
}


//-(void) rotateClockWise:(BOOL)flag{
//    count = 0;
//}
//
//-(void) rotateAntiClockWise:(BOOL)flag{
//    count = 0;
//}

-(void) rotateAntiClockWise:(BOOL) flag{
//    [self.tweakView.cropView ]
    if(flag){
        for(int i=180;i>=rulerView.rotateRulerView.value;i--){
            NSString *str =  [[NSNumber numberWithInt:(int)i] stringValue];
            str = [str stringByAppendingFormat:@"%@",@"\u00B0"];
            rulerView.angleText = str;
            [_cropCanvasView rotateImageLayer:(M_PI*i)/180.0 ];
        }

        NCCRRulerControl *ruler =rulerView.rotateRulerView;
        [ruler setValue:rulerView.changedValue animated:YES];
    }
    else {
        NSLog(@"ROTATING ANTI CLOCKWISE");
        
        degreeVal = rulerView.rotateRulerView.value;
        for(int i=rulerView.rotateRulerView.value;i>=degreeVal;i--){
            NSLog(@"Moving");
            NSString *str =  [[NSNumber numberWithInt:(int)i] stringValue];
            str = [str stringByAppendingFormat:@"%@",@"\u00B0"];
            rulerView.angleText = str;
            NSLog(@"------%@",str);
            [_cropCanvasView rotateImageLayer:(M_PI*i)/180.0 ];
        }
    }
    count = 0;
}

#pragma mark - rotate ClockWise
-(void) rotateClockWise:(BOOL) flag{
    if(flag) {
        degreeVal =rulerView.rotateRulerView.value;
        for(int i=-180;i<=rulerView.rotateRulerView.value;i++){
            NSString *str =  [[NSNumber numberWithInt:(int)i] stringValue];
            str = [str stringByAppendingFormat:@"%@",@"\u00B0"];
            rulerView.angleText = str;
            [_cropCanvasView rotateImageLayer:(M_PI*i)/180.0 ];
        }
        NCCRRulerControl *ruler =rulerView.rotateRulerView;
        [ruler setValue:rulerView.changedValue animated:YES];
    }
    else {
        
        NSLog(@"ROTATING CLOCKWISE");
        
        degreeVal =rulerView.rotateRulerView.value;
        for(int i=rulerView.rotateRulerView.value;i<=degreeVal;i++){
            
            NSLog(@"%d %d",degreeVal,i);
            
            NSString *str =  [[NSNumber numberWithInt:(int)i] stringValue];
            str = [str stringByAppendingFormat:@"%@",@"\u00B0"];
            rulerView.angleText = str;
            [_cropCanvasView rotateImageLayer:(M_PI*i)/180.0 ];
        }
    }
//    [self.tweakView.cropView updateCropLines:YES];
    count = 0;
}


@end
