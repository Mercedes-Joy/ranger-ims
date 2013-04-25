////
// ReportEntry.m
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

#import "ReportEntry.h"



@interface ReportEntry ()
@end



@implementation ReportEntry


- (id) initWithText:(NSString *)text
{
    return [self initWithText:text createdDate:nil];
}


- (id) initWithText:(NSString *)text
        createdDate:(NSDate *)createdDate
{
    if (self = [super init]) {
        if (! createdDate) {
            createdDate = [NSDate date];
        }

        self.createdDate = createdDate;
        self.text        = text;
    }
    return self;
}


- (BOOL) isEqual:(id)other
{
    if (other == self) {
        return YES;
    }
    if (! other || ! [other isKindOfClass:self.class]) {
        return NO;
    }
    return [self isEqualToReportEntry:other];
}


- (BOOL) isEqualToReportEntry:(ReportEntry *)other
{
    if (self == other) {
        return YES;
    }

    if ((self.text        != other.text       ) && (! [self.text        isEqualToString: other.text       ])) { return NO; }
    if ((self.createdDate != other.createdDate) && (! [self.createdDate isEqualToDate:   other.createdDate])) { return NO; }

    return YES;
}


@end
