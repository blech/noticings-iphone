//
//  StreamViewController.h
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PullRefreshTableViewController.h"
#import "UploadQueueManager.h"

@interface StreamViewController : PullRefreshTableViewController {
    UIBarButtonItem *queueButton;
    UploadQueueManager *uploadQueueManager;
}

@end
