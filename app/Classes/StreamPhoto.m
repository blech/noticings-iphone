//
//  StreamPhoto.m
//  Noticings
//
//  Created by Tom Insam on 05/07/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "StreamPhoto.h"
#import "JSONKit.h"

#import "APIKeys.h"
#import "NoticingsAppDelegate.h"

@implementation StreamPhoto

// core data magic
@dynamic flickrId, title, json, lastupdate, dateupload, needsFetch;
@dynamic isfavorite, comments, fullInfo;


@synthesize details;

+ (id)photoWithFlickrId:(NSString*)flickrId;
{
    NSManagedObjectContext *context = [NoticingsAppDelegate delegate].managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:context];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = entity;
    request.predicate = [NSPredicate predicateWithFormat:@"flickrId = %@", flickrId];
    NSError *error = nil;
    StreamPhoto *photo = [[context executeFetchRequest:request error:&error] lastObject];
    if (error) {
        DLog(@"error looking up object %@: %@", flickrId, error);
        abort();
    }
    if (photo != nil) {
        photo.details = [photo.json objectFromJSONData];
    }
    return photo;
}

+ (id)photoWithDictionary:(NSDictionary*)dict;
{
    StreamPhoto *photo = [self photoWithFlickrId:[dict objectForKey:@"id"]];
    if (photo == nil) {
        NSManagedObjectContext *context = [NoticingsAppDelegate delegate].managedObjectContext;
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:context];
        photo = [[StreamPhoto alloc] initWithEntity:entity insertIntoManagedObjectContext:context];;
    }
    [photo updateFromDict:dict];
    return photo;
}

+ (NSArray*)photosWithPredicate:(NSPredicate*)predicate;
{
    NSManagedObjectContext *context = [NoticingsAppDelegate delegate].managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = entity;
    request.predicate = predicate;
    // mose recently uploaded photos fetched first.
    request.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"dateupload" ascending:NO] ];
    NSError *error = nil;
    NSEnumerator *photos = [[context executeFetchRequest:request error:&error] objectEnumerator];
    return [photos allObjects];
}

- (void)updateFromDict:(NSDictionary*)dict;
{
    //DLog(@"details are %@", dict);
    self.details = dict;

    // update core data properties
    self.flickrId = [dict objectForKey:@"id"];
    self.json = [dict JSONData];
    self.dateupload = [NSNumber numberWithInt:[[dict objectForKey:@"dateupload"] intValue]];

    // the dict lastupdate is when flickr was last updated. ours is when we last fetched the
    // full photo information from flickr
    NSNumber *lastupdate = [NSNumber numberWithInt:[[dict objectForKey:@"lastupdate"] intValue]];
    if (self.lastupdate != nil && [self.lastupdate isEqualToNumber:lastupdate]) {
        self.needsFetch = [NSNumber numberWithBool:NO];
    } else {
        self.needsFetch = [NSNumber numberWithBool:YES];
    }
}

-(void)updateFromPhotoInfo:(NSDictionary*)info;
{
    //DLog(@"got full photo info %@", info);
    self.fullInfo = [info JSONData];
    
    // info here is a response from flickr.photos.getInfo. more details.
    self.comments = @([[[info objectForKey:@"comments"] objectForKey:@"_content"] boolValue]);
    self.isfavorite = @([[info objectForKey:@"isfavorite"] boolValue]);
    self.lastupdate = @([[[info objectForKey:@"dates"] objectForKey:@"lastupdate"] intValue]);
    self.needsFetch = [NSNumber numberWithBool:NO];
}

-(NSString*)description;
{
    // this is the objective C introspection / toString() method
    return [NSString stringWithFormat:@"<%@ \"%@\" by %@>", self.class, self.title, self.ownername];
}




#pragma mark accessors / view utilities

- (NSString*)title;
{
    NSString *title = [[self.details valueForKeyPath:@"title"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (title.length > 0) {
        return title;
    }
    return @"Untitled";
}

-(BOOL)hasTitle;
{
    NSString *title = [[self.details valueForKeyPath:@"title"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return (title.length > 0);
}

- (NSString*)html;
{
    NSString *raw = [self.details valueForKeyPath:@"description._content"];
    return [raw stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
}

- (NSString*)ownername;
{
    return [self.details valueForKeyPath:@"ownername"];
}

- (NSString*)ownerId;
{
    return [self.details valueForKeyPath:@"owner"];
}

-(float)latitude;
{
    return [[self.details valueForKey:@"latitude"] floatValue];
}

-(float)longitude;
{
    return [[self.details valueForKey:@"longitude"] floatValue];
}

-(BOOL)hasLocation;
{
    float lat = [[self.details valueForKey:@"latitude"] floatValue];
    float lng = [[self.details valueForKey:@"longitude"] floatValue];
    return (lat != 0 && lng != 0);
}

- (NSString*)placename;
{
    return [NSString stringWithFormat:@"%.3f,%.3f", self.latitude, self.longitude];
}

- (NSString*)woeid;
{
    return [self.details valueForKey:@"woeid"];
}

- (NSURL*) mapPageURL;
{
    NSString *title = [self.title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if (title.length == 0) {
        title = @"Photo"; // google maps needs something
    }
    NSString *mapURL = [NSString stringWithFormat:@"http://maps.google.com/maps?q=%f,%f+(%@)", self.latitude, self.longitude, title];
    return [NSURL URLWithString:mapURL];
}

-(NSURL*)mapImageURL;
{
    int scale = [UIScreen mainScreen].scale; //  1 or 2
    NSString *mapURL = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/staticmap?sensor=false&size=320x70&center=%f,%f&zoom=12&scale=%d&markers=size:small%%7C%f,%f",
                        self.latitude, self.longitude, scale, self.latitude, self.longitude];
    return [NSURL URLWithString:mapURL];
}

- (NSURL*) imageURL;
{
    return [NSURL URLWithString:(self.details)[@"url_m"]];
}

- (NSURL*) bigImageURL;
{
    NSString *big = (self.details)[@"url_b"];
    if (!big) {
        big = (self.details)[@"url_m"];
    }
    return [NSURL URLWithString:big];
}

- (NSURL*) originalImageURL;
{
    if ([self.details valueForKey:@"url_o"]) {
        return [NSURL URLWithString:[self.details valueForKey:@"url_o"]];
    } else {
        return self.bigImageURL;
    }
}

- (NSURL*) avatarURL;
{
    NSString *avatarUrl;
    if ((self.details)[@"iconserver"] && ![(self.details)[@"iconserver"] isEqual:@"0"]) {
        avatarUrl = [NSString stringWithFormat:@"http://farm%@.static.flickr.com/%@/buddyicons/%@.jpg",
                     (self.details)[@"iconfarm"],
                     (self.details)[@"iconserver"],
                     (self.details)[@"owner"]
                     ];
        
    } else {
        avatarUrl = @"http://www.flickr.com/images/buddyicon.jpg";
    }
    return [NSURL URLWithString:avatarUrl];
}

- (NSURL*) pageURL;
{
    NSString *urlString = [NSString stringWithFormat:@"http://www.flickr.com/photos/%@/%@",
                           (self.details)[@"pathalias"],
                           (self.details)[@"id"]
                           ];
    return [NSURL URLWithString:urlString];
}

- (NSURL *)mobilePageURL;
{
    NSString *urlString = [NSString stringWithFormat:@"http://m.flickr.com/photos/%@/%@",
                           (self.details)[@"pathalias"],
                           (self.details)[@"id"]
                           ];
    return [NSURL URLWithString:urlString];
}

- (NSString*) ago;
{
    NSTimeInterval epoch = [[NSDate date] timeIntervalSinceReferenceDate] + NSTimeIntervalSince1970; // yeah.
    NSString *uploaded = [self.dateupload stringValue];
    if (!uploaded) {
        return @"";
    }
    int ago = epoch - [uploaded doubleValue]; // woooo overflow bug. I hope your friends upload at least once every 2*32 seconds!
    

    if (ago < 0) {
        return @"now"; // clock drift for new uploads can make this -ve
    }

    int seconds = ago % 60;
    int minutes = (ago / 60) % 60;
    int hours = (ago / (60*60)) % 24;
    int days = (ago / (24*60*60));
    
    if (days > 1) {
        return [NSString stringWithFormat:@"%dd", days];
    }
    if (hours > 1) {
        return [NSString stringWithFormat:@"%dh", hours + days*24];
    }
    if (minutes > 1) {
        return [NSString stringWithFormat:@"%dm", minutes + hours*60];
    }
    return [NSString stringWithFormat:@"%ds", seconds + minutes*60];
}

-(int)visibility;
{
    if ([(self.details)[@"ispublic"] intValue]) {
        return StreamPhotoVisibilityPublic;
    }
    if ([(self.details)[@"isfriend"] intValue] || [(self.details)[@"isfamily"] intValue]) {
        return StreamPhotoVisibilityLimited;
    }
    return StreamPhotoVisibilityPrivate;
}

-(NSArray*)tags;
{
    NSString *tags = [self.details valueForKey:@"tags"];
    if (tags.length > 0) {
        return [tags componentsSeparatedByString:@" "];
    }
    return @[];
}

-(NSArray*)humanTags;
{
    NSPredicate *human = [NSPredicate predicateWithBlock:^(id tag, NSDictionary *bindings) {
        NSRange range = [((NSString*)tag) rangeOfString:@":"];
        if (range.length > 0) {
            return NO;
        }
        return YES;
    }];
    return [self.tags filteredArrayUsingPredicate:human];
}



-(CGFloat)imageHeightForWidth:(CGFloat)width;
{
    float width_m = [(self.details)[@"width_m"] floatValue];
    float height_m = [(self.details)[@"height_m"] floatValue];
    CGFloat height = width * height_m / width_m;
    return height;
}


#pragma mark MKAnnotation

-(CLLocationCoordinate2D)coordinate;
{
    CLLocationCoordinate2D location;
    location.latitude = self.latitude;
    location.longitude = self.longitude;
    return location;
}

- (NSString*)subtitle;
{
    return self.ownername;
}


@end
