//
//  SearchResultsController.m
//  VisualBackup
//
//  Created by Jevgeni Zelenkov on 06.02.13.
//  Copyright (c) 2013 Jevgeni Zelenkov. All rights reserved.
//

#import "SearchResultsController.h"
#import "ImageBrowserController.h"

@implementation SearchResultsController

-(IBAction)toggleButtonClicked:(id)sender
{
    if ([_searchResultsBrowserScroller isHidden]) {
        [_imageBrowserScroller setHidden:YES];
        [_searchResultsBrowserScroller setHidden:NO];
    } else {
        [_imageBrowserScroller setHidden:NO];
        [_searchResultsBrowserScroller setHidden:YES];
    }
}

#pragma mark -
#pragma mark Keyword search handling

// -------------------------------------------------------------------------------
//	allKeywords:
//
//	This method builds our keyword array for use in type completion (dropdown list
//	in NSSearchField).
// -------------------------------------------------------------------------------
- (NSArray *)allKeywords
{
//    if (allKeywords == nil) {
//        allKeywords = [[NSMutableArray alloc] initWithObjects:
//                           @"Favorite", @"Favorite1", @"Favorite11", @"Favorite3", @"Vacations1", @"Vacations2", @"Hawaii", @"Family", @"Important", @"Important2",@"Personal", nil];
        NSMutableSet *allApps = [NSMutableSet set];
        NSDictionary *runningApps = [imageBrowserController runningApps];
        for(NSArray *arr in [runningApps allValues]) {
            for(NSString *appName in arr) {
                [allApps addObject:appName];
            }
        }
        allKeywords = [NSMutableArray arrayWithArray:[allApps allObjects]];
//        [allKeywords sortUsingSelector:@selector(compare:)];
//    }

    return allKeywords;
}


// -------------------------------------------------------------------------------
//	control:textView:completions:forPartialWordRange:indexOfSelectedItem:
//
//	Use this method to override NSFieldEditor's default matches (which is a much bigger
//	list of keywords).  By not implementing this method, you will then get back
//	NSSearchField's default feature.
// -------------------------------------------------------------------------------
- (NSArray *)control:(NSControl *)control textView:(NSTextView *)textView completions:(NSArray *)words
 forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger*)index
{
    NSMutableArray*	matches = NULL;
    NSString*		partialString;
    NSArray*		keywords;
    
    partialString = [[textView string] substringWithRange:charRange];
    keywords      = [self allKeywords];
    matches       = [NSMutableArray array];
    
    // find any match in our keyword array against what was typed -
	for(id string in keywords)
    {
        if ([string rangeOfString:partialString
						  options:NSAnchoredSearch | NSCaseInsensitiveSearch
							range:NSMakeRange(0, [string length])].location != NSNotFound)
		{
            [matches addObject:string];
        }
    }
    [matches sortUsingSelector:@selector(compare:)];

	return matches;
}


// -------------------------------------------------------------------------------
//	controlTextDidChange:
//
//	The text in NSSearchField has changed, try to attempt type completion.
// -------------------------------------------------------------------------------
- (void)controlTextDidChange:(NSNotification *)obj
{
	NSTextView* textView = [[obj userInfo] objectForKey:@"NSFieldEditor"];
    
    if (!completePosting && !commandHandling)	// prevent calling "complete" too often
	{
        completePosting = YES;
        [textView complete:nil];
        completePosting = NO;
    }
}

// -------------------------------------------------------------------------------
//	control:textView:commandSelector
//
//	Handle all commend selectors that we can handle here
// -------------------------------------------------------------------------------

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    BOOL result = NO;
	
	if ([textView respondsToSelector:commandSelector])
	{
        commandHandling = YES;
        if(commandSelector == @selector(insertNewline:)) {
            [self searchScreensByName];
        } else {
            [textView performSelector:commandSelector withObject:nil];
        }
        commandHandling = NO;
		
		result = YES;
    }
	
    return result;
}
#pragma clang diagnostic pop


- (void)searchScreensByName {
    NSLog(@"seach by name!");
}

@end
