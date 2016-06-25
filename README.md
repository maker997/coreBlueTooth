# coreBlueTooth
手机通过蓝牙连接外部设备的 demo
### 中心管理者模式思路
- 1.建立中心角色
- 2.扫描外设(Discover Peripheral)
- 3.连接外设(Connect Peripheral)
- 4.扫描外设中的服务和特征(Discover Services And Characteristics)
    * 4.1 获取外设的services
    * 4.2 获取外设的Characteristics,获取characteristics的值,,获取Characteristics的Descriptor和Descriptor的值
- 5.利用特征与外设做数据交互(Explore And Interact)
- 6.订阅Characteristic的通知
- 7.断开连接(Disconnect)

### 代码实现
#### 1.导入CB头文件,建立主设备管理类,设置主设备代理

```
@interface centerManagerViewController()<CBCentralManagerDelegate,CBPeripheralDelegate>
@property(nonatomic,strong)CBCentralManager *CBCM;//中心管理者
@property(nonatomic,strong)CBPeripheral *cbp;//外部设备
@end

@implementation centerManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self CBCM];
}

// 1.1建立中心管理者
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

// 1.2中心管理者状态发生改变的方法
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

```
#### 2.扫描外设（discover）

```
//搜索到设备后回调的方法
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI{
    NSLog(@"peripheral = %@ advertisementData = %@ RSSI = %@",peripheral,advertisementData,RSSI);
    //通过条件控制过滤掉别人的设备
    if ([peripheral.name hasPrefix:@"UPWEAR"] && (ABS([RSSI integerValue]) >40)) {
     /*
       一个主设备最多能连7个外设，每个外设最多只能给一个主设备连接,连接成功，失		败，断开会进入各自的委托
       - (void)centralManager:(CBCentralManager *)central 		didConnectPeripheral:(CBPeripheral *)peripheral;//连接外设成功的		委托
       - (void)centralManager:(CBCentralManager *)central 		didFailToConnectPeripheral:(CBPeripheral *)peripheral error:		(NSError *)error;//外设连接失败的委托
       - (void)centralManager:(CBCentralManager *)central 		didDisconnectPeripheral:(CBPeripheral *)peripheral error:(		NSError *)error;//断开外设的委托
		找到的设备必须持有它，否则CBCentralManager中也不会保存peripheral，那		么CBPeripheralDelegate中的方法也不会被调用！！
      */
        self.cbp = peripheral;
        [self.CBCM connectPeripheral:peripheral options:nil];
    }
}

```
#### 3 连接外设(connect)
```
//连接外设成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
	 NSLog(@"%s,line = %d per = %@",__func__,__LINE__,peripheral);
    self.cbp.delegate = self;
    [self.cbp discoverServices:nil];//发现服务
   //发现服务后会调用- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error
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

```

#### 4扫描外设中的服务和特征(discover)
	设备连接成功后，就可以扫描设备的服务了，同样是通过委托形式，扫描到结果后会进入委托方法。但是这个委托已经不再是主设备的委托（CBCentralManagerDelegate），而是外设的委托（CBPeripheralDelegate）,这个委托包含了主设备与外设交互的许多 回叫方法，包括获取services，获取characteristics，获取characteristics的值，获取characteristics的Descriptor，和Descriptor的值，写数据，读rssi，用通知的方式订阅数据等等。

##### 4.1获取外设的services

```
//发现服务,外部设备的代理方法
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error{
    if (error) {
        NSLog(@"%s, line = %d, error = %@", __FUNCTION__, __LINE__, error.localizedDescription);
        return;
    }
    //扫描服务中的特征
    for (CBService *service in peripheral.services) {
        [self.cbp discoverCharacteristics:nil forService:service];
        //发现特征,之后会调用发现特征的方法
    }
}

```

##### 4.2获取外设的Characteristics,获取Characteristics的值，获取Characteristics的Descriptor和Descriptor的值
```
//4.2.1获取外设的Characteristics
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (error) {
        NSLog(@"%s, line = %d, error = %@", __FUNCTION__, __LINE__, error.localizedDescription);
        return;
    }
    //通过特征查看Descriptor
    for (CBCharacteristic *cbc in service.characteristics) {
        [peripheral discoverDescriptorsForCharacteristic:cbc];
        //发现描述后会调用4.2.3
        [peripheral readValueForCharacteristic:cbc];
        //读取特征的值,会调用4.2.2
    }
}

//4.2.2获取特征的值
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error) {
        NSLog(@"%s, line = %d, error = %@", __FUNCTION__, __LINE__, error.localizedDescription);
        return;
    }
    //value 的类型为 NSData 类型
    NSLog(@"%s,%d value = %@",__func__,__LINE__,characteristic.value);
}

//4.2.3通过特征发现描述
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"%s,line = %d descriptors = %@",__func__,__LINE__,characteristic.descriptors);
    for (CBDescriptor *cbd in characteristic.descriptors) {
        [self.cbp readValueForDescriptor:cbd];
        //读取描述的值会调用4.2.4
    }
}

//4.2.4获取descriptor的值
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    if (error) {
        NSLog(@"%s, line = %d, error = %@", __FUNCTION__, __LINE__, error.localizedDescription);
        return;
    }
    NSLog(@"%s,line = %d value = %@",__func__,__LINE__,descriptor.value);
}

```

#### 5 把数据写到Characteristic中
```
//写数据
-(void)writeCharacteristic:(CBPeripheral *)peripheral
                characteristic:(CBCharacteristic *)characteristic
                         value:(NSData *)value{

        //打印出 characteristic 的权限，可以看到有很多种，这是一个NS_OPTIONS，就是可以同时用于好几个值，常见的有read，write，notify，indicate，知知道这几个基本就够用了，前连个是读写权限，后两个都是通知，两种不同的通知方式。
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

         */
        NSLog(@"%lu", (unsigned long)characteristic.properties);

        //只有 characteristic.properties 有write的权限才可以写
        if(characteristic.properties & CBCharacteristicPropertyWrite){
            /*
                最好一个type参数可以为CBCharacteristicWriteWithResponse或type:CBCharacteristicWriteWithResponse,区别是是否会有反馈
            */
            [peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        }else{
            NSLog(@"该字段不可写！");
        }

    }

```
#### 6 订阅Characteristic的通知
```
 //设置通知
 -(void)notifyCharacteristic:(CBPeripheral *)peripheral
  characteristic:(CBCharacteristic *)characteristic{
   //设置通知，数据通知会进入：didUpdateValueForCharacteristic方法
  [peripheral setNotifyValue:YES forCharacteristic:characteristic];

    }

//取消通知
-(void)cancelNotifyCharacteristic:(CBPeripheral *)peripheral
                 characteristic:(CBCharacteristic *)characteristic{
                 
  [peripheral setNotifyValue:NO forCharacteristic:characteristic];
}

```

#### 7.断开连接
```
- (void)ma_dismissConentedWithPeripheral:(CBPeripheral *)peripheral
{
    // 停止扫描
    [self.CBCM stopScan];
    // 断开连接
    [self.CBCM cancelPeripheralConnection:peripheral];
}


```