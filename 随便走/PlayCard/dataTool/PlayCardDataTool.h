//
//  PlayCardDataTool.h
//  随便走
//
//  Created by num:369 on 15/6/17.
//  Copyright (c) 2015年 jf. All rights reserved.
//

#import "Singleton.h"
#import <Foundation/Foundation.h>
#import "CardDataModel.h"

@interface PlayCardDataTool : NSObject
single_interface(PlayCardDataTool)

+ (void)getCardDatasSuccess:(void(^)(NSArray *result))successBlock failed:(void(^)())failedBlock;

@end
