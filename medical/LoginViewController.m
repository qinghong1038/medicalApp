//
//  ViewController.m
//  medical
//
//  Created by Matt LaDuca on 2/11/12.
//  Copyright (c) 2012  PPA. All rights reserved.
//

#import "LoginViewController.h"
#import "OfficeViewController.h"

@interface LoginViewController()

@property (nonatomic, strong) UITextField *usernameField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UISegmentedControl *userIDPass;
@property (nonatomic, strong) UIStoryboardSegue *segue;

- (UITextField *)newUsernameTextField;
- (UITextField *)newPasswordTextField;
- (UIBarButtonItem *)userIDPassBarButton;
- (void)setLogOnButtonProperties;
- (NSArray *)keyboardToolbarItems;
- (void)tryLogOn;
- (UITextField *)tableCellTextField;
- (void)showAlertViewWithMessage:(NSString *)message;
- (BOOL)emptyUsernameOrPassword;
- (void) contactServer;

@end

@implementation LoginViewController

@synthesize tableView = _tableView;
@synthesize keyboardToolbar = _keyboardToolbar;
@synthesize logOnButton = _logOnButton;
@synthesize loadingView = _loadingView;
@synthesize usernameField = _usernameField;
@synthesize passwordField = _passwordField;
@synthesize userIDPass = _userIDPass;
@synthesize segue = _segue;

#pragma mark - View lifecycle


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.usernameField = [self newUsernameTextField];
    self.passwordField = [self newPasswordTextField];
    self.keyboardToolbar.items = [self keyboardToolbarItems];  
    [self setLogOnButtonProperties];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [self setKeyboardToolbar:nil];
    [self setLogOnButton:nil];
    [self setLoadingView:nil];
    [super viewDidUnload];
}

#pragma mark -

- (IBAction)logOnPressed:(id)sender 
{
    [self tryLogOn];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self tryLogOn];
    return YES;
}


- (void)tryLogOn
{
    if ([self emptyUsernameOrPassword]) {
        [self showAlertViewWithMessage:@"Please enter a User ID and Password to continue"];
        return;
    }
    
    
    [self.view addSubview:self.loadingView];
    self.loadingView.backgroundColor = [UIColor clearColor];
    self.loadingView.center = self.view.center;
    
    [self contactServer];
}


#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
#define kLadookieURL [NSURL URLWithString: @"http://www.ladookie4343.com/MedicalApp/doctorlogin.php"]

- (void)contactServer
{
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:kLadookieURL];
    [request setHTTPMethod:@"POST"];
    
    NSString *username = self.usernameField.text;
    NSString *password = self.passwordField.text;
    NSString *requestData = [NSString stringWithFormat:@"username=%@&password=%@", username, password];
    [request setHTTPBody:[requestData dataUsingEncoding:NSUTF8StringEncoding]]; 
    
    
    dispatch_async(kBgQueue, ^{ 
        NSURLResponse *response;
        NSError *error;
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request 
                                                     returningResponse:&response 
                                                                 error:&error];
        [self performSelectorOnMainThread:@selector(responseFromLoginScript:) 
                               withObject:responseData 
                            waitUntilDone:YES];
    });
     
}

- (void)responseFromLoginScript:(NSData *)data
{
    [self.loadingView removeFromSuperview];
    
    NSString *success = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if ([success isEqualToString:@"yes"]) {
        [self showAlertViewWithMessage:@"good credentials"];
    } else {
        [self showAlertViewWithMessage:@"The User ID or Password you entered is incorrect. "
         "Please click 'OK' to reenter your User ID and password"];
    } 
}

- (BOOL)emptyUsernameOrPassword
{
    return [@"" isEqualToString:self.usernameField.text] ||
           [@"" isEqualToString:self.passwordField.text] ||
           self.usernameField.text == nil ||
           self.passwordField.text == nil;
}

- (void)showAlertViewWithMessage:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil 
                                                    message:message
                                                   delegate:nil 
                                          cancelButtonTitle:@"OK" 
                                          otherButtonTitles:nil];
    [alert show];   
}

/*
- (void)fetchData:(NSData *)responseData
{
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData 
                                                         options:kNilOptions 
                                                           error:&error];
    NSString *firstname = [json objectForKey:@"firstname"];
    NSString *type = [json objectForKey:@"type"];
    NSString *experience = [json objectForKey:@"years_experience"];
    
    NSLog(@"%@, %@, %@", firstname, type, experience);
    NSLog(@"%@", json);
}
 */
#pragma mark


#pragma mark Tableview datasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                                   reuseIdentifier:nil];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 10.0, 100, 20)];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:15];
    [cell.contentView addSubview:label];
    if (indexPath.row == 0) {
        label.text = @"User ID";
        [cell addSubview:self.usernameField];
    } else {
        label.text = @"Password";
        [cell.contentView addSubview:self.passwordField];
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

#pragma mark - textfield accessory view methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField == self.usernameField) {
        self.userIDPass.selectedSegmentIndex = 0;
    } else {
        self.userIDPass.selectedSegmentIndex = 1;
    }
    textField.inputAccessoryView = self.keyboardToolbar;
}

- (void)userIDPassPressed:(UISegmentedControl *)sender
{
    if (sender.selectedSegmentIndex == 0) {
        [self.usernameField becomeFirstResponder];
    } else {
        [self.passwordField becomeFirstResponder];
    }
}

- (void)closeKeyboard
{
    if ([self.usernameField isEditing]) {
        [self.usernameField resignFirstResponder];
    } else {
        [self.passwordField resignFirstResponder];
    }
}


#pragma mark - helper methods

- (UITextField *)tableCellTextField
{
    UITextField *textField = [[UITextField alloc] init];
    textField.font = [UIFont boldSystemFontOfSize:14];
    textField.delegate = self;
    textField.returnKeyType = UIReturnKeyGo;
    textField.clearsOnBeginEditing = NO;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.enabled = YES;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    return textField;
}

- (UITextField *)newUsernameTextField
{
    UITextField *textField = [self tableCellTextField];
    textField.frame = CGRectMake(105.0, 5.0, 202.0, 35.0);
    textField.placeholder = @"Enter your User ID";
    textField.secureTextEntry = NO;
    return textField;
}

- (UITextField *)newPasswordTextField
{
    UITextField *textField = [self tableCellTextField];
    textField.frame = CGRectMake(95.0, 5.0, 204.0, 35.0);
    textField.placeholder = @"Enter your Password";
    textField.secureTextEntry = YES;
    return textField;
}

- (void)setLogOnButtonProperties
{
    self.logOnButton.frame = CGRectMake(10, 250, 300, 38);
    [self.logOnButton setTitle:@"Log On" forState:UIControlStateNormal];
    UIImage *buttonImage = [[UIImage imageNamed:@"green_button.png"] resizableImageWithCapInsets:
                            UIEdgeInsetsMake(0, 11, 0, 11)];
    [self.logOnButton addTarget:self action:(@selector(logOnPressed:)) forControlEvents:UIControlEventTouchUpInside];
    [self.logOnButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
}

- (NSArray *)keyboardToolbarItems
{
    UIBarButtonItem *userIDPassButton =  [self userIDPassBarButton];    
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] 
                             initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace 
                                                  target:nil 
                                                  action:nil];
    flex.width = 105;
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Done" 
                                                             style:UIBarButtonItemStyleBordered 
                                                            target:self 
                                                            action:@selector(closeKeyboard)];
    done.tintColor = [UIColor colorWithWhite:0.25 alpha:1];
    return [[NSArray alloc] initWithObjects: userIDPassButton, flex, done, nil];
}

- (UIBarButtonItem *)userIDPassBarButton
{
    self.userIDPass = [[UISegmentedControl alloc] initWithItems:
                                    [[NSArray alloc] initWithObjects:@"User ID", @"Password", nil]];
    self.userIDPass.segmentedControlStyle = UISegmentedControlStyleBar;
    [self.userIDPass addTarget:self 
                        action:@selector(userIDPassPressed:) 
              forControlEvents:UIControlEventValueChanged];
    self.userIDPass.tintColor = [UIColor colorWithWhite:0.25 alpha:1];
    return [[UIBarButtonItem alloc] initWithCustomView:self.userIDPass];
}


@end











