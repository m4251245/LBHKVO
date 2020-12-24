//
//  NSObject+LBHKVO.m
//  003---自定义KVO
//
//  Created by 刘必红 on 2020/12/23.
//  Copyright © 2020 cooci. All rights reserved.
//

#import "NSObject+LBHKVO.h"
#import <objc/message.h>

static NSString *const kLBHKVOPrefix = @"LBHKVONotifying_";
static NSString *const LBHKVOAssiociakey = @"kLBHKVO_AssiociateKey";


@implementation LBHKVOInfo

- (instancetype) initWithObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath handleBlock:(LBHKVOBlock) block {
    if (self = [super init]) {
        self.observer = observer;
        self.keyPath = keyPath;
        self.hanldBlock = block;
    }
    return self;
}


- (BOOL)isEqual:(LBHKVOInfo *)object {
    return[self.observer isEqual:object.observer] && [self.keyPath isEqualToString:object.keyPath];
}

@end


@implementation NSObject (LBHKVO)


// 添加观察者
- (void)lbh_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath block:(LBHKVOBlock)block {
    
    [self lbh_addObserver:observer forKeyPath:keyPath options:(LBHKeyValueObservingOptionNew | LBHKeyValueObservingOptionOld) context:NULL block:block];
}

- (void)lbh_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(LBHKeyValueObservingOptions)options context:(nullable void *)context block:(LBHKVOBlock)block {
    
    // 1.1 验证setter方法是否存在
    [self judgeSetterMethodFromKeyPath:keyPath];
    // 1.2 + 1.3 注册KVO派生类(动态生成子类) 添加方法
    Class newClass = [self creatChildClassWithKeyPath:keyPath];
    // 1.4 isa的指向： LBHKVONotifying_LBHPerosn
    object_setClass(self, newClass);
    // 1.5. 保存信息
    LBHKVOInfo * info = [[LBHKVOInfo alloc]initWithObserver:observer forKeyPath:keyPath handleBlock:block];
    [self associatedObjectAddObject:info];
}


- (void)lbh_observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context{
    
}

- (void)lbh_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath
{
    NSMutableArray * observerArr = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)LBHKVOAssiociakey);
    
    if (observerArr.count <= 0) return;
    
    for (LBHKVOInfo * info in observerArr) {
        if ([info.keyPath isEqualToString:keyPath]) {
            // 移除当前info
            [observerArr removeObject:info];
            // 重新设置关联对象的值
            objc_setAssociatedObject(self, (__bridge const void * _Nonnull)LBHKVOAssiociakey, observerArr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            break;
        }
    }
    
    // 全部移除后，isa指回父类
    if (observerArr.count <= 0) {
        Class superClass = [self class];
        object_setClass(self, superClass);
    }
}


#pragma mark - 验证是否存在setter方法
- (void)judgeSetterMethodFromKeyPath:(NSString *)keyPath{
    Class superClass    = object_getClass(self);
    SEL setterSeletor   = NSSelectorFromString(setterForGetter(keyPath));
    Method setterMethod = class_getInstanceMethod(superClass, setterSeletor);
    if (!setterMethod) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"老铁没有当前%@的setter",keyPath] userInfo:nil];
    }
}


//MARK: - 1.2 + 1.3 注册KVO派生类(动态生成子类) 添加方法
- (Class)creatChildClassWithKeyPath: (NSString *) keyPath {
    
    // 1. 类名
    NSString * oldClassName = NSStringFromClass([self class]);
    NSString * newClassName = [NSString stringWithFormat:@"%@%@",kLBHKVOPrefix,oldClassName];
    
    // 2. 生成类
    Class newClass = NSClassFromString(newClassName);
    
    // 2.1 不存在，创建类
    if (!newClass) {
        
        // 2.2.1 申请内存空间 （参数1：父类，参数2：类名，参数3：额外大小）
        newClass = objc_allocateClassPair([self class], newClassName.UTF8String, 0);
        
        // 2.2.2 注册类
        objc_registerClassPair(newClass);
    }
    
    
    // 2.2.3 动态添加set函数
    
    //两个SEL 通过class_getMethodImplementation获取到的实现地址IMP是相同的
    SEL setterSel = NSSelectorFromString(setterForGetter(keyPath));
    
    Method setterMethod = class_getInstanceMethod([self class], setterSel); //为了保证types和原来的类的Imp保持一致，所以从[self class]提取
    const char * setterTypes = method_getTypeEncoding(setterMethod);
    class_addMethod(newClass, setterSel, (IMP)lbh_setter, setterTypes);
    
    
    // 2.2.4 动态添加class函数 （为了让外界调用class时，看到的时原来的类，isa需要指向原来的类）
    SEL classSel = NSSelectorFromString(@"class");
    
//    IMP classImp = class_getMethodImplementation(newClass, classSel);

    Method classMethod = class_getInstanceMethod([self class], classSel);
    const char * classTypes = method_getTypeEncoding(classMethod);
    class_addMethod(newClass, classSel, (IMP)lbh_class, classTypes);
    
    
    // 2.2.5 动态添加dealloc函数
    SEL deallocSel = NSSelectorFromString(@"dealloc");
    Method deallocMethod = class_getInstanceMethod([self class], deallocSel);
    const char * deallocTypes = method_getTypeEncoding(deallocMethod);
    class_addMethod(newClass, deallocSel, (IMP)lbh_dealloc, deallocTypes);
    
    return newClass;
}


//MARK: - 关联属性添加对象
- (void)associatedObjectAddObject:(LBHKVOInfo *)info {
    
    NSMutableArray * mArray = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)LBHKVOAssiociakey);
    if (!mArray) {
        mArray = [NSMutableArray arrayWithCapacity:1];
        objc_setAssociatedObject(self,  (__bridge const void * _Nonnull)LBHKVOAssiociakey, mArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    for (LBHKVOInfo * tempInfo in mArray) {
        if ([tempInfo isEqual:info]) return;
    }
    
    [mArray addObject:info];
}

static void lbh_setter(id self, SEL _cmd, id newValue) {
    NSLog(@"新值：%@", newValue);
    // 读取getter方法（属性名）
    NSString * keyPath = getterForSetter(NSStringFromSelector(_cmd));
    // 获取旧值
    id oldValue = [self valueForKey:keyPath];

    // 1. willChange在此处触发（本示例省略）

    // 2. 调用父类的setter方法(消息转发)
    // 修改objc_super的值，强制将super_class设置为父类
    void(* lbh_msgSendSuper)(void *, SEL, id) = (void *)objc_msgSendSuper;

    // 创建并赋值
    struct objc_super superStruct = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self)),
    };

    lbh_msgSendSuper(&superStruct, _cmd, newValue);
    
//    objc_msgSendSuper(&superStruct, _cmd, newValue);
    
    // 3. didChange在此处触发（本示例省略）
    NSMutableArray * array = objc_getAssociatedObject(self, (__bridge const void * _Nonnull) LBHKVOAssiociakey);
    
    for (LBHKVOInfo * info in array) {
        if([info.keyPath isEqualToString:keyPath] && info.observer){
            // 3.1 block回调的方式
            if (info.hanldBlock) {
                info.hanldBlock(info.observer, keyPath, oldValue, newValue);
            }
//            // 3.2 调用方法的方式
            if([info.observer respondsToSelector:@selector(lbh_observeValueForKeyPath: ofObject: change: context:)]) {
                [info.observer lbh_observeValueForKeyPath:keyPath ofObject:self change:@{keyPath: newValue} context:NULL];
            }
        }
    }
    
}

// 1.3.2 改写class的imp实现
Class lbh_class(id self, SEL _cmd) {
    return class_getSuperclass(object_getClass(self)); // 返回当前类的父类（原来的类）
}

// 1.3.3 重写dealloc方法
void lbh_dealloc(id self, SEL _cmd) {
    
    NSLog(@"%s KVO派生类移除了",__func__);
    
    Class superClass = [self class];
    object_setClass(self, superClass);
}


#pragma mark - 从get方法获取set方法的名称 key ===>>> setKey:
static NSString *setterForGetter(NSString *getter){
    
    if (getter.length <= 0) { return nil;}
    
    NSString *firstString = [[getter substringToIndex:1] uppercaseString];
    NSString *leaveString = [getter substringFromIndex:1];
    
    return [NSString stringWithFormat:@"set%@%@:",firstString,leaveString];
}


#pragma mark - 从set方法获取getter方法的名称 set<Key>:===> key
static NSString *getterForSetter(NSString *setter){
    
    if (setter.length <= 0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) { return nil;}
    
    NSRange range = NSMakeRange(3, setter.length-4);
    NSString *getter = [setter substringWithRange:range];
    NSString *firstString = [[getter substringToIndex:1] lowercaseString];
    return  [getter stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstString];
}


@end
