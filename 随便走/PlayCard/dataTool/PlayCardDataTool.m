//
//  PlayCardDataTool.m
//  随便走
//
//  Created by num:369 on 15/6/17.
//  Copyright (c) 2015年 jf. All rights reserved.
//

#import "PlayCardDataTool.h"
#import <MapKit/MapKit.h>
#import "DeviceSensorTool.h"
#import "DeviceSensorDataModel.h"

@implementation PlayCardDataTool

single_implementation(PlayCardDataTool)

+(void)getCardDatasSuccess:(void (^)(NSArray *))successBlock failed:(void (^)())failedBlock
{
    
    //苹果地图自带的POI搜索
    CLLocationCoordinate2D location = [DeviceSensorTool sharedDeviceSensorTool].deviceSensorDataModel.devSenCurrentLoc.coordinate;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(location, 0.05, 0.05);
    
    MKLocalSearchRequest *requst = [[MKLocalSearchRequest alloc] init];
    requst.region = region;
    requst.naturalLanguageQuery = @"restaurant";
    
    MKLocalSearch *localSearch = [[MKLocalSearch alloc] initWithRequest:requst];
    
    NSMutableArray *cardDataModels = [NSMutableArray array];
    
    [localSearch startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error){
        if (!error)
        {
            for (MKMapItem *item in response.mapItems)
            {
                CardDataModel *data = [[CardDataModel alloc] init];
                data.cardDataTitle = item.name;
                data.cardLocationCoor = item.placemark.coordinate;
                NSLog(@"restaurant名称 : %@", item.name);
                [cardDataModels addObject:data];
            }
            successBlock(cardDataModels);
        }
        else
        {
            failedBlock();
        }
    }];
}
@end
