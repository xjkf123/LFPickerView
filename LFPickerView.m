//
//  LFPickerView.m
//  LFPickerView
//
//  Created by 悟🔥空 on 2017/9/14.
//  Copyright © 2017年 悟🔥空. All rights reserved.
//

#import "LFPickerView.h"
#define LFPickerViewHeight 266.0*LFAdapterHeight
#define LFToolbarViewHeight 50.0*LFAdapterHeight
#define LFMaxNowDifferenceDay 7300     //默认最大7300天，20年
#define LFMinNowDifferenceDay 7300     //默认最小7300天，20年
#define LFMarginWidth  15.0*LFAdapterWidth         //距离视图边距
#define LFScreenHeight [UIScreen mainScreen].bounds.size.height
#define LFScreenWidth [UIScreen mainScreen].bounds.size.width
#define LFAdapterHeight ([UIScreen mainScreen].bounds.size.height/667.0)
#define LFAdapterWidth ([UIScreen mainScreen].bounds.size.width/375.0)

@implementation LFPickerView
#pragma mark - 创建一个单利对象
+ (LFPickerView *)shareLFPickerView {
    static LFPickerView *_lfPickerView;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _lfPickerView = [[LFPickerView alloc] init];
    });
    return _lfPickerView;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, LFScreenHeight - LFPickerViewHeight, LFScreenWidth, LFPickerViewHeight);
        self.backgroundColor = [UIColor whiteColor];
        //工具栏。
        UIView *toolbarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, LFScreenWidth, LFToolbarViewHeight)];
        CGSize sizeButton = [self sizeWidthStr:@"取消" andFontSize:16.0 * LFAdapterWidth];
        float buttonWidth = sizeButton.width + 2.0*LFMarginWidth;
        //工具栏。取消
        UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonWidth, LFToolbarViewHeight)];
        cancelButton.titleLabel.font = [UIFont systemFontOfSize:16.0 * LFAdapterWidth];
        [cancelButton setTitle:[NSString stringWithFormat:@"%@",@"取消"] forState:UIControlStateNormal];
        [cancelButton setTitleColor:[self colorWithHexString:@"#d2b883"] forState:UIControlStateNormal];
        [cancelButton addTarget:self action:@selector(hiddenLFPickerView) forControlEvents:UIControlEventTouchUpInside];
        [toolbarView addSubview:cancelButton];
        //工具栏。标题
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(sizeButton.width + 2.0*LFMarginWidth, 0, LFScreenWidth - 2*buttonWidth, LFToolbarViewHeight)];
        titleLabel.textColor = [self colorWithHexString:@"333333"];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont systemFontOfSize:16.0 * LFAdapterWidth];
        titleLabel.tag = 2000;
        [toolbarView addSubview:titleLabel];
        //工具栏。完成
        UIButton *completionButton = [[UIButton alloc] initWithFrame:CGRectMake(LFScreenWidth  - buttonWidth, 0, buttonWidth, LFToolbarViewHeight)];
        completionButton.titleLabel.font = [UIFont systemFontOfSize:16.0 * LFAdapterWidth];
        [completionButton setTitle:[NSString stringWithFormat:@"%@",@"完成"] forState:UIControlStateNormal];
        [completionButton setTitleColor:[self colorWithHexString:@"#d2b883"] forState:UIControlStateNormal];
        [completionButton addTarget:self action:@selector(completion) forControlEvents:UIControlEventTouchUpInside];
        [toolbarView addSubview:completionButton];
        [self addSubview:toolbarView];
        //LFPickerView. 选择器
        _lfPickerView = [[UIPickerView alloc]initWithFrame:CGRectMake(0, LFToolbarViewHeight, LFScreenWidth, LFPickerViewHeight - LFToolbarViewHeight)];
        _lfPickerView.backgroundColor = [UIColor whiteColor];
        _lfPickerView.showsSelectionIndicator = YES;
        _lfPickerView.delegate = self;
        _lfPickerView.dataSource = self;
        [self addSubview:_lfPickerView];
        //设置默认最大天数
        _nowMoreThanDay = LFMaxNowDifferenceDay;
        _nowbelowDay = LFMaxNowDifferenceDay;
    }
    return self;
}

#pragma mark - 添加到主window上，隐藏会移除
- (void)addSubViewkeyWindow{
    //创建背景层
    _bgControl = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, LFScreenWidth, LFScreenHeight)];
    _bgControl.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    [_bgControl addTarget:self action:@selector(hiddenLFPickerView) forControlEvents:UIControlEventTouchUpInside];
    //显示当前keyWindo
    UIWindow *kewWindow = [UIApplication sharedApplication].keyWindow;
    if (kewWindow) {
        [kewWindow.rootViewController.view addSubview:_bgControl];
    }
    [_bgControl addSubview:self];
    _bgControl.hidden = YES;
}

//////////////////////////////LFPickerViewTypeMenu 基本配置开始//////////////////////////////////////////////////////
#pragma - mark - 弹出LFPickerView+动画
- (void)showTitle:(NSString *)title contentArray:(NSArray *)contentArray defaultTitles:(NSArray *)defaultTitles completeBlock:(CompletionMenuBlock)completeBlock {
    //初始化数据
    [self addSubViewkeyWindow];
    self.completionMenuBlock = completeBlock;
    _contentArray = [NSMutableArray arrayWithArray:contentArray];
    _lfPickerViewType = LFPickerViewTypeMenu;
    _showTitleArray = [NSMutableArray array];
    _indexPathArray = [NSMutableArray array];

    //默认化设置
    [self reloadPresentAndSubArraySelectRow:0 inComponent:0];
    if (defaultTitles.count > 0) {
        //如果有初始化选择，自动定位到自动选择
        for (int i = 0; i < defaultTitles.count; i++) {
            NSString *defaultTitle  = [defaultTitles objectAtIndex:i];
            NSArray *presentArray = [self foundArrayInComponent:i];
            NSInteger index = [presentArray indexOfObject:defaultTitle];
            if (index != NSIntegerMax) {
                [self reloadPresentAndSubArraySelectRow:index inComponent:i];
            }
        }
    }
    //显示view
    [self showLFPickerView:title];
}

#pragma mark - 重置当前选项及子选项
- (void)reloadPresentAndSubArraySelectRow:(NSInteger)row inComponent:(NSInteger)component{
    //移除当前列数组文本，及选择项
    for (int i = (int)_indexPathArray.count - 1; i >= (int)component; i--) {
        [_indexPathArray removeObjectAtIndex:i];
        [_showTitleArray removeObjectAtIndex:i];
    }
    //获取设置当前列选择文本
    NSArray *presentArray = [self foundArrayInComponent:(int)component];
    if (presentArray.count > 0) {
        [_showTitleArray addObject:presentArray];
        [_indexPathArray addObject:@[[NSNumber numberWithInteger:component],[NSNumber numberWithInteger:row]]];
    }
    
    //初始化设置子类选择，最大列不能操作最大数组count
    int macCount = (int)_contentArray.count;
    for (int i = (int)component + 1; i < macCount; i++) {
        presentArray = [self foundArrayInComponent:(int)i];
        if (presentArray.count > 0) {
            [_showTitleArray addObject:presentArray];
            [_indexPathArray addObject:@[[NSNumber numberWithInteger:i],[NSNumber numberWithInteger:0]]];
        }
    }
    
    //刷新加载选择,这里一定要全部刷新，不然单行刷新会数组越界
    [_lfPickerView reloadAllComponents];
    for (int i = 0; i < _indexPathArray.count; i++) {
        NSInteger componentTemp= [_indexPathArray[i][0] integerValue];
        NSInteger rowTemp = [_indexPathArray[i][1] integerValue];
        [_lfPickerView selectRow:rowTemp inComponent:componentTemp animated:NO];
    }
}

#pragma mark - 获取当前选择的文本数组
- (NSArray *)foundArrayInComponent:(int)inComponent{
    NSArray *kindClass = _contentArray[inComponent];
    for (int i = 0; i < inComponent; i++) {
        if (kindClass.count != 0) {
            NSInteger chooseRow = [_indexPathArray[i][1] integerValue];
            kindClass = kindClass[chooseRow];
        } else {
            break;
        }
    }
    return kindClass;
}
//////////////////////////////LFPickerViewTypeMenu基本配置结束//////////////////////////////////////////////////////

//////////////////////////////LFPickerViewTypeDate基本配置开始//////////////////////////////////////////////////////
- (void)showTitle:(NSString *)title stringToDate:(NSString *)dateString completeBlock:(CompletionDateBlock)completeBlock{
    //初始化数据
    [self addSubViewkeyWindow];
    _completionDateBlock = completeBlock;
    _lfPickerViewType = LFPickerViewTypeDate;
    _showTitleArray = [NSMutableArray array];
    _showDateStyle = @[@"NSCalendarUnitYear",@"NSCalendarUnitMonth",@"NSCalendarUnitDay"];
    _defaultDateString = dateString;
    _format = @"yyyy-MM-dd";
    long nowMoreThanDay = _nowMoreThanDay * 24.0 * 60.0 * 60.0;//距离当前最多多少天，默认7300天，20年
    long nowbelowDay = _nowbelowDay * 24.0 * 60.0 * 60.0;//距离当前最少多少天，默认7300天，20年
    _minShowDate = [[NSDate date] initWithTimeIntervalSinceNow:-nowbelowDay];//最小显示日期，以当前时间作为临界
    _maxShowDate = [[NSDate date] initWithTimeIntervalSinceNow:nowMoreThanDay];//最大显示日期，以当前时间作为临界
    
    //默认显示时间
    NSDate *currentDate = [NSDate date];
    if (_defaultDateString.length > 0 && ![_defaultDateString isEqualToString:@"(null)"]) {
        //设置默认显示时间，否则显示当前时间
        currentDate = [self stringToDate:_defaultDateString withDateFormat:_format];
    }
    NSDateComponents *currentDateComponents = [self LFDateComponents:currentDate];
    NSDateComponents *minShowDateComponents = [self LFDateComponents:_minShowDate];
    NSDateComponents *maxShowDateComponents = [self LFDateComponents:_maxShowDate];
    
    [self changeArrayMin:[minShowDateComponents year] max:[maxShowDateComponents year] inComponent:0];
    [self currentShooseYear:[NSString stringWithFormat:@"%ld",[currentDateComponents year]] shooseMonth:[NSString stringWithFormat:@"%ld",[currentDateComponents month]]];
    
    [_lfPickerView selectRow:[_showTitleArray[0] indexOfObject:[NSString stringWithFormat:@"%ld",(long)[currentDateComponents year]]] inComponent:0 animated:NO];
    [_lfPickerView selectRow:[_showTitleArray[1] indexOfObject:[NSString stringWithFormat:@"%ld",(long)[currentDateComponents month]]] inComponent:1 animated:NO];
    [_lfPickerView selectRow:[_showTitleArray[2] indexOfObject:[NSString stringWithFormat:@"%ld",(long)[currentDateComponents day]]] inComponent:2 animated:NO];
    
    //显示view
    [self showLFPickerView:title];
}
#pragma mark - 配置显示列数组
- (void)changeArrayMin:(NSInteger)min max:(NSInteger)max inComponent:(int)inComponent{
    NSMutableArray *changeArray = [NSMutableArray array];
    for (int i = (int)min; i <= (int)max; i++) {
        [changeArray addObject:[NSString stringWithFormat:@"%d",i]];
    }
    if (_showTitleArray.count >= inComponent + 1) {
        [_showTitleArray replaceObjectAtIndex:inComponent withObject:changeArray];
    } else {
        [_showTitleArray addObject:changeArray];
    }
    [_lfPickerView reloadAllComponents];
}

#pragma mark -
- (NSDateComponents *)LFDateComponents:(NSDate *)date {
    NSCalendar *calendar = [[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSCalendarUnit calendarUnit = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSDateComponents *dateComponents = [calendar components:calendarUnit fromDate:date];
    return dateComponents;
}

#pragma mark - 获取某年某月的天数
- (NSInteger)howManyDaysInThisYear:(NSString *)lfYear withMonth:(NSString *)lfMonth{
    int year = [lfYear intValue];
    int month = [lfMonth intValue];
    if((month == 1) || (month == 3) || (month == 5) || (month == 7) || (month == 8) || (month == 10) || (month == 12))
        return 31 ;
    
    if((month == 4) || (month == 6) || (month == 9) || (month == 11))
        return 30;
    
    if((year % 4 == 1) || (year % 4 == 2) || (year % 4 == 3))
        return 28;
    
    if(year % 400 == 0)
        return 29;
    
    if(year % 100 == 0)
        return 28;
    
    return 29;
}

#pragma mark - 日期格式转字符串
- (NSString *)dateToString:(NSDate *)date withDateFormat:(NSString *)format {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:format];
    NSString *strDate = [dateFormatter stringFromDate:date];
    return strDate;
}
#pragma mark - 字符串转日期格式
- (NSDate *)stringToDate:(NSString *)dateString withDateFormat:(NSString *)format{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:format];
    
    NSDate *date = [dateFormatter dateFromString:dateString];
    return [self worldTimeToChinaTime:date];
}
#pragma mark - 将世界时间转化为中国区时间
- (NSDate *)worldTimeToChinaTime:(NSDate *)date{
    NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
    NSInteger interval = [timeZone secondsFromGMTForDate:date];
    NSDate *localeDate = [date  dateByAddingTimeInterval:interval];
    return localeDate;
}
//////////////////////////////LFPickerViewTypeDate基本配置结束//////////////////////////////////////////////////////


#pragma - mark - 显示LFPickerView+动画
- (void)showLFPickerView:(NSString *)pickerTitle{
    //设置LFPickerView 标题
    UILabel *titleLabel = (UILabel *)[self viewWithTag:2000];
    titleLabel.text = pickerTitle?pickerTitle:@"欢迎使用LFPickerView";
    
    //显示动画
    _bgControl.hidden = NO;
    self.frame = CGRectMake(0, LFScreenHeight, LFScreenWidth, LFPickerViewHeight);
    [UIView animateWithDuration:0.3 animations:^{
        self.frame = CGRectMake(0, LFScreenHeight - LFPickerViewHeight, LFScreenWidth, LFPickerViewHeight);
    }];
}
#pragma - mark - 隐藏LFPickerView+动画
- (void)hiddenLFPickerView {
    //设置默认最大天数
    _nowMoreThanDay = LFMaxNowDifferenceDay;
    _nowbelowDay = LFMaxNowDifferenceDay;
    self.frame = CGRectMake(0, LFScreenHeight - LFPickerViewHeight, LFScreenWidth, LFPickerViewHeight);
    [UIView animateWithDuration:0.3 animations:^{
        self.frame = CGRectMake(0, LFScreenHeight, LFScreenWidth, LFPickerViewHeight);
    } completion:^(BOOL finished) {
        _bgControl.hidden = YES;
    }] ;
}

#pragma mark - 读取字体尺寸
- (CGSize)sizeWidthStr:(NSString *)string andFontSize:(CGFloat)fontSize{
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:[UIFont systemFontOfSize:fontSize],NSFontAttributeName, nil];
    CGSize stringSize = [[NSString stringWithFormat:@"%@",string] sizeWithAttributes:dict];
    return stringSize;
}

#pragma mark - 设置颜色
- (UIColor *) colorWithHexString: (NSString *) stringToConvert{
    NSString *cString = [[stringToConvert stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    if ([cString hasPrefix:@"#"]) cString = [cString substringFromIndex:1];
    if ([cString length] != 6) return [UIColor blackColor];
    // Separate into r, g, b substrings
    NSRange range;
    range.length = 2;
    
    range.location = 0;
    NSString *rString = [cString substringWithRange:range];
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1];
}

#pragma mark - UIPickerViewDelegate, UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    //多少列
    return _showTitleArray.count;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    //多少行
    return [[_showTitleArray objectAtIndex:component] count];
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view  {
    // 改变分割线的颜色
    for(UIView *speartorView in _lfPickerView.subviews){
        if (speartorView.frame.size.height < 1){//取出分割线view
            speartorView.backgroundColor = [self colorWithHexString:@"#d1d1d1"];
        }
    }
    //设置当前文本
    UILabel *pickerLabel = (UILabel *)view;
    CGFloat labelWidth =  CGRectGetWidth(pickerView.frame) / _showTitleArray.count;
    CGSize pickerLabelSize = [self sizeWidthStr:@"文本" andFontSize:16.0 * LFAdapterWidth];
    pickerLabel = [[UILabel alloc]initWithFrame:CGRectMake(0.0f, 0.0f, labelWidth, pickerLabelSize.height)];
    pickerLabel.textAlignment = NSTextAlignmentCenter;
    pickerLabel.font = [UIFont systemFontOfSize:16.0 * LFAdapterWidth];
    pickerLabel.textColor = [self colorWithHexString:@"333333"];
    pickerLabel.backgroundColor = [UIColor clearColor];
    pickerLabel.text = _showTitleArray[component][row];

    return pickerLabel;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (_lfPickerViewType == LFPickerViewTypeMenu) {
        [self reloadPresentAndSubArraySelectRow:row inComponent:component];
    } else if (_lfPickerViewType == LFPickerViewTypeDate) {
        [self currentShooseYear:[self chooseText:0] shooseMonth:[self chooseText:1]];
    }
}

#pragma mark - 获取当前列选择文本
- (NSString *)chooseText:(int)component {
    NSInteger chooseRow = [_lfPickerView selectedRowInComponent:component];
    NSString *chooseText = _showTitleArray[component][chooseRow];
    return chooseText;
}

#pragma mark - 刷新当前选择
- (void)currentShooseYear:(NSString *)shooseYear shooseMonth:(NSString *)shooseMonth{
    
    NSInteger maxYear = [[self LFDateComponents:_maxShowDate] year];
    NSInteger maxMonth = [[self LFDateComponents:_maxShowDate] month];
    NSInteger minYear = [[self LFDateComponents:_minShowDate] year];
    NSInteger minMonth = [[self LFDateComponents:_minShowDate] month];
    if ([[NSString stringWithFormat:@"%ld",maxYear] isEqualToString:shooseYear]){
        //当前是最大年
        NSDateComponents *minShowDateComponents = [self LFDateComponents:_minShowDate];
        NSDateComponents *maxShowDateComponents = [self LFDateComponents:_maxShowDate];
        [self changeArrayMin:[minShowDateComponents month] max:[maxShowDateComponents month] inComponent:1];
        
        NSInteger minDay = 1;
        NSInteger maxDay = [self howManyDaysInThisYear:shooseYear withMonth:shooseMonth];
        if ([[NSString stringWithFormat:@"%ld",maxMonth] isEqualToString:shooseMonth]){
            //当月是最大月
            maxDay = [maxShowDateComponents day];
        }
        if ([[NSString stringWithFormat:@"%ld",minMonth] isEqualToString:shooseMonth]) {
            //当月是最小月
            minDay = [minShowDateComponents day];
        }
        [self changeArrayMin:minDay max:maxDay inComponent:2];
    } else if ([[NSString stringWithFormat:@"%ld",minYear] isEqualToString:shooseYear]) {
        //当前是最小年
        NSDateComponents *minShowDateComponents = [self LFDateComponents:_minShowDate];
        NSDateComponents *maxShowDateComponents = [self LFDateComponents:_maxShowDate];
        [self changeArrayMin:[minShowDateComponents month] max:[maxShowDateComponents month] inComponent:1];
        
        NSInteger minDay = 1;
        NSInteger maxDay = [self howManyDaysInThisYear:shooseYear withMonth:shooseMonth];
        if ([[NSString stringWithFormat:@"%ld",maxMonth] isEqualToString:shooseMonth]){
            //当月是最大月
            maxDay = [maxShowDateComponents day];
        }
        if ([[NSString stringWithFormat:@"%ld",minMonth] isEqualToString:shooseMonth]) {
            //当月是最小月
            minDay = [minShowDateComponents day];
        }
        [self changeArrayMin:minDay max:maxDay inComponent:2];
    } else {
        //当前是正常年
        [self changeArrayMin:1 max:12 inComponent:1];
        [self changeArrayMin:1 max:[self howManyDaysInThisYear:shooseYear withMonth:shooseMonth] inComponent:2];
    }
}

#pragma mark - 点击完成回调
- (void)completion {
    if (_lfPickerViewType == LFPickerViewTypeMenu) {
        NSMutableArray *blockTextArray = [NSMutableArray array];
        for (int i = 0; i < _indexPathArray.count; i++) {
            NSInteger componentTemp = [_indexPathArray[i][0] integerValue];
            NSInteger rowTemp = [_indexPathArray[i][1] integerValue];
            [blockTextArray addObject:[NSString stringWithFormat:@"%@",_showTitleArray[componentTemp][rowTemp]]];
        }
        NSLog(@"");
        self.completionMenuBlock(_indexPathArray,blockTextArray);
    } else if (_lfPickerViewType == LFPickerViewTypeDate) {
        
        NSDateComponents *dateComponents = [[NSDateComponents alloc]init];
        dateComponents.year = [[self chooseText:0] integerValue];
        dateComponents.month = [[self chooseText:1] integerValue];
        dateComponents.day = [[self chooseText:2] integerValue];
        NSCalendar *calendar = [[NSCalendar alloc]initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDate *selectedDate = [calendar dateFromComponents:dateComponents];
        NSDateFormatter *dateFomatter = [[NSDateFormatter alloc] init];
        dateFomatter.dateFormat = _format;
        NSString *nowDateStr = [dateFomatter stringFromDate:selectedDate];
        _completionDateBlock(nowDateStr,_format);
    }
    
    [self hiddenLFPickerView];
}
@end
