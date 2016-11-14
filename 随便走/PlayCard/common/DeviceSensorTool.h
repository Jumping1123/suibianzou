//
//  DeviceSensorTool.h
//  随便走
//
//  Created by num:369 on 15/6/16.
//  Copyright (c) 2015年 jf. All rights reserved.
//

#import "Singleton.h"
#import <CoreLocation/CoreLocation.h>

typedef void(^ResultBlock)(CLLocation *userLocation, NSString *error);

@class DeviceSensorDataModel;

@interface DeviceSensorTool : NSObject

single_interface(DeviceSensorTool)

/**
 *  供外界访问的传感器各项信息
 */
@property (nonatomic, strong) DeviceSensorDataModel *deviceSensorDataModel;

/**
 *  开始检测获取设备信息
 */
- (void)run;
/**
 *  停止检测设备信息
 */
- (void)stop;

/**
 获取当前位置

 @param block 获取当前位置后处理的block
 */
- (void)getCurrentLocation:(ResultBlock)block;
@end
