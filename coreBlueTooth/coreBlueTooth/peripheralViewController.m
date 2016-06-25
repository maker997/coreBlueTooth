//
//  peripheralViewController.m
//  coreBlueTooth
//  外设管理者模式
//  Created by maker on 16/4/27.
//  Copyright © 2016年 maker. All rights reserved.
//

#import "peripheralViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
@interface peripheralViewController ()<CBPeripheralManagerDelegate>

@property(nonatomic,strong)CBPeripheralManager *CBPM;//外设管理者

@end

@implementation peripheralViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self CBPM];
  
}
#pragma mark 懒加载
- (CBPeripheralManager *)CBPM{
    if (!_CBPM) {
        _CBPM = [[CBPeripheralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue() options:nil];
    }
    return _CBPM;
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    /**
     typedef NS_ENUM(NSInteger, CBPeripheralManagerState) {
     CBPeripheralManagerStateUnknown = 0,
     CBPeripheralManagerStateResetting,
     CBPeripheralManagerStateUnsupported,
     CBPeripheralManagerStateUnauthorized,
     CBPeripheralManagerStatePoweredOff,
     CBPeripheralManagerStatePoweredOn,
     } NS_ENUM_AVAILABLE(NA, 6_0);
     
     */

    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        NSLog(@"%s,line = %d 打开 ",__func__,__LINE__);
    }else{
        NSLog(@"%s,line = %d 关闭状态 ",__func__,__LINE__);
    }
}
- (void)setupCBPM{
    CBUUID *serUUID = [CBUUID UUIDWithString:@"maker_fengShan"];
    //创建特征的描述
    CBMutableDescriptor *cbd = [[CBMutableDescriptor alloc] initWithType:serUUID value:nil];
    //创建特征
    CBMutableCharacteristic *cbmc = [[CBMutableCharacteristic alloc] initWithType:serUUID properties:CBCharacteristicPropertyWrite value:nil permissions:CBAttributePermissionsWriteable];
    cbmc.descriptors = @[cbd];
    CBMutableService *service = [[CBMutableService alloc] initWithType:serUUID primary:YES];
    service.characteristics = @[cbmc];
    [self.CBPM addService:service];
}
@end





