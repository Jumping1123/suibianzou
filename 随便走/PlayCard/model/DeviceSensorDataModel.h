//
//  DeviceSensorDataModel.h
//  随便走
//
//  Created by zn on 2016/11/9.
//  Copyright © 2016年 jf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeviceSensorDataModel : NSObject
/**
 *  当前位置信息
 */
@property (nonatomic, strong) CLLocation *devSenCurrentLoc;
/**
 *  手机相对于正北方向的夹角（0.0 - 359.9）
 */
@property (nonatomic, assign) float devSenAngleFromNorth;
/**
 *  设备当前的倾斜度（-1.0 到 0 到 1.0）
 */
@property (nonatomic, assign) float devSenSlopeZ;
@end
