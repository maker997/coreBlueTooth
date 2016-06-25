//
//  centerManagerViewController.m
//  coreBlueTooth
//
//  Created by maker on 16/4/27.
//  Copyright © 2016年 maker. All rights reserved.
//

#import "centerManagerViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface centerManagerViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>
@property(nonatomic,strong)CBCentralManager *CBCM;//中心管理者
@property(nonatomic,strong)CBPeripheral *cbp;//外部设备
@end

@implementation centerManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self CBCM];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self ma_dismissConentedWithPeripheral:self.cbp];
}
#pragma mark 懒加载
- (CBCentralManager *)CBCM{
    if (!_CBCM) {
        _CBCM = [[CBCentralManager alloc] initWithDelegate://设置代理
                 self queue://放在主线程中
                 dispatch_get_main_queue() options://空
                 nil];
        //初始话中心管理者之后就会调用代理中的状态改变的方法
    }
    return _CBCM;
}
//中心管理者状态发生改变的方法
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            NSLog(@"CBCentralManagerStateUnknown");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@"CBCentralManagerStateResetting");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"CBCentralManagerStateUnsupported");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"CBCentralManagerStateUnauthorized");
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@"请打开蓝牙");
            break;
        case CBCentralManagerStatePoweredOn:
        {
           NSLog(@"CBCentralManagerStatePoweredOn");
            //中心管理者开启成功后搜索周围的设备
            [self.CBCM scanForPeripheralsWithServices://通过uuid的数组来指定搜索
             nil options://指定选项搜索
             nil];
        }
            break;
        default:
            break;
    }
}
//搜索到设备后回调的方法
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI{
    NSLog(@"peripheral = %@ advertisementData = %@ RSSI = %@",peripheral,advertisementData,RSSI);
    //通过条件控制过滤掉别人的设备
    if ([peripheral.name hasPrefix:@"UPWEAR"] && (ABS([RSSI integerValue]) >40)) {
        self.cbp = peripheral;
        [self.CBCM connectPeripheral:peripheral options:nil];
        
    }
}
//连接外设成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    self.cbp.delegate = self;
    [self.cbp discoverServices:nil];
    NSLog(@"%s,line = %d per = %@",__func__,__LINE__,peripheral);
}
// 外设连接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"%s, line = %d, %@=连接失败", __FUNCTION__, __LINE__, peripheral.name);
}

// 丢失连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"%s, line = %d, %@=断开连接", __FUNCTION__, __LINE__, peripheral.name);
}


//发现服务,外部设备的代理方法
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error{
    if (error) {
        NSLog(@"%s, line = %d, error = %@", __FUNCTION__, __LINE__, error.localizedDescription);
        return;
    }
    //扫描服务中的特征
    for (CBService *service in peripheral.services) {
        [self.cbp discoverCharacteristics:nil forService:service];//扫描特征
    }
}

//通过服务发现特征
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (error) {
        NSLog(@"%s, line = %d, error = %@", __FUNCTION__, __LINE__, error.localizedDescription);
        return;
    }
    //通过特征,查看描述内容
    for (CBCharacteristic *cbc in service.characteristics) {
        [peripheral discoverDescriptorsForCharacteristic:cbc];        [peripheral readValueForCharacteristic:cbc];//读取特征的值
    }
}

//获取特征的值
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        NSLog(@"%s, line = %d, error = %@", __FUNCTION__, __LINE__, error.localizedDescription);
        return;
    }
    //value 的类型为 NSData 类型
    NSLog(@"%s,%d value = %@",__func__,__LINE__,characteristic.value);
}

//通过特征发现描述
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"%s,line = %d descriptors = %@",__func__,__LINE__,characteristic.descriptors);
    for (CBDescriptor *cbd in characteristic.descriptors) {
        [self.cbp readValueForDescriptor:cbd];
    }
}

//获取descriptor的值
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    if (error) {
        NSLog(@"%s, line = %d, error = %@", __FUNCTION__, __LINE__, error.localizedDescription);
        return;
    }
    NSLog(@"%s,line = %d value = %@",__func__,__LINE__,descriptor.value);
}

#pragma mark - 自定义方法
// 一般第三方框架or自定义的方法,可以加前缀与系统自带的方法加以区分.最好还设置一个宏来取消前缀

// 5.外设写数据到特征中

// 需要注意的是特征的属性是否支持写数据
- (void)yf_peripheral:(CBPeripheral *)peripheral didWriteData:(NSData *)data forCharacteristic:(nonnull CBCharacteristic *)characteristic
{
    /*
     typedef NS_OPTIONS(NSUInteger, CBCharacteristicProperties) {
     CBCharacteristicPropertyBroadcast												= 0x01,
     CBCharacteristicPropertyRead													= 0x02,
     CBCharacteristicPropertyWriteWithoutResponse									= 0x04,
     CBCharacteristicPropertyWrite													= 0x08,
     CBCharacteristicPropertyNotify													= 0x10,
     CBCharacteristicPropertyIndicate												= 0x20,
     CBCharacteristicPropertyAuthenticatedSignedWrites								= 0x40,
     CBCharacteristicPropertyExtendedProperties										= 0x80,
     CBCharacteristicPropertyNotifyEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)		= 0x100,
     CBCharacteristicPropertyIndicateEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)	= 0x200
     };
     
     打印出特征的权限(characteristic.properties),可以看到有很多种,这是一个NS_OPTIONS的枚举,可以是多个值
     常见的又read,write,noitfy,indicate.知道这几个基本够用了,前俩是读写权限,后俩都是通知,俩不同的通知方式
     */
    NSLog(@"%s, line = %d, char.pro = %lu", __FUNCTION__, __LINE__, (unsigned long)characteristic.properties);
    // 此时由于枚举属性是NS_OPTIONS,所以一个枚举可能对应多个类型,所以判断不能用 = ,而应该用包含&
    if (characteristic.properties & CBCharacteristicPropertyWrite) {
        // 核心代码在这里
        [peripheral writeValue:data // 写入的数据
             forCharacteristic:characteristic // 写给哪个特征
                          type:CBCharacteristicWriteWithResponse];// 通过此响应记录是否成功写入
    }
}

// 6.通知的订阅和取消订阅
// 实际核心代码是一个方法
// 一般这两个方法要根据产品需求来确定写在何处
- (void)yf_peripheral:(CBPeripheral *)peripheral regNotifyWithCharacteristic:(nonnull CBCharacteristic *)characteristic
{
    // 外设为特征订阅通知 数据会进入 peripheral:didUpdateValueForCharacteristic:error:方法
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
}
- (void)yf_peripheral:(CBPeripheral *)peripheral CancleRegNotifyWithCharacteristic:(nonnull CBCharacteristic *)characteristic
{
    // 外设取消订阅通知 数据会进入 peripheral:didUpdateValueForCharacteristic:error:方法
    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
}

// 7.断开连接
- (void)ma_dismissConentedWithPeripheral:(CBPeripheral *)peripheral
{
    // 停止扫描
    [self.CBCM stopScan];
    // 断开连接
    [self.CBCM cancelPeripheralConnection:peripheral];
}
@end











