//
//  CYDataInputSourceTests.m
//  BRCybertron
//
//  Created by Matt on 6/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import <XCTest/XCTest.h>

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>
#import <libxml/parser.h>
#import "CYDataInputSource.h"
#import "CYSimpleEntityResolver.h"

@interface CYDataInputSourceTests : XCTestCase

@end

@implementation CYDataInputSourceTests

- (void)tearDown {
	[[CYSimpleEntityResolver sharedResolver] setInternalEntities:nil];
	[super tearDown];
}

- (void)testParseSimple {
	NSData *data = [@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><section><p>Hello, world.</p></section>" dataUsingEncoding:NSUTF8StringEncoding];
	CYDataInputSource *input = [[CYDataInputSource alloc] initWithData:data options:0];
	
	NSError *error = nil;
	xmlDocPtr doc = [input getDocument:&error];
	XCTAssertTrue(doc != NULL);
	XCTAssertNil(error);
}

- (void)testParseSimpleNoEncoding {
	NSData *data = [@"<section><p>Hello, world.</p></section>" dataUsingEncoding:NSUTF8StringEncoding];
	CYDataInputSource *input = [[CYDataInputSource alloc] initWithData:data options:0];
	
	NSError *error = nil;
	xmlDocPtr doc = [input getDocument:&error];
	XCTAssertTrue(doc != NULL);
	XCTAssertNil(error);
}

- (void)testToStringSimpleNoFormat {
	NSData *data = [@"<section><p>Hello, world.</p></section>" dataUsingEncoding:NSUTF8StringEncoding];
	CYDataInputSource *input = [[CYDataInputSource alloc] initWithData:data options:0];
	
	NSError *error = nil;
	NSString *result = [input asString:NO error:&error];
	XCTAssertNil(error);
	XCTAssertEqualObjects(@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<section><p>Hello, world.</p></section>\n", result);
}

- (void)testToStringSimpleFormat {
	NSData *data = [@"<section><p>Hello, world.</p></section>" dataUsingEncoding:NSUTF8StringEncoding];
	CYDataInputSource *input = [[CYDataInputSource alloc] initWithData:data options:0];
	
	NSError *error = nil;
	NSString *result = [input asString:YES error:&error];
	XCTAssertNil(error);
	XCTAssertEqualObjects(@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<section>\n  <p>Hello, world.</p>\n</section>\n", result);
}

- (void)testParseMalformedXML {
	NSData *data = [@"<section><p>Hello, world.</section>" dataUsingEncoding:NSUTF8StringEncoding];
	CYDataInputSource *input = [[CYDataInputSource alloc] initWithData:data options:0];
	
	NSError *error = nil;
	xmlDocPtr doc = [input getDocument:&error];
	XCTAssertTrue(doc == NULL);
	XCTAssertNotNil(error);
}

- (void)testParseWithUnknownEntity {
	NSData *data = [@"<section><p>&emsp;</p></section>" dataUsingEncoding:NSUTF8StringEncoding];
	CYDataInputSource *input = [[CYDataInputSource alloc] initWithData:data options:0];
	
	NSError *error = nil;
	xmlDocPtr doc = [input getDocument:&error];
	XCTAssertTrue(doc == NULL);
	XCTAssertNotNil(error);
}

- (void)testParseWithResolvedEntity {
	[[CYSimpleEntityResolver sharedResolver] setInternalEntities:@{@"emsp" : @"&#160;"}];
	NSData *data = [@"<section><p>&emsp;</p></section>" dataUsingEncoding:NSUTF8StringEncoding];
	CYDataInputSource *input = [[CYDataInputSource alloc] initWithData:data options:0];
	
	NSError *error = nil;
	NSString *result = [input asString:NO error:&error];
	assertThat(error, nilValue());
	NSString *expected = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
						@"<section><p>&emsp;</p></section>\n";
	assertThat(expected, equalTo(result));
}

- (void)testParseWithResolvedEntitySubstitute {
	[[CYSimpleEntityResolver sharedResolver] setInternalEntities:@{@"copy" : @"&#169;"}];
	NSData *data = [@"<section><p>&copy;</p></section>" dataUsingEncoding:NSUTF8StringEncoding];
	CYDataInputSource *input = [[CYDataInputSource alloc] initWithData:data options:(CYParsingOptions)(XML_PARSE_NOENT)];
	
	NSError *error = nil;
	NSString *result = [input asString:NO error:&error];
	assertThat(error, nilValue());
	NSString *expected = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
						@"<section><p>\u00a9</p></section>\n";
	assertThat(expected, equalTo(result));
}

#pragma mark - HTML support

- (void)testParseSimpleHTML {
	NSData *data = [@"<html><p>Hello, world.<br>I said hello!</p></html>" dataUsingEncoding:NSUTF8StringEncoding];
	CYDataInputSource *input = [[CYDataInputSource alloc] initWithData:data options:CYParsingAsHTML];
	
	NSError *error = nil;
	xmlDocPtr doc = [input getDocument:&error];
	XCTAssertTrue(doc != NULL);
	XCTAssertNil(error);
}

- (void)testParseAsHTMLWithEntities {
	NSData *data = [@"<section><p>&emsp;&nbsp;</p></section>" dataUsingEncoding:NSUTF8StringEncoding];
	CYDataInputSource *input = [[CYDataInputSource alloc] initWithData:data options:CYParsingAsHTML];
	
	NSError *error = nil;
	NSString *result = [input asString:NO error:&error];
	XCTAssertNil(error);
	NSString *expected = @"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n"
						@"<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">\n"
						@"<html><body><section><p>  </p></section></body></html>\n";
	XCTAssertEqualObjects(expected, result);
}

@end
