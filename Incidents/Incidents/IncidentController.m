////
// IncidentController.m
// Incidents
////
// See the file COPYRIGHT for copyright information.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
////

#import <Block.h>
#import "ReportEntry.h"
#import "Incident.h"
#import "Location.h"
#import "Ranger.h"
#import "TableView.h"
#import "DispatchQueueController.h"
#import "IncidentController.h"



static NSDateFormatter *entryDateFormatter = nil;



@interface IncidentController ()
<
    NSWindowDelegate,
    NSTableViewDataSource,
    NSTableViewDelegate,
    NSTextFieldDelegate,
    TableViewDelegate
>

@property (strong) DispatchQueueController *dispatchQueueController;
@property (strong) Incident *incident;

@property (unsafe_unretained) IBOutlet NSTextField   *numberField;
@property (unsafe_unretained) IBOutlet NSPopUpButton *statePopUp;
@property (unsafe_unretained) IBOutlet NSPopUpButton *priorityPopUp;
@property (unsafe_unretained) IBOutlet NSTextField   *summaryField;
@property (unsafe_unretained) IBOutlet NSTableView   *rangersTable;
@property (unsafe_unretained) IBOutlet NSTextField   *rangerToAddField;
@property (unsafe_unretained) IBOutlet NSTableView   *typesTable;
@property (unsafe_unretained) IBOutlet NSTextField   *typeToAddField;
@property (unsafe_unretained) IBOutlet NSTextField   *locationNameField;
@property (unsafe_unretained) IBOutlet NSTextField   *locationAddressField;
@property (assign)            IBOutlet NSTextView    *reportEntriesView;
@property (assign)            IBOutlet NSTextView    *reportEntryToAddView;

@property (assign) BOOL amCompleting;
@property (assign) BOOL amBackspacing;

@end



@implementation IncidentController


- (id) initWithDispatchQueueController:(DispatchQueueController *)dispatchQueueController
                              incident:(Incident *)incident
{
    if (! incident) {
        [NSException raise:NSInvalidArgumentException format:@"incident may not be nil"];
    }

    if (self = [super initWithWindowNibName:@"IncidentController"]) {
        self.dispatchQueueController = dispatchQueueController;
        self.incident = incident;
    }
    return self;
}


- (void) dealloc
{
    self.reportEntriesView    = nil;
    self.reportEntryToAddView = nil;
}


- (void) windowDidLoad
{
    [super windowDidLoad];

    [self.reportEntryToAddView setFieldEditor:YES];

    [self reloadIncident];
}


- (void) reloadIncident
{
    if (! self.incident.number.integerValue < 0) {
        self.incident = [[self.dispatchQueueController.dataStore incidentWithNumber:self.incident.number] copy];
    }

    [self updateView];
    self.window.documentEdited = NO;
}


- (void) updateView
{
    Incident *incident = self.incident;

    NSLog(@"Displaying: %@", incident);

    NSString *summaryFromReport = incident.summaryFromReport;

    if (self.window) {
        self.window.title = [NSString stringWithFormat:
                                @"%@: %@",
                                incident.number,
                                summaryFromReport];
    }
    else {
        NSLog(@"No window?");
    }

    NSTextField *numberField = self.numberField;
    if (numberField) {
        numberField.stringValue = incident.number ? incident.number.description : @"";
    }
    else {
        NSLog(@"No numberField?");
    }

    NSPopUpButton *statePopUp = self.statePopUp;
    if (statePopUp) {
        NSInteger stateTag;

        if      (incident.closed    ) { stateTag = 4; }
        else if (incident.onScene   ) { stateTag = 3; }
        else if (incident.dispatched) { stateTag = 2; }
        else if (incident.created   ) { stateTag = 1; }
        else {
            NSLog(@"Unknown incident state.");
            stateTag = 0;
        }
        [statePopUp selectItemWithTag:stateTag];

        void (^enableState)(NSInteger, BOOL) = ^(NSInteger tag, BOOL enabled) {
            [[statePopUp itemAtIndex: [statePopUp indexOfItemWithTag:tag]] setEnabled:enabled];
        };

        void (^enableStates)(BOOL, BOOL, BOOL, BOOL) = ^(BOOL one, BOOL two, BOOL three, BOOL four) {
            enableState(1, one);
            enableState(2, two);
            enableState(3, three);
            enableState(4, four);
        };

        if      (stateTag == 1) { enableStates(YES, YES, YES, YES); }
        else if (stateTag == 2) { enableStates(YES, YES, YES, YES); }
        else if (stateTag == 3) { enableStates(NO , YES, YES, YES); }
        else if (stateTag == 4) { enableStates(YES, NO , NO , YES); }
    }
    else {
        NSLog(@"No statePopUp?");
    }

    NSPopUpButton *priorityPopUp = self.priorityPopUp;
    if (priorityPopUp) {
        [priorityPopUp selectItemWithTag:incident.priority.integerValue];
    }
    else {
        NSLog(@"No priorityPopUp?");
    }

    NSTextField *summaryField = self.summaryField;
    if (summaryField) {
        if (incident.summary && incident.summary.length) {
            summaryField.stringValue = incident.summary;
        }
        else {
            if (! [summaryField.stringValue isEqualToString:@""]) {
                summaryField.stringValue = @"";
            }
            if (! [[summaryField.cell placeholderString] isEqualToString:summaryFromReport]) {
                [summaryField.cell setPlaceholderString:summaryFromReport];
            }
        }
    }
    else {
        NSLog(@"No summaryField?");
    }

    NSTableView *rangersTable = self.rangersTable;
    if (rangersTable) {
        [rangersTable reloadData];
    }
    else {
        NSLog(@"No rangersTable?");
    }

    NSTableView *typesTable = self.typesTable;
    if (typesTable) {
        [typesTable reloadData];
    }
    else {
        NSLog(@"No typesTable?");
    }

    NSTextField *locationNameField = self.locationNameField;
    if (locationNameField) {
        locationNameField.stringValue = incident.location.name ? incident.location.name : @"";
    }
    else {
        NSLog(@"No locationNameField?");
    }

    NSTextField *locationAddressField = self.locationAddressField;
    if (locationAddressField) {
        locationAddressField.stringValue = incident.location.address ? incident.location.address : @"";
    }
    else {
        NSLog(@"No locationAddressField?");
    }

    NSTextView *reportEntriesView = self.reportEntriesView;
    if (reportEntriesView) {
        [reportEntriesView.textStorage
            setAttributedString:[self formattedReport]];

        NSRange end = NSMakeRange([[reportEntriesView string] length],0);
        [reportEntriesView scrollRangeToVisible:end];
    }
    else {
        NSLog(@"No reportEntriesView?");
    }
}


- (void) commitIncident
{
    [self.dispatchQueueController commitIncident:self.incident];
    [self reloadIncident];
}


- (NSAttributedString *) formattedReport
{
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:@""];

    for (ReportEntry *entry in self.incident.reportEntries) {
        NSAttributedString *text = [self formattedReportEntry:entry];
        [result appendAttributedString:text];
    }

    return result;
}


- (NSAttributedString *) formattedReportEntry:(ReportEntry *)entry
{
    NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n"];
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:@""];

    // Prepend a date stamp.
    NSAttributedString *dateStamp = [self dateStampForReportEntry:entry];

    [result appendAttributedString:dateStamp];

    // Append the entry text.
    NSAttributedString *text = [self textForReportEntry:entry];

    [result appendAttributedString:text];
    [result appendAttributedString:newline];

    // Add (another) newline if text didn't end in newline
    NSUInteger length = [text length];
    unichar lastCharacter = [[text string] characterAtIndex:length-1];

    if (lastCharacter != '\n') {
        [result appendAttributedString:newline];
    }

    return result;
}


- (NSAttributedString *) dateStampForReportEntry:(ReportEntry *)entry
{
    if (!entryDateFormatter) {
        entryDateFormatter = [[NSDateFormatter alloc] init];
        [entryDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    }

    NSString *dateFormatted = [entryDateFormatter stringFromDate:entry.createdDate];
    NSString *dateStamp = [NSString stringWithFormat:@"%@, %@:\n", dateFormatted, @"<Name of Operator>"];
    NSDictionary *attributes = @{
        NSFontAttributeName: [NSFont fontWithName:@"Menlo-Bold" size:0],
    };

    return [[NSAttributedString alloc] initWithString:dateStamp
                                           attributes:attributes];
}


- (NSAttributedString *) textForReportEntry:(ReportEntry *)entry
{
    NSDictionary *attributes = @{
        NSFontAttributeName: [NSFont fontWithName:@"Menlo" size:0],
    };
    NSAttributedString *text = [[NSAttributedString alloc] initWithString:entry.text
                                                               attributes:attributes];

    return text;
}


- (IBAction) save:(id)sender
{
    // Flush the text fields
    [self editSummary:self];
    [self editState:self];
    [self editPriority:self];
    [self editLocationName:self];
    [self editLocationAddress:self];

    // Get any added report text
    NSCharacterSet *whiteSpace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSTextView *reportEntryToAddView = self.reportEntryToAddView;
    NSString* reportTextToAdd = reportEntryToAddView.textStorage.string;
    reportTextToAdd = [reportTextToAdd stringByTrimmingCharactersInSet:whiteSpace];

    // Add a report entry
    if (reportTextToAdd.length > 0) {
        ReportEntry *entry = [[ReportEntry alloc] initWithText:reportTextToAdd];
        [self.incident addEntryToReport:entry];
    }

    // Commit the change
    [self commitIncident];

    // Clear the report entry view
    reportEntryToAddView.textStorage.attributedString = [[NSAttributedString alloc] initWithString:@""];
}


- (IBAction) editSummary:(id)sender {
    Incident *incident = self.incident;
    NSTextField *summaryField = self.summaryField;
    NSString *summary = summaryField.stringValue;

    if (! incident.summary || ! [summary isEqualToString:incident.summary]) {
        incident.summary = summary;
        self.window.documentEdited = YES;
    }
}


- (IBAction) editState:(id)sender {
    Incident *incident = self.incident;
    NSPopUpButton *statePopUp = self.statePopUp;
    NSInteger stateTag = statePopUp.selectedItem.tag;

    if (stateTag == 1) {
        incident.dispatched = nil;
        incident.onScene    = nil;
        incident.closed     = nil;
    }
    else if (stateTag == 2) {
        if (! incident.dispatched) { incident.dispatched = [NSDate date]; }

        incident.onScene = nil;
        incident.closed  = nil;
    }
    else if (stateTag == 3) {
        if (! incident.dispatched) { incident.dispatched = [NSDate date]; }
        if (! incident.onScene   ) { incident.onScene    = [NSDate date]; }

        incident.closed  = nil;
    }
    else if (stateTag == 4) {
        if (! incident.dispatched) { incident.dispatched = [NSDate date]; }
        if (! incident.onScene   ) { incident.onScene    = [NSDate date]; }
        if (! incident.closed    ) { incident.closed     = [NSDate date]; }
    }
    else {
        NSLog(@"Unknown state tag: %ld", stateTag);
        return;
    }

    self.window.documentEdited = YES;
}


- (IBAction) editPriority:(id)sender {
    Incident *incident = self.incident;
    NSPopUpButton *priorityPopUp = self.priorityPopUp;
    NSNumber *priority = [NSNumber numberWithInteger:priorityPopUp.selectedItem.tag];

    if (! [priority isEqualToNumber:incident.priority]) {
        NSLog(@"Priority edited.");
        incident.priority = priority;
        self.window.documentEdited = YES;
    }
}


- (IBAction) editLocationName:(id)sender {
    Incident *incident = self.incident;
    NSTextField *locationNameField = self.locationNameField;
    NSString *locationName = locationNameField.stringValue;

    if (! [locationName isEqualToString:incident.location.name]) {
        NSLog(@"Location name edited.");
        incident.location.name = locationName;
        self.window.documentEdited = YES;
    }
}


- (IBAction) editLocationAddress:(id)sender {
    Incident *incident = self.incident;
    NSTextField *locationAddressField = self.locationAddressField;
    NSString *locationAddress = locationAddressField.stringValue;

    if (! [locationAddress isEqualToString:incident.location.address]) {
        NSLog(@"Location address edited.");
        incident.location.address = locationAddress;
        self.window.documentEdited = YES;
    }
}


- (NSArray *) sourceForTableView:(NSTableView *)tableView
{
    if (tableView == self.rangersTable) {
        return self.incident.rangersByHandle.allValues;
    }
    else if (tableView == self.typesTable) {
        return self.incident.types;
    }
    else {
        NSLog(@"Table view unknown to IncidentController: %@", tableView);
        return nil;
    }
}


- (NSArray *) sortedSourceArrayForTableView:(NSTableView *)tableView
{
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@""
                                                                 ascending:YES];

    NSArray *source = [self sourceForTableView:tableView];

    return [source sortedArrayUsingDescriptors:@[descriptor]];
}


- (id) itemFromTableView:(NSTableView *)tableView row:(NSInteger)rowIndex
{
    if (rowIndex < 0) {
        return nil;
    }

    NSArray *sourceArray = [self sortedSourceArrayForTableView: tableView];

    if (rowIndex > (NSInteger)sourceArray.count) {
        NSLog(@"IncidentController got out of bounds rowIndex: %ld", rowIndex);
        return nil;
    }

    return sourceArray[(NSUInteger)rowIndex];
}



@end



@implementation IncidentController (NSWindowDelegate)


- (BOOL) windowShouldClose:(id)sender {
    return YES;
}


- (void) windowWillClose:(NSNotification *)notification {
    if (notification.object != self.window) {
        return;
    }

    [self reloadIncident];
}


@end



@implementation IncidentController (NSTableViewDataSource)


- (NSUInteger) numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == self.rangersTable) {
        return self.incident.rangersByHandle.count;
    }
    else if (tableView == self.typesTable) {
        return self.incident.types.count;
    }
    else {
        NSLog(@"Table view unknown to IncidentController: %@", tableView);
        return 0;
    }
}


- (id)            tableView:(NSTableView *)tableView
  objectValueForTableColumn:(NSTableColumn *)column
                        row:(NSInteger)rowIndex {
    return [self itemFromTableView:tableView row:rowIndex];
}


@end



@implementation IncidentController (NSTableViewDelegate)
@end



@implementation IncidentController (TableViewDelegate)


- (void) deleteFromTableView:(NSTableView *)tableView
{
    NSInteger rowIndex = tableView.selectedRow;

    id objectToDelete = [self itemFromTableView:tableView row:rowIndex];

    if (objectToDelete) {
        NSLog(@"Removing: %@", objectToDelete);

        if (tableView == self.rangersTable) {
            [self.incident removeRanger:objectToDelete];
        }
        else if (tableView == self.typesTable) {
            [self.incident.types removeObject:objectToDelete];
        }
        else {
            NSLog(@"Table view unknown to IncidentController: %@", tableView);
            return;
        }
        
        [self updateView];

        self.window.documentEdited = YES;
    }
}


- (void) openFromTableView:(NSTableView *)tableView
{
}


@end



@implementation IncidentController (NSTextFieldDelegate)


- (NSArray *) completionSourceForControl:(NSControl *)control
{
    if (control == self.rangerToAddField) {
        return self.dispatchQueueController.dataStore.allRangersByHandle.allKeys;
    }

    if (control == self.typeToAddField) {
        return self.dispatchQueueController.dataStore.allIncidentTypes;
    }

    return nil;
}


- (NSArray *) completionsForWord:(NSString *)word
                      fromSource:(NSArray *)source
{
    if (! [word isEqualToString:@"?"]) {
        BOOL(^startsWithFilter)(NSString *, NSDictionary *) = ^(NSString *text, NSDictionary *bindings) {
            NSRange range = [text rangeOfString:word options:NSAnchoredSearch|NSCaseInsensitiveSearch];

            return (BOOL)(range.location != NSNotFound);
        };
        NSPredicate *predicate = [NSPredicate predicateWithBlock:startsWithFilter];

        // FIXME: This doesn't work because completion rewrites the entered text
//        BOOL(^containsFilter)(NSString *, NSDictionary *) = ^(NSString *text, NSDictionary *bindings) {
//            NSRange range = [text rangeOfString:word options:NSCaseInsensitiveSearch];
//
//            return (BOOL)(range.location != NSNotFound);
//        };
//        NSPredicate *predicate = [NSPredicate predicateWithBlock:containsFilter];

        source = [source filteredArrayUsingPredicate:predicate];
    }
    source = [source sortedArrayUsingSelector:NSSelectorFromString(@"localizedCaseInsensitiveCompare:")];

    return source;
}


- (NSArray *) control:(NSControl *)control
             textView:(NSTextView *)textView
          completions:(NSArray *)words
  forPartialWordRange:(NSRange)charRange
  indexOfSelectedItem:(NSInteger *)index
{
    NSArray *source = [self completionSourceForControl:control];

    if (! source) {
        NSLog(@"Completion request from unknown control: %@", control);
        return @[];
    }

    return [self completionsForWord:textView.string fromSource:source];
}


- (void) controlTextDidChange:(NSNotification *)notification
{
    if (self.amBackspacing) {
        self.amBackspacing = NO;
        return;
    }

    if (! self.amCompleting) {
        self.amCompleting = YES;

        NSTextView *fieldEditor = [[notification userInfo] objectForKey:@"NSFieldEditor"];
        [fieldEditor complete:nil];

        self.amCompleting = NO;
    }
}


- (void)      control:(NSControl *)control
             textView:(NSTextView *)textView
  doCommandBySelector:(SEL)command
{
    if (control == self.rangerToAddField || control == self.typeToAddField) {
        if (command == NSSelectorFromString(@"deleteBackward:")) {
            self.amBackspacing = YES;
        }
        else if (command == NSSelectorFromString(@"insertNewline:")) {
            if (control == self.rangerToAddField) {
                NSTextField *rangerToAddField = self.rangerToAddField;
                NSString *rangerHandle = rangerToAddField.stringValue;

                if (rangerHandle.length > 0) {
                    Ranger *ranger = self.incident.rangersByHandle[rangerHandle];
                    if (! ranger) {
                        ranger = self.dispatchQueueController.dataStore.allRangersByHandle[rangerHandle];
                        if (ranger) {
                            NSLog(@"Ranger added: %@", ranger);
                            [self.incident addRanger:ranger];
                            self.window.documentEdited = YES;
                            rangerToAddField.stringValue = @"";
                            [self updateView];
                        }
                        else {
                            NSLog(@"Unknown Ranger: %@", rangerHandle);
                            NSBeep();
                        }
                    }
                }
            }
            else if (control == self.typeToAddField) {
                NSTextField *typeToAddField = self.typeToAddField;
                NSString *type = typeToAddField.stringValue;

                if (type.length > 0) {
                    if (! [self.incident.types containsObject:type]) {
                        if ([self.dispatchQueueController.dataStore.allIncidentTypes containsObject:type]) {
                            NSLog(@"Type added: %@", type);
                            [self.incident.types addObject:type];
                            self.window.documentEdited = YES;
                            typeToAddField.stringValue = @"";
                            [self updateView];
                        }
                        else {
                            NSLog(@"Unknown incident type: %@", type);
                            NSBeep();
                        }
                    }
                }
            }
        }
        else {
            NSLog(@"Do command: %@", NSStringFromSelector(command));
        }
    }
}


- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)selector
{
    if (textView == self.reportEntryToAddView) {
	if (selector == NSSelectorFromString(@"insertNewline:")) {
            NSTextView *reportEntryToAddView = self.reportEntryToAddView;
            [reportEntryToAddView insertNewlineIgnoringFieldEditor:self];
            return YES;
        }
    }
    return NO;
}


@end
