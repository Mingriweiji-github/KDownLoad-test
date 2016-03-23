//
//  WFSessionViewController.m
//  DownLoad-test
//
//  Created by Mr.Li on 16/3/15.
//  Copyright © 2016年 Mr.Li. All rights reserved.
//

#import "WFSessionViewController.h"
#import "RealReachability.h"
@interface WFSessionViewController ()<NSURLSessionDownloadDelegate>

//@property(nonatomic,strong) UIProgressView *progression;//进度条


@property (weak, nonatomic) IBOutlet UIProgressView *progressViews;

@property (weak, nonatomic) IBOutlet UILabel *pgLabel;
@property (weak, nonatomic) IBOutlet UILabel *netType;

@property(nonatomic,strong)NSURLSessionDownloadTask *downloadTask;//下载任务

@property(nonatomic,strong)NSData *resumeData;//记录下载的进度


@property(nonatomic,strong)NSURLSession *session;


@end

@implementation WFSessionViewController
/**
 *  session的懒加载
 */


- (NSURLSession *)session
{
    if (nil == _session) {
        
        NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor orangeColor];
    
    //网络状况监听
    [GLobalRealReachability startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkChanged:)
                                                 name:kRealReachabilityChangedNotification
                                               object:nil];
    
}
- (void)networkChanged:(NSNotification *)notification
{
    RealReachability *reachability = (RealReachability *)notification.object;
    ReachabilityStatus status = [reachability currentReachabilityStatus];
    NSLog(@"currentStatus:%@",@(status));
    
    if (status == RealStatusNotReachable)
    {
        self.netType.text = @"无网!";//暂停下载
        
        [self pauseTask];
    }
    
    if (status == RealStatusViaWiFi)
    {
        self.netType.text = @"WIFI";//开始下载
        
        if (self.downloadTask == nil) {
            
            if (self.resumeData) {//继续
                
                [self resumeTask];
                
            }else{// 0 开始
                
                [self startDownLoadTask];
            }

        }
        
    }
    
    if (status == RealStatusViaWWAN)
    {
        self.netType.text = @"4G/3G!";//暂停下载
        
        [self pauseTask];
    }
}
#pragma mark 开始下载任务
- (void)startDownLoadTask
{
    NSURL *url = [NSURL URLWithString:@"http://dlsw.baidu.com/sw-search-sp/soft/9d/25765/sogou_mac_32c_V3.2.0.1437101586.dmg"];
    
    //任务创建
     self.downloadTask =  [self.session downloadTaskWithURL:url];
    
    //开始任务
    [self.downloadTask resume];
    
}
#pragma mark 恢复下载
- (void)resumeTask
{
    //需要传入暂停下载返回的数据，就可以恢复下载了
    self.downloadTask = [self.session downloadTaskWithResumeData:self.resumeData];
    
    //开始任务
    [self.downloadTask resume];
    
    self.resumeData = nil;
    
}
#pragma mark 暂停
- (void)pauseTask
{

    __weak typeof(self) selfVc = self;
    [self.downloadTask cancelByProducingResumeData:^(NSData *resumeData) {
        //  resumeData : 包含了继续下载的开始位置\下载的url
        selfVc.resumeData = resumeData;
        selfVc.downloadTask = nil;
    }];
}

#pragma mark 代理方法--NSURLSessionDownloadDelegate
/*
   监听下载的进度
*/

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{


    //下载进度
    self.progressViews.progress = (double) totalBytesWritten / totalBytesExpectedToWrite;
    
    self.pgLabel.text = [NSString stringWithFormat:@"下载进度：%.3f",self.progressViews.progress];
    
    NSLog(@"progress:%.3f",self.progressViews.progress);
    

}

/*
  完成下载
 
  @param location  文件临时地址
 
 
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSLog(@"suggestedFilename : %@",downloadTask.response.suggestedFilename);
    
    NSLog(@"home-%@  caches-%@",NSHomeDirectory(),[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]);
    
    NSString *filePath = [NSHomeDirectory() stringByAppendingPathComponent:downloadTask.response.suggestedFilename];
    
    //剪切临时文件caches文件夹
    NSFileManager *fl = [NSFileManager defaultManager];
    
    //剪切后的文件路径-----suggestedFilename
    [fl moveItemAtPath:location.path toPath:filePath error:nil];
    
    
}

/*
     恢复下载后调用，
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    
}
/**
 *  Sesstion 简单执行下载
 */


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
