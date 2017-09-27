//
//  LFPickerView.h
//  LFPickerView
//
//  Created by 悟🔥空 on 2017/9/14.
//  Copyright © 2017年 悟🔥空. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum LFPickerViewType {
    LFPickerViewTypeMenu,//菜单文本选择类型
    LFPickerViewTypeDate,//日期选择类型
}LFPickerViewType;


/**
 CompletionMenuBlock  菜单类型返回Block

 @param indexPathArray 选择数组下标
 @param showTitleArray 选择数组内容
 */
typedef void (^CompletionMenuBlock)(NSArray *indexPathArray,NSArray *showTitleArray);

/**
 CompletionDateBlock 日期选择返回Block

 @param dateString 返回选择时间String
 @param format 返回选择时间格式
 */
typedef void (^CompletionDateBlock)(NSString *dateString,NSString *format);

@interface LFPickerView : UIView<UIPickerViewDelegate,UIPickerViewDataSource> {
    UIControl *_bgControl;
    UIPickerView *_lfPickerView;
    NSDate *_maxShowDate;//最大显示日期
    NSDate *_minShowDate;//最小显示日期
}

@property (nonatomic, copy) CompletionMenuBlock completionMenuBlock;
@property (nonatomic, copy) CompletionDateBlock completionDateBlock;
@property (nonatomic, assign) LFPickerViewType lfPickerViewType;

@property (nonatomic, strong) NSMutableArray *contentArray;//接收到的数组
@property (nonatomic, strong) NSMutableArray *showTitleArray;//当前选择内容数组
@property (nonatomic, strong) NSMutableArray *indexPathArray;//当前选择坐标数组

@property (nonatomic, strong) NSArray *showDateStyle;//显示时间类型项
@property (nonatomic, strong) NSString *defaultDateString;//初始化设置时间
@property (nonatomic, strong) NSString *format;//输出格式
@property (nonatomic, assign) long nowMoreThanDay;//选择不能超过当前多少天
@property (nonatomic, assign) long nowbelowDay;//选择不能低于当前多少天

+ (LFPickerView *)shareLFPickerView;


/**
 菜单文本定义方法

 @param title 选择器标题
 @param contentArray 选择器菜单项（注意传值方式，支持所有类型的菜单选择）
 @param defaultTitles 初始化显示定位（不传默认第一栏选中）
 @param completeBlock 完成返回选择项item，及，菜单项
 
 传值样式，及，试验数据
 NSArray *title = @[@[@"通过",@"不通过",@"第三种"],@[@[@"有征信通过",@"无征信通过"],@[],@[@"关注",@"禁入",@"其他"]],@[@[],@[],@[@[@"牛逼",@"牛逼"],@[@"牛逼"],@[@"牛逼"]]]];
 NSArray *defaultTitles = @[@"通过",@"无征信通过"];
 */
- (void)showTitle:(NSString *)title contentArray:(NSArray *)contentArray defaultTitles:(NSArray *)defaultTitles completeBlock:(CompletionMenuBlock)completeBlock;


/**
 日期选择类型

 @param title 选择器标题
 @param dateString 初始化显示定位（不传默认第一栏选中）
 @param completeBlock 完成返回选择项
 */
- (void)showTitle:(NSString *)title stringToDate:(NSString *)dateString completeBlock:(CompletionDateBlock)completeBlock;
@end
