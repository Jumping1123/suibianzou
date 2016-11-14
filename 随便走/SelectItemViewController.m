//
//  SelectItemViewController.m
//  随便走
//
//  Created by zn on 2016/11/11.
//  Copyright © 2016年 ZN. All rights reserved.
//

#import "SelectItemViewController.h"

@interface SelectItemViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *keywordTextField;

@end

@implementation SelectItemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.keywordTextField.delegate = self;
    [self.keywordTextField becomeFirstResponder];
}

- (IBAction)selectedBtnClick:(UIButton *)sender {
    
    NSString *tag = [NSString stringWithFormat:@"%ld",(long)sender.tag];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Keywords.plist" ofType:nil];
    NSDictionary *keyDict = [NSDictionary dictionaryWithContentsOfFile:filePath];
    
    NSString *keyword = [keyDict objectForKey:tag];
    
    [self sendKeyword:keyword];
}

- (IBAction)cancelBtnClick:(UIButton *)sender {
    
    [self dismissViewControllerAnimated:TRUE completion:nil];
}

- (void)sendKeyword:(NSString *)keyword
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"setKeywordNotification" object:nil userInfo:@{@"keyword" : keyword}];
    [self dismissViewControllerAnimated:TRUE completion:nil];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self sendKeyword:textField.text];
    return YES;
}
@end
