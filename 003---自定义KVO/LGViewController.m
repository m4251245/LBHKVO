//
//  LGViewController.m
//  003---自定义KVO
//
//  Created by cooci on 2019/1/5.
//  Copyright © 2019 cooci. All rights reserved.
//

#import "LGViewController.h"
#import "LGPerson.h"
#import "NSObject+LGKVO.h"
#import <objc/runtime.h>
#import "NSObject+LBHKVO.h"

@interface LGViewController ()
@property (nonatomic, strong) LBHPerson *person;
@end

@implementation LGViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.person = [[LBHPerson alloc] init];
//    [self.person lg_addObserver:self forKeyPath:@"nickName" options:(LGKeyValueObservingOptionNew|LGKeyValueObservingOptionOld) context:NULL];
//    [self.person lg_addObserver:self forKeyPath:@"name" options:(LGKeyValueObservingOptionNew|LGKeyValueObservingOptionOld) context:NULL];
    
    
    [self.person lbh_addObserver:self forKeyPath:@"nickName" options:(LBHKeyValueObservingOptionNew|LBHKeyValueObservingOptionOld) context:NULL block:^(id  _Nonnull observer, NSString * _Nonnull keyPath, id  _Nonnull oldValue, id  _Nonnull newValue) {
          
        NSLog(@"回调响应：oldValue: %@, newValue:%@", oldValue, newValue);
        
    }];
    
    [self.person lbh_addObserver:self forKeyPath:@"name" options:(LBHKeyValueObservingOptionNew|LBHKeyValueObservingOptionOld) context:NULL block:^(id  _Nonnull observer, NSString * _Nonnull keyPath, id  _Nonnull oldValue, id  _Nonnull newValue) {
          
        NSLog(@"回调响应：oldValue: %@, newValue:%@", oldValue, newValue);
        
    }];

    
    self.person.name = @"liu";
    self.person.nickName = @"666";
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    self.person.name = [NSString stringWithFormat:@"%@+", self.person.name];
    self.person.nickName = [NSString stringWithFormat:@"%@+", self.person.nickName];
}

#pragma mark - KVO回调
- (void)lg_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    NSLog(@"%@",change);
}

- (void)lbh_observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context
{
    
}

- (void)dealloc{
    [self.person lg_removeObserver:self forKeyPath:@"nickName"];
    NSLog(@"end");
}


#pragma mark - 遍历方法-ivar-property
- (void)printClassAllMethod:(Class)cls{
    unsigned int count = 0;
    Method *methodList = class_copyMethodList(cls, &count);
    for (int i = 0; i<count; i++) {
        Method method = methodList[i];
        SEL sel = method_getName(method);
        IMP imp = class_getMethodImplementation(cls, sel);
        NSLog(@"%@-%p",NSStringFromSelector(sel),imp);
    }
    free(methodList);
}

#pragma mark - 遍历类以及子类
- (void)printClasses:(Class)cls{
    
    /// 注册类的总数
    int count = objc_getClassList(NULL, 0);
    /// 创建一个数组， 其中包含给定对象
    NSMutableArray *mArray = [NSMutableArray arrayWithObject:cls];
    /// 获取所有已注册的类
    Class* classes = (Class*)malloc(sizeof(Class)*count);
    objc_getClassList(classes, count);
    for (int i = 0; i<count; i++) {
        if (cls == class_getSuperclass(classes[i])) {
            [mArray addObject:classes[i]];
        }
    }
    free(classes);
    NSLog(@"classes = %@", mArray);
}
@end
