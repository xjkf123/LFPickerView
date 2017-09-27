# LFPickerView
    LFPickerViewTypeMenu,//菜单文本选择类型     LFPickerViewTypeDate,//日期选择类型
    菜单支持所有已知样式，时间支持年月日，距离现在最大天数，最小天数设置


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
