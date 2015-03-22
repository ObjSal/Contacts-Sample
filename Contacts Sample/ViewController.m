//
//  ViewController.m
//  Contacts Sample
//
//  Created by Salvador Guerrero on 12/18/14.
//  Copyright (c) 2014 ByteApps. All rights reserved.
//

#import "ViewController.h"
#import <AddressBook/ABAddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    //Requesting permission to access address book
    {
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);

        __block BOOL accessGranted = NO;

        if (ABAddressBookRequestAccessWithCompletion != NULL) { // We are on iOS 6
            //dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

            ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                accessGranted = granted;
                //dispatch_semaphore_signal(semaphore);

                [self getContactsWithAddressBook:addressBook];
            });

            //dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            //dispatch_release(semaphore);
        }

        else { // We are on iOS 5 or Older
            accessGranted = YES;
            [self getContactsWithAddressBook:addressBook];
        }

        if (accessGranted) {
            [self getContactsWithAddressBook:addressBook];
        }
    }
}

- (void)getContactsWithAddressBook:(ABAddressBookRef )addressBook {

    NSMutableArray *contactList = [[NSMutableArray alloc] init];
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex nPeople = ABAddressBookGetPersonCount(addressBook);

    for (int i=0;i < nPeople;i++) {
        NSMutableDictionary *dOfPerson=[NSMutableDictionary dictionary];

        ABRecordRef ref = CFArrayGetValueAtIndex(allPeople,i);

        //For username and surname
        ABMultiValueRef phones =(__bridge ABMultiValueRef)((__bridge NSString*)ABRecordCopyValue(ref, kABPersonPhoneProperty));

        CFStringRef firstName, lastName, middleName;
        firstName = ABRecordCopyValue(ref, kABPersonFirstNameProperty);
        lastName  = ABRecordCopyValue(ref, kABPersonLastNameProperty);
        middleName = ABRecordCopyValue(ref, kABPersonMiddleNameProperty);
        [dOfPerson setObject:[NSString stringWithFormat:@"%@ %@, %@", firstName, middleName, lastName] forKey:@"name"];

        CFStringRef org, jobTitle, department;

        org = ABRecordCopyValue(ref, kABPersonOrganizationProperty);
        jobTitle  = ABRecordCopyValue(ref, kABPersonJobTitleProperty);
        department = ABRecordCopyValue(ref, kABPersonDepartmentProperty);

        [dOfPerson setObject:[NSString stringWithFormat:@"%@", org] forKey:@"organization"];
        [dOfPerson setObject:[NSString stringWithFormat:@"%@", jobTitle] forKey:@"jobTitle"];
        [dOfPerson setObject:[NSString stringWithFormat:@"%@", department] forKey:@"department"];

        CFStringRef creationDate, modificationDate;
        creationDate = ABRecordCopyValue(ref, kABPersonCreationDateProperty);
        modificationDate  = ABRecordCopyValue(ref, kABPersonModificationDateProperty);

        [dOfPerson setObject:[NSString stringWithFormat:@"%@", creationDate] forKey:@"creationDate"];
        [dOfPerson setObject:[NSString stringWithFormat:@"%@", modificationDate] forKey:@"modificationDate"];

        //AB_EXTERN const ABPropertyID kABPersonSocialProfileProperty __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_5_0);
        {
            CFStringRef socialProfile = ABRecordCopyValue(ref, kABPersonSocialProfileProperty);

            for(CFIndex i = 0; i < ABMultiValueGetCount(socialProfile); i++)
            {
                NSString *socialLabel = (__bridge NSString*)ABMultiValueCopyLabelAtIndex(socialProfile, i);

                [dOfPerson setObject:[NSString stringWithFormat:@"%@", (__bridge NSString*)ABMultiValueCopyValueAtIndex(socialProfile, i)] forKey:[NSString stringWithFormat:@"social_%@[%ld]", socialLabel, i]];
            }
        }

        //AB_EXTERN const ABPropertyID kABPersonInstantMessageProperty;     // Instant Messaging - kABMultiDictionaryPropertyType
        {
            CFStringRef instantMessaging = ABRecordCopyValue(ref, kABPersonInstantMessageProperty);

            for(CFIndex i = 0; i < ABMultiValueGetCount(instantMessaging); i++)
            {
                NSString *imLabel = (__bridge NSString*)ABMultiValueCopyLabelAtIndex(instantMessaging, i);

                [dOfPerson setObject:[NSString stringWithFormat:@"%@", (__bridge NSString*)ABMultiValueCopyValueAtIndex(instantMessaging, i)] forKey:[NSString stringWithFormat:@"instantMessaging_%@[%ld]", imLabel, i]];
            }
        }

        

        //For Email ids
        ABMutableMultiValueRef eMail  = ABRecordCopyValue(ref, kABPersonEmailProperty);
        if(ABMultiValueGetCount(eMail) > 0) {
            [dOfPerson setObject:(__bridge NSString *)ABMultiValueCopyValueAtIndex(eMail, 0) forKey:@"email"];

        }

        //For Phone number
        NSString* mobileLabel;

        for(CFIndex i = 0; i < ABMultiValueGetCount(phones); i++) {
            mobileLabel = (__bridge NSString*)ABMultiValueCopyLabelAtIndex(phones, i);
            if([mobileLabel isEqualToString:(NSString *)kABPersonPhoneMobileLabel])
            {
                [dOfPerson setObject:(__bridge NSString*)ABMultiValueCopyValueAtIndex(phones, i) forKey:@"Phone"];
            }
            else if ([mobileLabel isEqualToString:(NSString*)kABPersonPhoneIPhoneLabel])
            {
                [dOfPerson setObject:(__bridge NSString*)ABMultiValueCopyValueAtIndex(phones, i) forKey:@"Phone"];
                break ;
            }

        }
        [contactList addObject:dOfPerson];
        
    }
    NSLog(@"Contacts = %@",contactList);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
