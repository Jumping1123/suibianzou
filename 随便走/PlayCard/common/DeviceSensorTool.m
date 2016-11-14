//
//  DeviceSensorTool.m
//  随便走
//
//  Created by num:369 on 15/6/16.
//  Copyright (c) 2015年 jf. All rights reserved.
//

#import "DeviceSensorTool.h"
#import "DeviceSensorDataModel.h"

@interface DeviceSensorTool()<CLLocationManagerDelegate>

/**
 *  用于获取位置信息和设备朝向的位置管理器
 */
@property (nonatomic, strong) CLLocationManager *locationM;
/**
 *  用于获取传感器信息的管理器
 */
@property (nonatomic, strong) CMMotionManager *motionM;

/**
 存储外界传递的代码块
 */
@property (nonatomic,copy)ResultBlock resultBlock;

@end

@implementation DeviceSensorTool

single_implementation(DeviceSensorTool)

-(CMMotionManager *)motionM
{
    if (!_motionM) {
        _motionM = [[CMMotionManager alloc] init];
        _motionM.deviceMotionUpdateInterval = 0.05;
    }
    return _motionM;
}

-(CLLocationManager *)locationM
{
    if (!_locationM) {
        _locationM = [[CLLocationManager alloc] init];
        _locationM.headingFilter = 0.5;
        _locationM.distanceFilter = 10;
        if([_locationM respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [_locationM requestAlwaysAuthorization]; // 永久授权
        }
        _locationM.delegate = self;
        [_locationM setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];
    }
    return _locationM;
}

-(DeviceSensorDataModel *)deviceSensorDataModel
{
    if (_deviceSensorDataModel == nil) {
        _deviceSensorDataModel = [[DeviceSensorDataModel alloc] init];
    }
    _deviceSensorDataModel.devSenSlopeZ = self.motionM.deviceMotion.gravity.z;
    
    return _deviceSensorDataModel;
}


-(void)run
{
    [self stop];
    if ([CLLocationManager locationServicesEnabled]) {
        [self.locationM startUpdatingLocation];
    }

    // 磁力计传感器(获取设备朝向)
    if ([CLLocationManager headingAvailable]) {
        [self.locationM startUpdatingHeading];
    }

    // 陀螺仪传感器(可以获取设备在空间内的持握方式)
    if ([self.motionM isDeviceMotionAvailable]) {
        [self.motionM startDeviceMotionUpdates];
    }
}

-(void)stop
{
    [self.locationM stopUpdatingLocation];
    [self.locationM stopUpdatingHeading];
    [self.motionM stopDeviceMotionUpdates];
    self.locationM = nil;
    self.motionM = nil;
}

-(void)getCurrentLocation:(ResultBlock)block
{
    //记录代码块,在合适位置调用
    self.resultBlock = block;
    
    //判断是否开启定位服务
    if ([CLLocationManager locationServicesEnabled]) {
        //更新用户位置
        [self.locationM startUpdatingLocation];
    }else
    {
        self.resultBlock(nil, @"用户定位服务未开启");
    }
    
}

#pragma mark - CLLocationManagerDelegate
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    NSLog(@"didUpdateLocations");
    //更新到用户定位，执行外界调用的代码块
    if (self.resultBlock) {
        self.resultBlock([locations lastObject], nil);
    }
    
    // 修改属性参数,供外界访问
    CLLocation *anyL = [locations lastObject];
    self.deviceSensorDataModel.devSenCurrentLoc = anyL;
}

-(void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    // 修改属性参数,供外界访问
    self.deviceSensorDataModel.devSenAngleFromNorth = newHeading.trueHeading;
}

@end
