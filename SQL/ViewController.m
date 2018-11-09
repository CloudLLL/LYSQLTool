//
//  ViewController.m
//  SQL
//
//  Created by CloudL on 2018/9/25.
//  Copyright © 2018 KOOCAN. All rights reserved.
//

#import "ViewController.h"
#import "LYSQLTool.h"
#import "TestModel.h"


@interface ViewController ()

@property (nonatomic , strong) LYSQLTool *tool;

@property (nonatomic , strong) LYSQLTool *tool2;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tool = [[LYSQLTool alloc]initWithPath:@"/Users/cloudl/Desktop/DB/test.sqlite"];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc]init];
    queue.maxConcurrentOperationCount = 10;

    [queue addOperationWithBlock:^{
        [self.tool createTabel:@"testTabel" objectClass:[TestModel class] results:nil];
    }];


    [queue addOperationWithBlock:^{
       [self.tool updateTableWithTableName:@"testTabel" class:[TestModel class]];
    }];
    
    [queue addOperationWithBlock:^{
        [self.tool createTabel:@"testTabel" objectClass:[TestModel class] results:nil];
    }];
    
    [queue addOperationWithBlock:^{
        NSLog(@"viewDidLoad ---- %@",[NSThread currentThread]);
        for (NSInteger i = 0; i < 100; i++) {
            TestModel *model = [TestModel new];
            model.age = 2;
            model.name = @"32132";
            model.num = @4;
            model.Mname = [NSMutableString stringWithString:@"fdsfd"];
            model.arr = @[[TestModel2 new],[TestModel2 new]];
            model.marr = [NSMutableArray arrayWithArray:model.arr];
            model.dict = @{
                           @"fdsfds":@"dsfdsfds",
                           @"fsds":[TestModel2 new]
                           };
            model.mdict = [NSMutableDictionary dictionaryWithDictionary:model.dict];
            [self.tool insertModel:model fromTable:@"testTabel" results:^(BOOL results) {
                NSLog(@"插入结果:%d",results);
            }];
        }
    }];
    
    
    [queue addOperationWithBlock:^{
        [self.tool queryWithConditionsStr:nil fromTable:@"testTabel" backObject:[TestModel class] results:^(NSMutableArray * _Nonnull objectArr) {
            NSLog(@"%ld",objectArr.count);
        }];
    }];
    
    [queue addOperationWithBlock:^{

        for (NSInteger i = 0; i < 100; i++) {
            TestModel *model = [TestModel new];
            model.age = 2;
            model.name = @"32132";
            model.num = @4;
            model.Mname = [NSMutableString stringWithString:@"fdsfd"];
            model.arr = @[[TestModel2 new],[TestModel2 new]];
            model.marr = [NSMutableArray arrayWithArray:model.arr];
            model.dict = @{
                           @"fdsfds":@"dsfdsfds",
                           @"fsds":[TestModel2 new]
                           };
            model.mdict = [NSMutableDictionary dictionaryWithDictionary:model.dict];
            [self.tool insertModel:model fromTable:@"testTabel" results:^(BOOL results) {
                NSLog(@"插入结果:%d",results);
            }];
        }
    }];
    
    [self.tool queryWithConditionsStr:nil fromTable:@"testTabel" backObject:[TestModel class] results:^(NSMutableArray * _Nonnull objectArr) {
        NSLog(@"%ld",objectArr.count);
    }];


    
//    [self test];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    ViewController *vc = [ViewController new];
    vc.view.backgroundColor = [UIColor yellowColor];
    [self presentViewController:vc animated:nil completion:nil];
}



#pragma mark - <#注释#>
- (void)test
{
    self.tool2 = [[LYSQLTool alloc]initWithPath:@"/Users/cloudl/Desktop/DB/test2.sqlite"];
    [self.tool2 createTabel:@"testTabel" objectClass:[TestModel class] results:nil];
    

    for (NSInteger i = 0; i < 100; i++) {
        TestModel *model = [TestModel new];
        model.age = 2;
        model.name = @"32132";
        model.num = @4;
        model.Mname = [NSMutableString stringWithString:@"fdsfd"];
        model.arr = @[[TestModel2 new],[TestModel2 new]];
        model.marr = [NSMutableArray arrayWithArray:model.arr];
        model.dict = @{
                       @"fdsfds":@"dsfdsfds",
                       @"fsds":[TestModel2 new]
                       };
        model.mdict = [NSMutableDictionary dictionaryWithDictionary:model.dict];
        [self.tool2 insertModel:model fromTable:@"testTabel" results:^(BOOL results) {
            NSLog(@"插入结果:%d",results);
        }];
    }
    
    [self.tool2 queryWithConditionsStr:nil fromTable:@"testTabel" backObject:[TestModel class] results:^(NSMutableArray * _Nonnull objectArr) {
        
        NSLog(@"%ld",objectArr.count);

    }];
    
    for (NSInteger i = 0; i < 100; i++) {
        TestModel *model = [TestModel new];
        model.age = 2;
        model.name = @"32132";
        model.num = @4;
        model.Mname = [NSMutableString stringWithString:@"fdsfd"];
        model.arr = @[[TestModel2 new],[TestModel2 new]];
        model.marr = [NSMutableArray arrayWithArray:model.arr];
        model.dict = @{
                       @"fdsfds":@"dsfdsfds",
                       @"fsds":[TestModel2 new]
                       };
        model.mdict = [NSMutableDictionary dictionaryWithDictionary:model.dict];
        [self.tool2 insertModel:model fromTable:@"testTabel" results:^(BOOL results) {
            NSLog(@"插入结果:%d",results);
        }];
    }

}

@end

