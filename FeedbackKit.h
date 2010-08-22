//
//  FeedbackKit.h
//  RealWeather
//
//  Created by Nicolas Giannetta on 8/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FeedbackKitDelegate <NSObject>
@required
- (void) didReceiveNews: (NSString *)description withTitle: (NSString *)title;
- (void) didFailToReceiveNews: (NSError *)error;
@end

@interface FeedbackKit : NSObject <NSXMLParserDelegate> {
	id <FeedbackKitDelegate> delegate;
	
	@private
	NSString *currentElement;
	NSMutableArray *stories;
	NSMutableDictionary *item;
	NSMutableString *currentTitle;
	NSMutableString *currentDate;
	NSMutableString *currentSummary;
	NSMutableString *currentLink;
}

@property (retain) id delegate;

-(void)requestNews: (NSString *)url;
//@private make this a private function
-(NSError *)parseData:(NSData *)info;
-(NSDate *)dateFromString:(NSString *)dateString;

@end
