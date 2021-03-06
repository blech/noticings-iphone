//
//  MoreViewController.m
//  Noticings
//
//  Created by Tom Taylor on 31/10/2009.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MoreViewController.h"
#import "FlickrAuthenticationViewController.h"
#import "DebugViewController.h"
#import "StreamViewController.h"
#import "StarredStreamManager.h"

enum Sections {
	kNoticingsSection = 0,
	kFlickrSection,
	kAppSection,
	NUM_SECTIONS
};

enum NoticingsSectionRows {
	kNoticingsSectionSiteRow = 0,
	kNoticingsSectionDebugRow,
	kNoticingsSectionStarredRow,
	NUM_NOTICINGS_SECTION_ROWS
};

enum FlickrSectionRows {
	kFlickrSectionSiteRow = 0,
	NUM_FLICKR_SECTION_ROWS
};

enum AppSectionRows {
	kAppSectionSignoutRow = 0,
	NUM_APP_SECTION_ROWS
};


@implementation MoreViewController

- (void)viewDidLoad {
    if (!self.cameraController) {
        self.cameraController = [[CameraController alloc] initWithBaseViewController:self];
    }
    [super viewDidLoad];
}

- (void)viewDidUnload {
    self.cameraController = nil;
    [super viewDidUnload];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return NUM_SECTIONS;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
		case kNoticingsSection:
			return NUM_NOTICINGS_SECTION_ROWS;
		case kFlickrSection:
			return NUM_FLICKR_SECTION_ROWS;
		case kAppSection:
			return NUM_APP_SECTION_ROWS;
		default:
			return 0;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
	
	if (indexPath.section == kNoticingsSection) {
		switch (indexPath.row) {
			case kNoticingsSectionSiteRow:
				cell.textLabel.text = @"Upload from Camera Roll";
				break;
			case kNoticingsSectionDebugRow:
				cell.textLabel.text = @"Debug";
				break;
			case kNoticingsSectionStarredRow:
				cell.textLabel.text = @"Your favourites";
				break;
			default:
				break;
		}
	} else if (indexPath.section == kFlickrSection) {
		cell.textLabel.text = @"Open flickr.com";
	} else {
		cell.textLabel.text = @"Sign out";
	}
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == kNoticingsSection) {
		switch (indexPath.row) {
			case kNoticingsSectionSiteRow:
				[self.cameraController presentImagePicker];
				break;
			case kNoticingsSectionDebugRow:
                [self.navigationController pushViewController:[[DebugViewController alloc] initWithStyle:UITableViewStyleGrouped] animated:YES];
				break;
            case kNoticingsSectionStarredRow: {
                StarredStreamManager *manager = [[StarredStreamManager alloc] init];
                StreamViewController *vc = [[StreamViewController alloc] initWithPhotoStreamManager:manager];
                [self.navigationController pushViewController:vc animated:YES];
                break;
            }
			default:
				break;
		}
	} else if (indexPath.section == kFlickrSection) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://m.flickr.com"]];
	} else {
		[[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"oauth_token"];
		[[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"oauth_secret"];
        [[NSUserDefaults standardUserDefaults] synchronize];
		FlickrAuthenticationViewController *authViewController = [[FlickrAuthenticationViewController alloc] init];
		[authViewController displaySignIn];
		[self presentModalViewController:authViewController animated:YES];
	}

}



@end

