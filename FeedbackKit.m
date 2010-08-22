//
//  FeedbackKit.m
//  RealWeather
//
//  Created by Nicolas Giannetta on 8/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FeedbackKit.h"


@implementation FeedbackKit

@synthesize delegate;

/**
 * This is called when new news is detected on the source website
 */
- (void)requestNews:(NSString *)url
{
	stories = [[NSMutableArray alloc] init]; 
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSURLRequest *request = [NSURLRequest requestWithURL:
							 [NSURL URLWithString:url]
											 cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    NSURLResponse *response = [[NSURLResponse alloc] init];
    NSError *error = [[NSError alloc] init];
    NSData *returnedData = [[NSData alloc] init];
	returnedData = [NSURLConnection sendSynchronousRequest:request 
										 returningResponse:&response error:&error];
    if (returnedData == nil) {
        [pool release];
        //return -1;
    }
    else {
        if ([self parseData:returnedData] != nil) {
            [pool release];
            //return -1;
        }
        [pool release];
        //return 0;
    }
}

/**
 *  Parses the retrieved data from the website
 */
- (NSError *)parseData:(NSData *)info {
    BOOL success;
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:info];
    [parser setDelegate:self];
    [parser setShouldResolveExternalEntities:YES];
    success = [parser parse];
    if (success == NO) {
        return [parser parserError];
    }
    //[parser release];
    return nil;
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
	//NSLog(@"found file and started parsing"); 
} 

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	[[self delegate] didFailToReceiveNews:parseError];
} 

- (void)parser:(NSXMLParser *)parser 
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName 
	attributes:(NSDictionary *)attributeDict{ 
	//NSLog(@"found this element: %@", elementName); 
	currentElement = [elementName copy];
	if ([elementName isEqualToString:@"item"]) { 
		// clear out our story item caches... 
		item = [[NSMutableDictionary alloc] init];
		currentTitle = [[NSMutableString alloc] init];
		currentDate = [[NSMutableString alloc] init];
		currentSummary = [[NSMutableString alloc] init];
		currentLink = [[NSMutableString alloc] init];
	}
} 
- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName{
	//NSLog(@"ended element: %@", elementName);
	if ([elementName isEqualToString:@"item"]) { 
		// save values to an item, then store that item into the array... 
		[item setObject:currentTitle forKey:@"title"];
		[item setObject:currentLink forKey:@"link"];
		[item setObject:currentSummary forKey:@"summary"];
		[item setObject:currentDate forKey:@"date"];
		[stories addObject:[item copy]];
		//NSLog(@"adding story: %@", currentTitle);
	}
} 
- (void)parser:(NSXMLParser *)parser 
foundCharacters:(NSString *)string{ 
	//NSLog(@"found characters: %@", string);
	// save the characters for the current item... 
	if ([currentElement isEqualToString:@"title"]) { 
		[currentTitle appendString:string];
	} else if ([currentElement isEqualToString:@"link"]) {
		[currentLink appendString:string]; 
	} else if ([currentElement isEqualToString:@"description"]) { 
		[currentSummary appendString:string]; 
	} else if ([currentElement isEqualToString:@"pubDate"]) { 
		[currentDate appendString:string]; 
	}
} 

- (NSDate *)dateFromString:(NSString *)dateString {
	//NSString *dateString = @"Mon, 03 May 2010 18:54:26 +00:00";
	
	NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
	[df setDateFormat:@"EEE, dd MMMM yyyy HH:mm:ss Z"];
	
	// set locale to something English 
	NSLocale *enLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en"] autorelease];
	[df setLocale:enLocale];
	
	NSDate *date = [df dateFromString:dateString];
	
	//NSLog(@"'%@' = %@", dateString, date);
	return date;
}

/**
 * Parsing is finished here so this is when the delegate gets called
 */
- (void)parserDidEndDocument:(NSXMLParser *)parser {
	//NSLog(@"stories array has %d items", [stories count]);
	
	NSMutableDictionary *storyDictionary = [stories objectAtIndex:0];
	
	NSMutableString *newDateString = [storyDictionary objectForKey:@"date"];
	NSMutableString *newsDescription = [[NSMutableString alloc] initWithString:[storyDictionary objectForKey:@"summary"]];
	NSMutableString *newsTitle = [[NSMutableString alloc] initWithString:[storyDictionary objectForKey:@"title"]];
	// We remove unnecessary whitespace and newline
	newsDescription = (NSMutableString *)[newsDescription stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	newsTitle = (NSMutableString *)[newsTitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	newDateString = (NSMutableString *)[newDateString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	NSDate *newDate = [self dateFromString:newDateString];
	NSDate *oldDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"pubDate"];
	
	if ([newDate compare:oldDate] == NSOrderedDescending) {
		[[self delegate] didReceiveNews:newsDescription withTitle:newsTitle];
		[[NSUserDefaults standardUserDefaults] setObject:newDate forKey: @"pubDate"];
	}
	else if (oldDate == nil) {
		//NSLog(@"No old stories");
		[[NSUserDefaults standardUserDefaults] setObject:newDate forKey: @"pubDate"];
	}
	
	//NSLog(@"all done!");
}

@end
