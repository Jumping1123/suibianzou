//
//  RealDisplayViewController.m
//  随便走
//
//  Created by zn on 2016/11/11.
//  Copyright © 2016年 ZN. All rights reserved.
//

#import "RealDisplayViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "DeviceSensorTool.h"
#import "PlayCardDataTool.h"
#import "CardView.h"
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapSearchKit/AMapSearchKit.h>

@interface RealDisplayViewController () <AMapSearchDelegate, AVCapturePhotoCaptureDelegate>
/**
 冲击波视图
 */
@property (nonatomic,strong)UIImageView *scanlineView;
/**
 会话
 */
@property (nonatomic,strong)AVCaptureSession *session;
/**
 输入对象
 */
@property (nonatomic,strong)AVCaptureDeviceInput *input;
/**
 输出对象  以后可直接截屏分享
 */
@property (nonatomic,strong)AVCapturePhotoOutput *output;
/**
 预览图层
 */
@property (nonatomic,strong)AVCaptureVideoPreviewLayer *previewLayer;
/**
 *  卡牌的数据模型数组
 */
@property (nonatomic, strong) NSArray *playCardModels;
/**
 *  卡牌视图
 */
@property (nonatomic, strong) NSMutableArray *cardViews;
/**
 *  更新牌视图的定时器
 */
@property (nonatomic, weak) NSTimer *updateCellTimer;
/**
 地图搜索类
 */
@property (nonatomic,strong)AMapSearchAPI *search;
@end

@implementation RealDisplayViewController

#pragma mark - lazy loading
-(AVCaptureSession *)session
{
    if (_session == nil) {
        _session = [[AVCaptureSession alloc] init];
    }
    return _session;
}

-(AVCaptureDeviceInput *)input
{
    if (_input == nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        NSError *error;
        _input = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    }
    return _input;
}

-(AVCapturePhotoOutput *)output
{
    if (_output == nil) {
        _output = [[AVCapturePhotoOutput alloc] init];
        
//        CGSize screenBounds = [UIScreen mainScreen].bounds.size;
//        _output.rectOfInterest = CGRectMake(0, 0, screenBounds.width, screenBounds.height);
    }
    return _output;
}

-(AVCaptureVideoPreviewLayer *)previewLayer
{
    if (_previewLayer == nil) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
        
        CGSize screenBounds = [UIScreen mainScreen].bounds.size;
        _previewLayer.frame = CGRectMake(0, 0, screenBounds.width, screenBounds.height);
    }
    return _previewLayer;
}

-(NSTimer *)updateCellTimer
{
    if (!_updateCellTimer) {
        NSTimer *timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(updateCell) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        _updateCellTimer = timer;
    }
    return _updateCellTimer;
}

-(NSMutableArray *)cardViews
{
    if (!_cardViews) {
        _cardViews = [NSMutableArray array];
    }
    return _cardViews;
}

-(AMapSearchAPI *)search
{
    if (_search == nil) {
        _search = [[AMapSearchAPI alloc] init];
        _search.delegate = self;
    }
    return _search;
}

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];

    if ([self.session canAddInput:self.input]) {
        [self.session addInput:self.input];
    }
    
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    
    if ([self.session canAddOutput:self.output]) {
        [self.session addOutput:self.output];
    }
    
//    [self findDefault];
    
    //监听设置搜索词的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(findOPIWithKey:) name:@"setKeywordNotification" object:nil];
    
    // 启动刷新任务
    [self updateCellTimer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.session) {
        [self.session startRunning];
    }
    
    // 启动传感器监听
    [[DeviceSensorTool sharedDeviceSensorTool] run];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    if (self.session) {
        [self.session stopRunning];
    }
    
    // 停止传感器监听
    [[DeviceSensorTool sharedDeviceSensorTool] stop];
}

-(void)dealloc
{
    NSLog(@"removeObserver:setKeywordNotification");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"setKeywordNotification" object:nil];
}

- (IBAction)takePictureBtnClick:(UIButton *)sender {
    
    //图层上的cardView并不能展示出来
//    AVCapturePhotoSettings *settingsForMonitoring = [[AVCapturePhotoSettings alloc] init];
//    [self.output capturePhotoWithSettings:settingsForMonitoring delegate:self];
    
    CGSize screenBounds = [UIScreen mainScreen].bounds.size;
    UIGraphicsBeginImageContextWithOptions(screenBounds, NO, 0);
    [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];
    
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    [self.view.layer renderInContext:context];
//    [self.previewLayer renderInContext:context];

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageWriteToSavedPhotosAlbum(newImage, nil, nil, nil);
}

/**
 重写数据源set方法，用于重新加载所有卡牌

 @param playCardModels 所有卡牌信息
 */
-(void)setPlayCardModels:(NSArray *)playCardModels
{
    _playCardModels = playCardModels;
    [self loadCardView];
}

/**
 根据数据模型加载卡牌
 */
-(void)loadCardView
{
    //移除旧的视图
    [self.cardViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.cardViews = nil;
    //创建加载新的视图
    [self.playCardModels enumerateObjectsUsingBlock:^(CardDataModel *dataM, NSUInteger idx, BOOL * _Nonnull stop) {
        CardView *cardView = [CardView cardView];
        cardView.cardDataM = dataM;
        [self.view addSubview:cardView];
        [self.cardViews addObject:cardView];
    }];
}

/**
 不断更新每个卡牌的位置和内容
 */
-(void)updateCell
{
    [self.cardViews makeObjectsPerformSelector:@selector(setDevSenDataM:) withObject:[DeviceSensorTool sharedDeviceSensorTool].deviceSensorDataModel];
}

- (void)findOPIWithKey:(NSNotification *)notice
{
    NSString *keyword = [notice.userInfo objectForKey:@"keyword"];
    
    if (keyword) {
        //高德地图POI搜索
        AMapPOIAroundSearchRequest *request = [[AMapPOIAroundSearchRequest alloc] init];
        
        [[DeviceSensorTool sharedDeviceSensorTool] getCurrentLocation:^(CLLocation *userLocation, NSString *error) {
            if ([error length] == 0) {
                request.location = [AMapGeoPoint locationWithLatitude:userLocation.coordinate.latitude longitude:userLocation.coordinate.longitude];
                
                request.keywords = keyword;
                request.radius = 5000;
                request.sortrule = 0;
                request.requireExtension = YES;
                
                [self.search AMapPOIAroundSearch:request];
            }
        }];
    }
}

- (void)findDefault
{
    //高德地图POI搜索
    AMapPOIAroundSearchRequest *request = [[AMapPOIAroundSearchRequest alloc] init];
    
    [[DeviceSensorTool sharedDeviceSensorTool] getCurrentLocation:^(CLLocation *userLocation, NSString *error) {
        if ([error length] == 0) {
            request.location = [AMapGeoPoint locationWithLatitude:userLocation.coordinate.latitude longitude:userLocation.coordinate.longitude];
            
            request.keywords = @"餐厅";
            request.radius = 5000;
            //按照距离排序
            request.sortrule = 0;
            request.requireExtension = YES;
            
            [self.search AMapPOIAroundSearch:request];
        }
    }];
}

#pragma mark - AMapSearchDelegate
-(void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response
{
    if (response.pois.count == 0) {
        return;
    }
    
    NSMutableArray *searchPOIm = [[NSMutableArray alloc] initWithCapacity:response.pois.count];
    
    //解析response数组，获取POI信息
    for (AMapPOI *item in response.pois) {
        CardDataModel *data = [[CardDataModel alloc] init];
        data.cardDataTitle = item.name;
        data.cardLocationCoor = CLLocationCoordinate2DMake(item.location.latitude, item.location.longitude);
        
        [searchPOIm addObject:data];
    }
    
    self.playCardModels = searchPOIm;
}

#pragma mark - AVCapturePhotoCaptureDelegate
-(void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error
{
    if (error) {
        NSLog(@"error : %@", error.localizedDescription);
    }
    
    if (photoSampleBuffer) {
        NSData *data = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
        UIImage *displayImage = [UIImage imageWithData:data];
        UIImageWriteToSavedPhotosAlbum(displayImage, nil, nil, nil);
    }
}

@end
