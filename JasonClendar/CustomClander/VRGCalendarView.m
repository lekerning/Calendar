//
//  VRGCalendarView.m
//  Vurig
//
//  Created by in 't Veen Tjeerd on 5/8/12.
//  Copyright (c) 2012 Vurig Media. All rights reserved.
//

#import "VRGCalendarView.h"
#import <QuartzCore/QuartzCore.h>
#import "NSDate+convenience.h"
#import "NSMutableArray+convenience.h"
#import "UIView+convenience.h"

@implementation VRGCalendarView
@synthesize currentMonth,delegate,labelCurrentMonth, animationView_A,animationView_B;
@synthesize markedDates,markedColors,calendarHeight,selectedDate,previousMarkedDates,nextMarkedDates,monthSwitchEnable,daySelectedEnable;

#pragma mark - Select Date
-(void)selectDate:(int)date {
    
    NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
    NSDateComponents *comps = [gregorian components:NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit fromDate:self.currentMonth];
    [comps setDay:date];
    self.selectedDate = [gregorian dateFromComponents:comps];
    
    
    int selectedDateYear = [selectedDate year];
    int selectedDateMonth = [selectedDate month];
    int currentMonthYear = [currentMonth year];
    int currentMonthMonth = [currentMonth month];
    
    if(selectedDateYear < currentMonthYear){
        [self showPreviousMonth];
        
    }else if (selectedDateYear > currentMonthYear) {
        [self showNextMonth];
        
    }else if (selectedDateMonth < currentMonthMonth) {
        [self showPreviousMonth];
        
    }else if (selectedDateMonth > currentMonthMonth) {
        [self showNextMonth];
    
    }else{
        
        [self setNeedsDisplay];
        
    }
    
    if ([delegate respondsToSelector:@selector(calendarView:dateSelected:)]) [delegate calendarView:self dateSelected:self.selectedDate];
    
    
}


#pragma mark - Mark Dates
//NSArray can either contain NSDate objects or NSNumber objects with an int of the day.
-(void)markDates:(NSArray *)dates {
    self.markedDates = dates;
    NSMutableArray *colors = [[NSMutableArray alloc] init];
    
    for (int i = 0; i<[dates count]; i++) {
        [colors addObject:[UIColor colorWithHexString:@"0x383838"]];
    }
    
    self.markedColors = [NSArray arrayWithArray:colors];
    [colors release];
    
    [self setNeedsDisplay];
}

//NSArray can either contain NSDate objects or NSNumber objects with an int of the day.
-(void)markDates:(NSArray *)dates withColors:(NSArray *)colors {
    self.markedDates = dates;
    self.markedColors = colors;
    
    [self setNeedsDisplay];
    
}

#pragma mark - Set date to now
-(void)reset{
    
    NSCalendar *gregorian = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
    NSDateComponents *components =  [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate: [NSDate date]];
    self.currentMonth = [gregorian dateFromComponents:components]; //clean month
    [self updateSize];
    [self setNeedsDisplay];
    [delegate calendarView:self switchedToMonth:currentMonth targetHeight:self.calendarHeight animated:NO];

}

#pragma mark - Next & Previous
-(void)showNextMonth {
    if (isAnimating || !monthSwitchEnable || !daySelectedEnable) return;
    self.previousMarkedDates = nil;
    self.markedDates=nil;
    self.nextMarkedDates = nil;
    monthSwitchEnable = YES;
    daySelectedEnable = YES;
    isAnimating=YES;
    prepAnimationNextMonth=YES;
    
    [self setNeedsDisplay];
    
    int lastBlock = [currentMonth firstWeekDayInMonth]+[currentMonth numDaysInMonth]-1;
    int numBlocks = [self numRows]*7;
    BOOL hasNextMonthDays = lastBlock<numBlocks;
    
    //Old month
    float oldSize = self.calendarHeight;
    UIImage *imageCurrentMonth = [self drawCurrentState];
    
    //New month
    self.currentMonth = [currentMonth offsetMonth:1];
   
    if ([delegate respondsToSelector:@selector(calendarView:switchedToMonth:targetHeight: animated:)]) [delegate calendarView:self switchedToMonth:currentMonth targetHeight:self.calendarHeight animated:YES];
    prepAnimationNextMonth=NO;
    [self setNeedsDisplay];

    UIImage *imageNextMonth = [self drawCurrentState];
    float targetSize = fmaxf(oldSize, self.calendarHeight);
    UIView *animationHolder = [[UIView alloc] initWithFrame:CGRectMake(0, kVRGCalendarViewTopBarHeight, kVRGCalendarViewWidth, targetSize-kVRGCalendarViewTopBarHeight)];
    [animationHolder setClipsToBounds:YES];
    [self addSubview:animationHolder];
    [animationHolder release];
    
    //Animate
    self.animationView_A = [[[UIImageView alloc] initWithImage:imageCurrentMonth] autorelease];
    self.animationView_B = [[[UIImageView alloc] initWithImage:imageNextMonth] autorelease];
    [animationHolder addSubview:animationView_A];
    [animationHolder addSubview:animationView_B];
    
    if (hasNextMonthDays) {
        animationView_B.frameY = animationView_A.frameY + animationView_A.frameHeight - (kVRGCalendarViewDayHeight+3);
    } else {
        animationView_B.frameY = animationView_A.frameY + animationView_A.frameHeight -3;
    }
    
    //Animation
    __block VRGCalendarView *blockSafeSelf = self;
    [UIView animateWithDuration:.35
                     animations:^{
                         [self updateSize];
                         //blockSafeSelf.frameHeight = 100;
                         if (hasNextMonthDays) {
                             animationView_A.frameY = -animationView_A.frameHeight + kVRGCalendarViewDayHeight+3;
                         } else {
                             animationView_A.frameY = -animationView_A.frameHeight + 3;
                         }
                         animationView_B.frameY = 0;
                     }completion:^(BOOL finished){
                         
                         [animationView_A removeFromSuperview];
                         [animationView_B removeFromSuperview];
                         blockSafeSelf.animationView_A=nil;
                         blockSafeSelf.animationView_B=nil;
                         isAnimating=NO;
                         [animationHolder removeFromSuperview];
                        
                     }
     ];
    
}

-(void)showPreviousMonth {
    if (isAnimating || !monthSwitchEnable || !daySelectedEnable) return;
    isAnimating=YES;
    self.previousMarkedDates = nil;
    self.markedDates=nil;
    self.nextMarkedDates = nil;
    //Prepare current screen
    prepAnimationPreviousMonth = YES;
    [self setNeedsDisplay];
    BOOL hasPreviousDays = [currentMonth firstWeekDayInMonth]>1;
    float oldSize = self.calendarHeight;
    UIImage *imageCurrentMonth = [self drawCurrentState];
    
    //Prepare next screen
    self.currentMonth = [currentMonth offsetMonth:-1];
  
    if ([delegate respondsToSelector:@selector(calendarView:switchedToMonth:targetHeight:animated:)]) [delegate calendarView:self switchedToMonth:currentMonth targetHeight:self.calendarHeight animated:YES];
    prepAnimationPreviousMonth=NO;
    [self setNeedsDisplay];
    
    UIImage *imagePreviousMonth = [self drawCurrentState];
    float targetSize = fmaxf(oldSize, self.calendarHeight);
    UIView *animationHolder = [[UIView alloc] initWithFrame:CGRectMake(0, kVRGCalendarViewTopBarHeight, kVRGCalendarViewWidth, targetSize-kVRGCalendarViewTopBarHeight)];
    
    [animationHolder setClipsToBounds:YES];
    [self addSubview:animationHolder];
    [animationHolder release];
    
    self.animationView_A = [[[UIImageView alloc] initWithImage:imageCurrentMonth] autorelease];
    self.animationView_B = [[[UIImageView alloc] initWithImage:imagePreviousMonth] autorelease];
    [animationHolder addSubview:animationView_A];
    [animationHolder addSubview:animationView_B];
    
    if (hasPreviousDays) {
        animationView_B.frameY = animationView_A.frameY - (animationView_B.frameHeight-kVRGCalendarViewDayHeight) + 3;
    } else {
        animationView_B.frameY = animationView_A.frameY - animationView_B.frameHeight + 3;
    }
    
    __block VRGCalendarView *blockSafeSelf = self;
    [UIView animateWithDuration:.35
                     animations:^{
                         [self updateSize];
                         
                         if (hasPreviousDays) {
                             animationView_A.frameY = animationView_B.frameHeight-(kVRGCalendarViewDayHeight+3); 
                             
                         } else {
                             animationView_A.frameY = animationView_B.frameHeight-3;
                         }
                         
                         animationView_B.frameY = 0;
                     }
                     completion:^(BOOL finished) {
                         [animationView_A removeFromSuperview];
                         [animationView_B removeFromSuperview];
                         blockSafeSelf.animationView_A=nil;
                         blockSafeSelf.animationView_B=nil;
                         isAnimating=NO;
                         [animationHolder removeFromSuperview];
                        
                     }
     ];
    
    
}


#pragma mark - update size & row count
-(void)updateSize{
    self.frameHeight = self.calendarHeight;
    [self setNeedsDisplay];
}

-(float)calendarHeight {
    return kVRGCalendarViewTopBarHeight + [self numRows]*(kVRGCalendarViewDayHeight+2)+1;
}

-(int)numRows {
    float lastBlock = [self.currentMonth numDaysInMonth]+([self.currentMonth firstWeekDayInMonth]-1);
    return ceilf(lastBlock/7);
    
}

#pragma mark - Touches
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    if(!monthSwitchEnable || !daySelectedEnable){
    
        return;
    }
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    self.selectedDate=nil;
    //选中特定的某一天
    if (touchPoint.y > kVRGCalendarViewTopBarHeight) {
        float xLocation = touchPoint.x;
        float yLocation = touchPoint.y-kVRGCalendarViewTopBarHeight;
        int column = floorf(xLocation/(kVRGCalendarViewDayWidth+2));
        int row = floorf(yLocation/(kVRGCalendarViewDayHeight+2));
        int blockNr = (column+1)+row*7;
        int firstWeekDay = [self.currentMonth firstWeekDayInMonth]-1; //-1 because weekdays begin at 1, not 0
        int date = blockNr-firstWeekDay;
        [self selectDate:date];
        return;
    
        
    }
    
    self.previousMarkedDates = nil;
    self.markedDates=nil;
    self.nextMarkedDates = nil;
    self.markedColors=nil;  
    
    CGRect rectArrowLeft = CGRectMake(0, 0, 40, 30);
    CGRect rectArrowRight = CGRectMake(self.frame.size.width-40, 0, 40, 30);
    
    //Touch either arrows or month in middle
    if (CGRectContainsPoint(rectArrowLeft, touchPoint)){
        
      //[self showPreviousMonth];
        
        
        
    } else if (CGRectContainsPoint(rectArrowRight, touchPoint)){
        
       // [self showNextMonth];
        
    }else if(CGRectContainsPoint(self.labelCurrentMonth.frame, touchPoint)) {
        //Detect touch in current month
        int currentMonthIndex = [self.currentMonth month];
        int todayMonth = [[NSDate date] month];
        [self reset];
        if ((todayMonth!=currentMonthIndex) && [delegate respondsToSelector:@selector(calendarView:switchedToMonth:targetHeight:animated:)]) [delegate calendarView:self switchedToMonth:currentMonth targetHeight:self.calendarHeight animated:NO];
    }
    
}

#pragma mark - Drawing
- (void)drawRect:(CGRect)rect{
    
    int firstWeekDay = [self.currentMonth firstWeekDayInMonth]-1; //-1 because weekdays begin at 1, not 0
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"] autorelease]];
    [formatter setDateFormat:@"MM月yyyy年"];
    labelCurrentMonth.text = [formatter stringFromDate:self.currentMonth];
   // [labelCurrentMonth sizeToFit];
   // labelCurrentMonth.frameX = roundf(self.frame.size.width/2 - labelCurrentMonth.frameWidth/2);
   // labelCurrentMonth.frameY = 0;
    [formatter release];
    [currentMonth firstWeekDayInMonth];
    
    CGContextClearRect(UIGraphicsGetCurrentContext(),rect);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect rectangle = CGRectMake(0,0,self.frame.size.width,kVRGCalendarViewTopBarHeight);
   // CGContextDrawTiledImage(context, rectangle,[UIImage imageNamed:@"pattern.png"].CGImage);
    
    CGContextAddRect(context, rectangle);
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:232.0/255 green:232.0/255 blue:232.0/255 alpha:1.0].CGColor);
    CGContextFillPath(context);
    
    
    //Weekdays
    
 //   NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  //  dateFormatter.dateFormat=@"EEE";
    //always assume gregorian with monday first
   // NSMutableArray *weekdays = [[NSMutableArray alloc] initWithArray:[dateFormatter shortWeekdaySymbols]];
  //  [weekdays moveObjectFromIndex:0 toIndex:6];
  //  [dateFormatter release];
    NSMutableArray *weekdays = [NSMutableArray arrayWithObjects:@"周日",@"周一",@"周二",@"周三",@"周四",@"周五",@"周六", nil];
    CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:@"0x383838"].CGColor);
    for (int i =0; i<[weekdays count]; i++) {
        NSString *weekdayValue = (NSString *)[weekdays objectAtIndex:i];
        UIFont *font = [UIFont fontWithName:@"HelveticaNeue" size:10];
        [weekdayValue drawInRect:CGRectMake(i*(kVRGCalendarViewDayWidth+2), 35, kVRGCalendarViewDayWidth+2, 20) withFont:font lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
    }
    
  //  [weekdays release];
    int numRows = [self numRows];
    CGContextSetAllowsAntialiasing(context, NO);
    
    //Grid background
    float gridHeight = numRows*(kVRGCalendarViewDayHeight+2)+1;
    CGRect rectangleGrid = CGRectMake(0,kVRGCalendarViewTopBarHeight,self.frame.size.width,gridHeight);
    CGContextAddRect(context, rectangleGrid);
    CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:@"0xf3f3f3"].CGColor);
    //CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:@"0xff0000"].CGColor);
    CGContextFillPath(context);

    for (int i = 1; i<7; i++) {
        //竖线
        CGContextSaveGState(context);
        CGContextBeginPath(context);
        CGContextSetStrokeColorWithColor(context,[UIColor colorWithRed:169.0/255 green:183.0/255 blue:195.0/255 alpha:1.0].CGColor);
        CGContextSetLineWidth(context, 0.5);
        CGContextMoveToPoint(context, i*(kVRGCalendarViewDayWidth+1)+i*1-1, kVRGCalendarViewTopBarHeight);
        CGContextAddLineToPoint(context, i*(kVRGCalendarViewDayWidth+1)+i*1-1, kVRGCalendarViewTopBarHeight+gridHeight);
        CGContextStrokePath(context);
        CGContextRestoreGState(context);
        if (i>numRows-1) continue;
        //rows  横线
        CGContextSaveGState(context);
        CGContextBeginPath(context);  
        CGContextSetLineWidth(context, 0.5);
        CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:96.0/255 green:124.0/255 blue:148.0/255 alpha:1.0].CGColor);
        CGContextMoveToPoint(context, 0, kVRGCalendarViewTopBarHeight+i*(kVRGCalendarViewDayHeight+1)+i*1+1);
        CGContextAddLineToPoint(context, kVRGCalendarViewWidth, kVRGCalendarViewTopBarHeight+i*(kVRGCalendarViewDayHeight+1)+i*1+1);
        CGContextStrokePath(context);
        CGContextRestoreGState(context);
    }

    CGContextSetAllowsAntialiasing(context, YES);
    
    //Draw days
    CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:@"0x383838"].CGColor);
    
    
    //NSLog(@"currentMonth month = %i, first weekday in month = %i",[self.currentMonth month],[self.currentMonth firstWeekDayInMonth]);
    
    int numBlocks = numRows*7;
    NSDate *previousMonth = [self.currentMonth offsetMonth:-1];
    int currentMonthNumDays = [currentMonth numDaysInMonth];
    int prevMonthNumDays = [previousMonth numDaysInMonth];
    int selectedDateBlock = ([selectedDate day]-1)+firstWeekDay;
    //prepAnimationPreviousMonth nog wat mee doen
    //prev next month
    BOOL isSelectedDatePreviousMonth = prepAnimationPreviousMonth;
    BOOL isSelectedDateNextMonth = prepAnimationNextMonth;
    
    if (self.selectedDate!=nil) {
        isSelectedDatePreviousMonth = ([selectedDate year]==[currentMonth year] && [selectedDate month]<[currentMonth month]) || [selectedDate year] < [currentMonth year];
        
        if (!isSelectedDatePreviousMonth) {
            isSelectedDateNextMonth = ([selectedDate year]==[currentMonth year] && [selectedDate month]>[currentMonth month]) || [selectedDate year] > [currentMonth year];
        }
    }
    
    if (isSelectedDatePreviousMonth) {
        int lastPositionPreviousMonth = firstWeekDay-1;
        selectedDateBlock=lastPositionPreviousMonth-([selectedDate numDaysInMonth]-[selectedDate day]);
    } else if (isSelectedDateNextMonth) {
        selectedDateBlock = [currentMonth numDaysInMonth] + (firstWeekDay-1) + [selectedDate day];
    }
    
    NSDate *todayDate = [NSDate date];
    int todayBlock = -1;
    
// NSLog(@"currentMonth month = %i day = %i, todaydate day = %i",[currentMonth month],[currentMonth day],[todayDate month]);
    if([todayDate month] == [currentMonth month] && [todayDate year] == [currentMonth year]){
    
        todayBlock = [todayDate day] + firstWeekDay - 1;
        
    }
    
    for (int i=0; i<numBlocks; i++) {
        int targetDate = i;
        int targetColumn = i%7;
        int targetRow = i/7;
        int targetX = targetColumn * (kVRGCalendarViewDayWidth+2);
        int targetY = kVRGCalendarViewTopBarHeight + targetRow * (kVRGCalendarViewDayHeight+2);
        // BOOL isCurrentMonth = NO;
        
        if (selectedDate && i==selectedDateBlock){
            
            CGRect rectangleGrid = CGRectMake(targetX -1,targetY+1,kVRGCalendarViewDayWidth+2,kVRGCalendarViewDayHeight+2);
            CGContextAddRect(context, rectangleGrid);
            CGContextSetFillColorWithColor(context, [UIColor colorWithRed:186.0/255 green:41.0/255 blue:51.0/255 alpha:1.0].CGColor);
            CGContextFillPath(context);
            
            CGContextSetFillColorWithColor(context,[UIColor whiteColor].CGColor);
        }else if(todayBlock==i) {
            
            CGRect rectangleGrid = CGRectMake(targetX-1,targetY+1,kVRGCalendarViewDayWidth+2,kVRGCalendarViewDayHeight+2);
            CGContextAddRect(context, rectangleGrid);
            CGContextSetFillColorWithColor(context, [UIColor colorWithRed:186.0/255 green:41.0/255 blue:51.0/255 alpha:0.7].CGColor);
            CGContextFillPath(context);
            CGContextSetFillColorWithColor(context,[UIColor whiteColor].CGColor);
            
        }

        if (i<firstWeekDay) { //previous month
            targetDate = (prevMonthNumDays-firstWeekDay)+(i+1);
            NSString *hex = (isSelectedDatePreviousMonth) ? @"0x383838" : @"aaaaaa";
            CGContextSetFillColorWithColor(context,[UIColor colorWithHexString:hex].CGColor);
            for(int j = 0;j < [self.previousMarkedDates count];j++){
                id dateObj = [self.previousMarkedDates objectAtIndex:j];
                if([dateObj isKindOfClass:[NSNumber class]]){
                    if([dateObj integerValue] == targetDate){
                        //画出标记
                        CGContextSaveGState(context);
//                        CGContextAddArc(context, targetX + 25, targetY + 50, 3, 0,2*M_PI, 1);
//                        CGContextSetFillColorWithColor(context, [QuitTools danlanColor].CGColor);
//                        CGContextFillPath(context);
                        CGContextAddArc(context, targetX + 36, targetY + 50, 3,0, 2*M_PI,1);
                        CGContextSetFillColorWithColor(context, [UIColor redColor].CGColor);
                        CGContextFillPath(context);
                        CGContextRestoreGState(context);
                        
                    }
                    
                }
                
            }
            
        }else if(i>=(firstWeekDay+currentMonthNumDays)) { //next month
            targetDate = (i+1) - (firstWeekDay+currentMonthNumDays);
            NSString *hex = (isSelectedDateNextMonth) ? @"0x383838" : @"aaaaaa";
            CGContextSetFillColorWithColor(context,[UIColor colorWithHexString:hex].CGColor);
            for(int j = 0;j < [self.nextMarkedDates count];j++){
                id dateObj = [self.nextMarkedDates objectAtIndex:j];
                if([dateObj isKindOfClass:[NSNumber class]]){
                    if([dateObj integerValue] == targetDate){
                        //画出标记
                        CGContextSaveGState(context);
//                        CGContextAddArc(context, targetX + 25, targetY + 50, 3, 0,2*M_PI, 1);
//                        CGContextSetFillColorWithColor(context, [QuitTools danlanColor].CGColor);
//                        CGContextFillPath(context);
                        CGContextAddArc(context, targetX + 36, targetY + 50, 3,0, 2*M_PI,1);
                        CGContextSetFillColorWithColor(context, [UIColor redColor].CGColor);
                        CGContextFillPath(context);
                        CGContextRestoreGState(context);
                    }
                    
                }
                
            }

            
        }else{ //current month
            // isCurrentMonth = YES;
            targetDate = (i-firstWeekDay)+1;
            NSString *hex = (isSelectedDatePreviousMonth || isSelectedDateNextMonth) ? @"0xaaaaaa" : @"0x383838";
            CGContextSetFillColorWithColor(context,[UIColor colorWithHexString:hex].CGColor);
            for(int j = 0;j < [self.markedDates count];j++){
                id dateObj = [self.markedDates objectAtIndex:j];
                if([dateObj isKindOfClass:[NSNumber class]]){
                    if([dateObj integerValue] == targetDate){
                        //画出标记
                        CGContextSaveGState(context);
//                        CGContextAddArc(context, targetX + 25, targetY + 50, 3, 0,2*M_PI, 1);
//                        CGContextSetFillColorWithColor(context, [QuitTools danlanColor].CGColor);
//                        CGContextFillPath(context);
                        CGContextAddArc(context, targetX + 36, targetY + 50, 3,0, 2*M_PI,1);
                        CGContextSetFillColorWithColor(context, [UIColor redColor].CGColor);
                        CGContextFillPath(context);
                        CGContextRestoreGState(context);
                        
                    }
                    
                }
                
            }

        }
        
        NSString *date = [NSString stringWithFormat:@"%i",targetDate];
             [date drawInRect:CGRectMake(targetX+2, targetY+10, kVRGCalendarViewDayWidth, kVRGCalendarViewDayHeight) withFont:[UIFont systemFontOfSize:17] lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];

    }
    
         
    //Grid white lines
    CGContextSaveGState(context);
    CGContextBeginPath(context);
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:204.0/255 green:204.0/255 blue:204.0/255 alpha:1.0].CGColor);
    CGContextSetShadowWithColor(context, CGSizeMake(0, 1), 6,[UIColor grayColor].CGColor);
    CGContextMoveToPoint(context, 0, kVRGCalendarViewTopBarHeight);
    CGContextAddLineToPoint(context, kVRGCalendarViewWidth, kVRGCalendarViewTopBarHeight+1);
    CGContextStrokePath(context);
    
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 0, rect.size.height);
    CGContextAddLineToPoint(context, kVRGCalendarViewWidth, rect.size.height);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
    
    
}

#pragma mark - Draw image for animation
-(UIImage *)drawCurrentState {
    float targetHeight = kVRGCalendarViewTopBarHeight + [self numRows]*(kVRGCalendarViewDayHeight+2)+1;
    
    UIGraphicsBeginImageContext(CGSizeMake(kVRGCalendarViewWidth, targetHeight-kVRGCalendarViewTopBarHeight));
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(c, 0, -kVRGCalendarViewTopBarHeight);    // <-- shift everything up by 40px when drawing.
    [self.layer renderInContext:c];
    UIImage* viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return viewImage;
}

#pragma mark - Init
-(id)init{
    self = [super initWithFrame:CGRectMake(0, 0, kVRGCalendarViewWidth, 0)];
    if (self) {
        self.contentMode = UIViewContentModeTop;
        self.clipsToBounds=YES;
        isAnimating=NO;
        monthSwitchEnable = YES;
        daySelectedEnable = YES;
        self.labelCurrentMonth = [[[UILabel alloc] initWithFrame:CGRectMake(34, 0, kVRGCalendarViewWidth-68, 30)] autorelease];
        [self addSubview:labelCurrentMonth];
        labelCurrentMonth.backgroundColor=[UIColor clearColor];
        //labelCurrentMonth.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15];
        [labelCurrentMonth setFont:[UIFont systemFontOfSize:15]];
        //labelCurrentMonth.textColor = [UIColor colorWithHexString:@"0x383838"];
        labelCurrentMonth.textColor = [UIColor blackColor];
        labelCurrentMonth.textAlignment = UITextAlignmentCenter;
    
        UIView *lineV = [[UIView alloc] initWithFrame:CGRectMake(0, 30, kVRGCalendarViewWidth, 1)];
        [self addSubview:lineV];
        [lineV release];
        lineV.backgroundColor = [UIColor redColor];
        
        UIImageView *leftArrow = [[UIImageView alloc] initWithFrame:CGRectMake(15, 10.5,12.5,10.5)];
        leftArrow.image = [UIImage imageNamed:@"calendar_0.png"];
        [self addSubview:leftArrow];
        [leftArrow release];
        UIButton *leftBt = [UIButton buttonWithType:UIButtonTypeCustom];
        leftBt.frame = CGRectInset(leftArrow.frame, -10, -8);
     
        leftBt.showsTouchWhenHighlighted = YES;
        [self addSubview:leftBt];
        [leftBt addTarget:self action:@selector(showPreviousMonth) forControlEvents:UIControlEventTouchUpInside];
        
        UIImageView *rightArrow = [[UIImageView alloc] initWithFrame:CGRectMake(kVRGCalendarViewWidth - 15 - 12.5, 10.5, 12.5, 10.5)];
        rightArrow.image = [UIImage imageNamed:@"calendar_1.png"];
        [self addSubview:rightArrow];
        [rightArrow release];
        
        UIButton *rightBt = [UIButton buttonWithType:UIButtonTypeCustom];
        rightBt.frame = CGRectInset(rightArrow.frame, -10, -8);
        [self addSubview:rightBt];
        rightBt.showsTouchWhenHighlighted = YES;
        [rightBt addTarget:self action:@selector(showNextMonth) forControlEvents:UIControlEventTouchUpInside];
        
        [self performSelector:@selector(reset) withObject:nil afterDelay:0.1]; //so delegate can be set after init and still get called on init
       // [self reset];
    }
    
    return self;
    
    
}

-(void)dealloc {
    
    self.delegate=nil;
    self.previousMarkedDates = nil;
    self.currentMonth=nil;
    self.nextMarkedDates = nil;
    self.labelCurrentMonth=nil;
    self.animationView_A = nil;
    self.animationView_B = nil;
    
    self.markedDates=nil;
    self.markedColors=nil;
    
    [super dealloc];
}
@end
