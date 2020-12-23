//
//  NSObject+LBHKVO.h
//  003---自定义KVO
//
//  Created by 刘必红 on 2020/12/23.
//  Copyright © 2020 cooci. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^LBHKVOBlock)(id observer, NSString * keyPath, id oldValue, id newValue);

typedef NS_OPTIONS(NSUInteger, LBHKeyValueObservingOptions) {

    LBHKeyValueObservingOptionNew = 0x01,
    LBHKeyValueObservingOptionOld = 0x02,
};

//MARK: - LBHInfo 信息Model
@interface LBHKVOInfo : NSObject
@property (nonatomic, weak) NSObject *observer;
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, assign) LBHKeyValueObservingOptions options;
@property (nonatomic, copy) LBHKVOBlock hanldBlock;

@end

@class LBHKVOInfo;

@interface NSObject (LBHKVO)

/**
 * 添加观察者
 */
- (void)lbh_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath block:(LBHKVOBlock)block;

- (void)lbh_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(LBHKeyValueObservingOptions)options context:(nullable void *)context block:(LBHKVOBlock)block;
/**
 * 回调
 */
- (void)lbh_observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context;
/**
 * 移除观察者
 */
- (void)lbh_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;

@end



NS_ASSUME_NONNULL_END
