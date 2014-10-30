//
//  VRGCalendarView.h
//  Vurig
//
//  Created by in 't Veen Tjeerd on 5/8/12.
//  Copyright (c) 2012 Vurig Media. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "UIColor+expanded.h"

#define kVRGCalendarViewTopBarHeight 50
#define kVRGCalendarViewWidth 320

#define kVRGCalendarViewDayWidth 44
#define kVRGCalendarViewDayHeight 55

@protocol VRGCalendarViewDelegate;
@interface VRGCalendarView : UIView{
    id <VRGCalendarViewDelegate> delegate;
    NSDate *currentMonth;
    
    UILabel *labelCurrentMonth;
    
    BOOL isAnimating;
    BOOL prepAnimationPreviousMonth;
    BOOL prepAnimationNextMonth;
    
    UIImageView *animationView_A;
    UIImageView *animationView_B;
    NSArray *previousMarkedDates;
    NSArray *markedDates;
    NSArray *nextMarkedDates;
    NSArray *markedColors;
    BOOL monthSwitchEnable;
    BOOL daySelectedEnable;
    
}

@property (nonatomic, assign) BOOL monthSwitchEnable,daySelectedEnable;
@property (nonatomic, assign) id <VRGCalendarViewDelegate> delegate;
@property (nonatomic, retain) NSDate *currentMonth;
@property (nonatomic, retain) UILabel *labelCurrentMonth;
@property (nonatomic, retain) UIImageView *animationView_A;
@property (nonatomic, retain) UIImageView *animationView_B;
@property (nonatomic, retain) NSArray *previousMarkedDates;

@property (nonatomic, retain) NSArray *markedDates;
@property (nonatomic, retain) NSArray *nextMarkedDates;
@property (nonatomic, retain) NSArray *markedColors;
@property (nonatomic, getter = calendarHeight) float calendarHeight;
@property (nonatomic, retain, getter = selectedDate) NSDate *selectedDate;

-(void)selectDate:(int)date;
-(void)reset;

-(void)markDates:(NSArray *)dates;
-(void)markDates:(NSArray *)dates withColors:(NSArray *)colors;

-(void)showNextMonth;
-(void)showPreviousMonth;

-(int)numRows;
-(void)updateSize;
-(UIImage *)drawCurrentState;

@end

@protocol VRGCalendarViewDelegate <NSObject>

-(void)calendarView:(VRGCalendarView *)calendarView switchedToMonth:(NSDate *)month targetHeight:(float)targetHeight animated:(BOOL)animated;
-(void)calendarView:(VRGCalendarView *)calendarView dateSelected:(NSDate *)date;
-(void)calendarView:(VRGCalendarView *)v SwithchEndedWithDirect:(NSInteger)dir;
@end
