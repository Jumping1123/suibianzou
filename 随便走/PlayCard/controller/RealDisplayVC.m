//
//  RealDisplayVC.m
//  随便走
//
//  Created by num:369 on 15/6/16.
//  Copyright (c) 2015年 jf. All rights reserved.
//

#import "RealDisplayVC.h"
#import "DeviceSensorTool.h"
#import "PlayCardDataTool.h"
#import "CardView.h"
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapSearchKit/AMapSearchKit.h>

@interface RealDisplayVC() <AMapSearchDelegate>
/**
 *  摄像头
 */
@property (nonatomic, strong) UIImagePickerController *pickerC;
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

@implementation RealDisplayVC

#pragma mark - 懒加载方法
-(UIImagePickerController *)pickerC
{
    if (!_pickerC) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            
            _pickerC = [[UIImagePickerController alloc] init];
            _pickerC.sourceType = UIImagePickerControllerSourceTypeCamera;
            _pickerC.showsCameraControls = NO;
            _pickerC.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
            
            //可在照片视图上添加覆盖图层cameraOverlayView
            
            CGSize screenBounds = [UIScreen mainScreen].bounds.size;
            //UIImagePickerController默认比例4/3
            CGFloat cameraAspectRatio = 4.0f/3.0f;
            
            CGFloat camViewWidth = screenBounds.width;
            CGFloat camViewHeight = screenBounds.width * cameraAspectRatio;
            
            CGFloat scaleH = screenBounds.height / camViewHeight;
            CGFloat scaleW = screenBounds.width / camViewWidth;
            
            _pickerC.cameraViewTransform = CGAffineTransformMakeScale(scaleH, scaleW);
            
//            CGFloat scale = screenBounds.height / camViewHeight;
//
//            _pickerC.cameraViewTransform = CGAffineTransformMakeTranslation(0, (screenBounds.height - camViewHeight) / 2.0);
//            _pickerC.cameraViewTransform = CGAffineTransformScale(_pickerC.cameraViewTransform, scale, scale);
            
    ////        [self addChildViewController:_pickerC];
        }
    }
    return _pickerC;
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

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    // 添加摄像头背景
    [self.view addSubview:self.pickerC.view];
    
    //  加载数据源
    [self findOPIWithKey:@"餐厅"];
    
//    [PlayCardDataTool getCardDatasSuccess:^(NSArray *result) {
//        self.playCardModels = result;
//    } failed:^{
//        
//    }];
    
    // 启动刷新任务
    [self updateCellTimer];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // 启动传感器监听
    [[DeviceSensorTool sharedDeviceSensorTool] run];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // 停止传感器监听
    [[DeviceSensorTool sharedDeviceSensorTool] stop];
}


/**
 *  重写数据源set方法,用于重新加载所有卡牌
 *
 */
-(void)setPlayCardModels:(NSArray *)playCardModels
{
    _playCardModels = playCardModels;
    [self loadCardView];
}

/**
 *  根据数据模型加载卡牌
 */
- (void)loadCardView
{
    // 移除旧的视图
    [self.cardViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.cardViews = nil;
    // 创建加载新的视图
    [self.playCardModels enumerateObjectsUsingBlock:^(CardDataModel *dataM, NSUInteger idx, BOOL *stop) {
        CardView *cardView = [CardView cardView];
        cardView.cardDataM = dataM;
        [self.view addSubview:cardView];
        [self.cardViews addObject:cardView];
    }];
}

/**
 *  不断更新每个卡牌的位置和内容
 */
- (void)updateCell
{
    [self.cardViews makeObjectsPerformSelector:@selector(setDevSenDataM:) withObject:[DeviceSensorTool sharedDeviceSensorTool].deviceSensorDataModel];
}

- (void)findOPIWithKey:(NSString *)key
{
    //高德地图POI搜索
    AMapPOIAroundSearchRequest *request = [[AMapPOIAroundSearchRequest alloc] init];
    
//    //因为调用时间的问题，这里获取到的location为(0,0)
//    CLLocationCoordinate2D location = [DeviceSensorTool sharedDeviceSensorTool].deviceSensorDataModel.devSenCurrentLoc.coordinate;
//    request.location = [AMapGeoPoint locationWithLatitude:location.latitude longitude:location.longitude];
//    request.location = [AMapGeoPoint locationWithLatitude:34.233979 longitude:108.920501];
    
    [[DeviceSensorTool sharedDeviceSensorTool] getCurrentLocation:^(CLLocation *userLocation, NSString *error) {
        if ([error length] == 0) {
            request.location = [AMapGeoPoint locationWithLatitude:userLocation.coordinate.latitude longitude:userLocation.coordinate.longitude];
            
            request.keywords = key;
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
@end
