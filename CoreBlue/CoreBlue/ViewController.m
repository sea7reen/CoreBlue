//
//  ViewController.m
//  CoreBlue
//
//  Created by Kevin on 16/3/3.
//  Copyright © 2016年 kevin. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>


@interface ViewController ()<CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource>

//声明属性记录中心设备
@property (nonatomic, strong) CBCentralManager *cbcManager;
//声明属性记录外围设备
@property (nonatomic, strong) CBPeripheral *cbpripheral;
//tableView
@property (weak, nonatomic) IBOutlet UITableView *cbTableView;
//textView
@property (weak, nonatomic) IBOutlet UITextView *cbTextView;
//写入的数据
@property (nonatomic, strong) CBCharacteristic *cbCharacteristic;

//服务 特征 设备
@property (nonatomic, strong) NSMutableArray *allDevices;
@property (nonatomic, strong) NSMutableArray *allServices;
@property (nonatomic, strong) NSMutableArray *allCharacteristics;

@property (nonatomic, assign) BOOL isConnected;
@property (nonatomic, assign) int count;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (assign, nonatomic) BOOL cbReady;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.cbcManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    self.allDevices = [[NSMutableArray alloc]init];
    self.allServices = [[NSMutableArray alloc]init];
    self.allCharacteristics = [[NSMutableArray alloc]init];
    self.cbTableView.delegate = self;
    self.cbTableView.dataSource = self;
    self.cbReady = NO;
    self.count = 0;
}

#pragma mark - 按钮方法
//寻找设备
- (IBAction)searchDevice:(UIButton *)sender {
    [self updateTextViewString:@"正在扫描外围设备……"];
    NSDictionary *scanOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
    //开始扫描外围设备
    [self.cbcManager scanForPeripheralsWithServices:nil options:scanOptions];
    double delayInSeconds = 20.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds *NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        [self.cbcManager stopScan];
        [self updateTextViewString:@"扫描超时，停止寻找"];
    });
}
//连接设备
- (IBAction)connectDevice:(UIButton *)sender {
    if (self.cbpripheral && !self.cbReady) {
        _cbReady = NO;
        [self.cbcManager connectPeripheral:self.cbpripheral options:nil];
        [self updateTextViewString:@"连接设备，连接成功"];
    }
}
//切断设备
- (IBAction)cutDevice:(UIButton *)sender {
    if (self.cbpripheral && !self.cbReady) {
        _cbReady = YES;
        [self.cbcManager cancelPeripheralConnection:self.cbpripheral];
        [self updateTextViewString:@"断开设备，连接失败"];
    }
}
//暂停搜索
- (IBAction)stopDevice:(UIButton *)sender {
    [self.cbcManager stopScan];
    [self updateTextViewString:@"暂停设备搜索链接"];
}

#pragma mark - talbeView的代理方法
//返回几个表格
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
//返回个数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.allDevices.count;
}
//每个Cell的值
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    CBPeripheral *cbp = [self.allDevices objectAtIndex:indexPath.row];
    cell.textLabel.text = cbp.name;
    return cell;
}
//选中Cell后
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.cbpripheral = [self.allDevices objectAtIndex:indexPath.row];
}

#pragma mark - textView更新方法
//textView内容更新
- (void)updateTextViewString:(NSString *)textViewStr {
    [self.cbTextView setText:[NSString stringWithFormat:@"[ %d ] %@\r%@\n", self.count, textViewStr, self.cbTextView.text]];
    self.count ++;
}

#pragma mark - (1) 检测蓝牙状态
//开始查看服务，蓝牙开启
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
        {
            [self updateTextViewString:@"蓝牙已打开，请扫描外围设备"];
            [self.cbcManager scanForPeripheralsWithServices: nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @NO}];
            break;
        case CBCentralManagerStatePoweredOff:
            [self updateTextViewString:@"蓝牙关闭，请打开蓝牙设备"];
            break;
        default:
            break;
        }
    }
}
#pragma mark - (2) 检测到外设后，停止扫描，连接设备
//查到外设后，停止扫描，连接设备
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    [self updateTextViewString:[NSString stringWithFormat:@"发现peripheral:%@, rssi:%@, UUID:%@, advertisementData:%@ ", peripheral, RSSI, peripheral.identifier, advertisementData]];
    
    self.cbpripheral = peripheral;
    [self.cbcManager connectPeripheral:self.cbpripheral options:nil];
    [self.cbcManager stopScan];
    BOOL replace = NO;
    for (int i = 0; i < self.allDevices.count; i++) {
        CBPeripheral *cbp = [self.allDevices objectAtIndex:i];
        if ([cbp isEqual:peripheral]) {
            [self.allDevices replaceObjectAtIndex:i withObject:peripheral];
            replace = YES;
        }
    }
    if (!replace) {
        [self.allDevices addObject:peripheral];
        [self.cbTableView reloadData];
    }
}
#pragma mark - (3) 连接外设后的处理
//连接外设成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [self updateTextViewString:[NSString stringWithFormat:@"连接成功peripheral:%@, UUID:%@", peripheral, peripheral.identifier]];
    [self.cbpripheral setDelegate:self];
    [self.cbpripheral discoverServices:nil];
    [self updateTextViewString:@"扫描服务"];
    self.isConnected = YES;
}
//连接外围设备失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Error:%@", error.userInfo);
}
//读取到RSSI值,目前取消该方法
- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error {
    int rssi = abs([peripheral.RSSI intValue]);
    CGFloat ci = (rssi - 49) / (10 * 4.);
    NSString *length = [NSString stringWithFormat:@"发现BLT4.0热点:%@,距离:%.1fm",self.cbpripheral,pow(10,ci)];
    [self updateTextViewString:[NSString stringWithFormat:@"距离：%@", length]];
}
#pragma mark - (4) 发现服务和搜索到的Characteristice
//只要扫描到服务就调用
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    [self updateTextViewString:@"扫描到服务"];
    int i = 0;
    //模拟获取服务中的数据
    for (CBService *cbs in peripheral.services) {
        [self.allServices addObject:cbs];
    }
    for (CBService *cbs in peripheral.services) {
        [self updateTextViewString:[NSString stringWithFormat:@"%d:服务 UUID:%@(%@)", i, cbs.UUID.data, cbs.UUID]];
        i++;
        //可以继续扫描服务中的特征
        [peripheral discoverCharacteristics:nil forService:cbs];
    }
}
//只要扫描到特征Characteristics就调用
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    [self updateTextViewString:[NSString stringWithFormat:@"发现特征Characteristics的服务:%@ (%@)", service.UUID.data, service.UUID]];
    //遍历服务中的每个特征
    for (CBCharacteristic *cbc in service.characteristics) {
        [self updateTextViewString:[NSString stringWithFormat:@"特征的UUID:%@ (%@)",cbc.UUID.data, cbc.UUID]];
        [self.allCharacteristics addObject:cbc];
        [self.cbpripheral readValueForCharacteristic:cbc];
        [self.cbpripheral setNotifyValue:YES forCharacteristic:cbc];
        [peripheral discoverDescriptorsForCharacteristic:cbc];
    }
}
//连接外设失败
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self updateTextViewString:[NSString stringWithFormat:@"连接失败，已断开设备:%@连接", peripheral.name]];
    _isConnected = NO;
    [self.allDevices removeObject:peripheral];
    [self.cbTableView reloadData];
}
#pragma mark - (5) 获取外设发来的数据
//获取外设发来的数据，不论是read和notify,获取数据都是从这个方法中读取。
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSData *data = characteristic.value;
    Byte *resultByte = (Byte *)[data bytes];
    for (int i = 0; i < [data length]; i++) {
        printf("testByte[%d] = %d\n", i, resultByte[i]);
    }
}
//中心读取外设设备数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error changing notification state:%@", error.localizedDescription);
    }
    //Notification has started
    if (characteristic.isNotifying) {
        [peripheral readValueForCharacteristic:characteristic];
    }else{
        // Notification has stopped
        // so disconnect from the peripheral
        [self updateTextViewString:[NSString stringWithFormat:@"Notification stopped on %@.Disconnecting", characteristic]];
        [self.cbcManager cancelPeripheralConnection:self.cbpripheral];
    }
}
//发送成功调用
//用于检测中心向外设写数据是否成功
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        [self updateTextViewString:error.localizedDescription];
    }else{
        [self updateTextViewString:@"发送数据成功"];
    }
    //当写入数据时，需要重新读取本地characteristic来更新值
    [peripheral readValueForCharacteristic:characteristic];
}

#pragma mark - (6) 其他辅助
//请求队列
-(NSOperationQueue *)queue {
    if (!_queue) {
        _queue = [[NSOperationQueue alloc]init];
        [_queue setMaxConcurrentOperationCount:1];
    }return _queue;
}

#pragma mark (7) 检索外设的代理功能
/*
 后记
 最主要是用UUID来确定你要干的事情，特征和服务的UUID都是外设定义好的。我们只需要读取，确定你要读取什么的时候，就去判断UUID是否 相符。 一般来说我们使用的iPhone都是做centralManager的，蓝牙模块是peripheral的，所以我们是want datas，需要接受数据。
 1.判断状态为powerOn，然后执行扫描
 2.停止扫描，连接外设
 3.连接成功，寻找服务
 4.在服务里寻找特征
 5.为特征添加通知
 5.通知添加成功，那么就可以实时的读取value[也就是说只要外设发送数据[一般外设的频率为10Hz]，代理就会调用此方法]。
 6.处理接收到的value，[hex值，得转换] 之后就自由发挥了，在这期间都是通过代理来实现的，也就是说你只需要处理你想要做的事情，代理会帮你调用方法。[别忘了添加代理]
 */





@end