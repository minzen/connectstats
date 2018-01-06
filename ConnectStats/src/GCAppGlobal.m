//  MIT Licence
//
//  Created on 08/09/2012.
//
//  Copyright (c) 2012 Brice Rosenzweig.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//  

#import "GCAppGlobal.h"
#import "GCAppDelegate.h"
#import "Flurry.h"
#import "GCHealthViewController.h"
#import "GCWebConnect+Requests.h"

#ifdef GC_USE_HEALTHKIT
#import <HealthKit/HealthKit.h>
#endif

NSString *const kNotifySettingsChange = @"NotifySettingsChange";

static NSDictionary * _debugState = nil;
static NSCalendar * _cacheCalendar = nil;

static GCAppDelegate * _cacheApplicationDelegate = nil;


NS_INLINE GCAppDelegate * _sharedApplicationDelegate(void){
    if( _cacheApplicationDelegate == nil){
        _cacheApplicationDelegate = (GCAppDelegate*)[UIApplication sharedApplication].delegate;
    }
    return _cacheApplicationDelegate;
}

@implementation GCAppGlobal

+(HKHealthStore*)healthKitStore{
    static BOOL tested = false;
    static HKHealthStore * hkstore = nil;

    if (!tested) {
        tested = true;
#ifdef GC_USE_HEALTHKIT
        if ([HKHealthStore isHealthDataAvailable]) {
            hkstore = [[HKHealthStore alloc] init];
        }
#endif
    }

    return hkstore;
}

+(void)setApplicationDelegate:(GCAppDelegate*)del{
    _cacheApplicationDelegate = del;
}

+(BOOL)connectStatsVersion{
    return [GCAppDelegate connectStatsVersion];
}
+(BOOL)trialVersion{
    return [GCAppDelegate trialVersion];
}
+(BOOL)healthStatsVersion{
    return [GCAppDelegate healthStatsVersion];
}

#pragma mark - Singletons access

+(GCActivitiesOrganizer*)organizer{
    GCAppDelegate * app = _sharedApplicationDelegate();
    return app.organizer;

}

+(GCHealthOrganizer*)health{
    GCAppDelegate * app = _sharedApplicationDelegate();
    return app.health;
}
+(FMDatabase*)db{
    GCAppDelegate * app = _sharedApplicationDelegate();
    return app.db;
}
+(NSMutableDictionary*)settings{
    GCAppDelegate * app = _sharedApplicationDelegate();
    return app.settings;
}

+(GCWebConnect*)web{
    GCAppDelegate * app = _sharedApplicationDelegate();
    return app.web;
}
+(dispatch_queue_t)worker{
    GCAppDelegate *appDelegate = _sharedApplicationDelegate();
    return appDelegate.worker;
}

+(GCAppProfiles*)profile{
    GCAppDelegate *appDelegate = _sharedApplicationDelegate();
    return appDelegate.profiles;
}

+(GCDerivedOrganizer*)derived{
    GCAppDelegate *appDelegate = _sharedApplicationDelegate();
    return appDelegate.derived;
}

+(UINavigationController*)currentNavigationController{
    GCAppDelegate *appDelegate = _sharedApplicationDelegate();
    return [appDelegate.actionDelegate currentNavigationController];
}

+(GCSegmentOrganizer*)segments{
    GCAppDelegate *appDelegate = _sharedApplicationDelegate();
    return appDelegate.segments;
}

+(GCActivityTypes*)activityTypes{
    GCAppDelegate *appDelegate = _sharedApplicationDelegate();
    return appDelegate.activityTypes;
}

#pragma mark - UI Focus Actions

+(void)switchToHealth{
	GCAppDelegate *appDelegate = _sharedApplicationDelegate();
    if (appDelegate.tabBarController) {
        GCTabBarController * tab = appDelegate.tabBarController;
        [tab.settingsViewController.navigationController popToRootViewControllerAnimated:NO];
        GCHealthViewController * cont = [[[GCHealthViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
        [tab.settingsViewController.navigationController pushViewController:cont animated:NO];
    }
}

+(void)focusOnStatsSummary{
    GCAppDelegate *appDelegate = _sharedApplicationDelegate();
    [appDelegate.actionDelegate focusOnStatsSummary];
}

+(void)focusOnActivityId:(NSString*)aId{
	GCAppDelegate *appDelegate = _sharedApplicationDelegate();
    [appDelegate.actionDelegate focusOnActivityId:aId];
}

+(void)focusOnListWithFilter:(NSString*)aFilter{
	GCAppDelegate *appDelegate = _sharedApplicationDelegate();
    [appDelegate.actionDelegate focusOnListWithFilter:aFilter];

}
+(void)focusOnActivityList{
    GCAppDelegate *appDelegate = _sharedApplicationDelegate();
    [appDelegate.actionDelegate focusOnActivityList];
}

+(void)focusOnActivityAtIndex:(NSUInteger)idx{
    GCAppDelegate *appDelegate = _sharedApplicationDelegate();
    [appDelegate.actionDelegate focusOnActivityAtIndex:idx];
}

#pragma mark - Global Actions

+(void)publishEvent:(NSString*)name{
#ifdef GC_USE_FLURRY
	[Flurry logEvent:name];
#endif
}

+(NSInteger)recordEvent:(NSString*)name count:(int)count every:(int)aStep{
    NSString*nextRecordKey	= [NSString stringWithFormat:@"event_next_%@",	name];

    NSInteger next    = [self configGetInt:nextRecordKey defaultValue:0];

    NSInteger rv = -1;

    if (count > next) {

        next = count/aStep+aStep;
        rv = next;
        [self configSet:nextRecordKey intVal:next];
#ifdef GC_USE_FLURRY
        NSDictionary * params = @{@"Count": @(next)};
        [Flurry logEvent:name withParameters:params];
#endif

    }

    return rv;
}


+(void)saveSettings{
	GCAppDelegate *appDelegate = _sharedApplicationDelegate();
    [appDelegate saveSettings];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifySettingsChange object:nil];
    //
}
+(void)beginRefreshing{
    GCAppDelegate *appDelegate = _sharedApplicationDelegate();

    [appDelegate.actionDelegate beginRefreshing];
}
+(void)login{
	GCAppDelegate *appDelegate = _sharedApplicationDelegate();
    [appDelegate.actionDelegate login];
}

+(void)logout{
	GCAppDelegate *appDelegate = _sharedApplicationDelegate();
    [appDelegate.actionDelegate logout];
}

+(void)addOrSelectProfile:(NSString*)pName{

	GCAppDelegate *appDelegate = _sharedApplicationDelegate();
    [appDelegate addOrSelectProfile:pName];
}

+(void)startSuccessful{
    GCAppDelegate *appDelegate = _sharedApplicationDelegate();
    [appDelegate startSuccessful];
}

+(void)searchAllActivities{
    GCAppDelegate *appDelegate = _sharedApplicationDelegate();
    [appDelegate searchAllActivities];
}

+(void)startupRefreshIfNeeded{
    GCAppDelegate *appDelegate = _sharedApplicationDelegate();
    [appDelegate startupRefreshIfNeeded];
}

+(void)setupFieldCache{
    GCAppDelegate *appDelegate = _sharedApplicationDelegate();
    [appDelegate setupFieldCache];
}

+(NSDictionary*)debugState{
    if (!_debugState) {
        _debugState = @{};
        [_debugState retain];
    }
    return _debugState;
}

+(void)debugStateRecord:(NSDictionary*)dict{
    if (!_debugState) {
        _debugState = dict;
        [_debugState retain];
    }else{
        NSDictionary * newDict = [_debugState dictionaryByAddingEntriesFromDictionary:dict];
        [_debugState release];
        _debugState = newDict;
        [_debugState retain];
    }
}

+(void)debugStateClear{
    [_debugState release];
    _debugState = nil;
}


#pragma mark - Dates

+(NSCalendar*)calculationCalendar{
    if (_cacheCalendar == nil) {
        _cacheCalendar = [[NSCalendar currentCalendar] retain];
    }

    NSInteger firstday = [self configGetInt:CONFIG_FIRST_DAY_WEEK defaultValue:1];
    if (firstday!=_cacheCalendar.firstWeekday) {
        _cacheCalendar.firstWeekday = firstday;
    }

    return _cacheCalendar;
}
+(NSDate*)referenceDate{
    NSDate * refdate = nil;

    gcPeriodType period = (gcPeriodType)[GCAppGlobal configGetInt:CONFIG_PERIOD_TYPE defaultValue:gcPeriodCalendar];
    if (period==gcPeriodRolling) {
        refdate = [NSDate date];
        /* Test
        NSDateComponents * comp = [[[NSDateComponents alloc] init] autorelease];
        comp.month = 3;
        comp.year=2014;
        comp.day=9;
        refdate = [[GCAppGlobal calculationCalendar] dateFromComponents:comp];
        */
    }else if(period==gcPeriodReferenceDate){
        NSTimeInterval refInterval = [GCAppGlobal configGetDouble:CONFIG_REFERENCE_DATE defaultValue:0.];
        if (refInterval==0.) {
            NSDateComponents * comp = [[[NSDateComponents alloc] init] autorelease];
            comp.month = 3;
            comp.year=2014;
            comp.day=9;
            refdate = [[GCAppGlobal calculationCalendar] dateFromComponents:comp];
        }else{
            refdate = [NSDate dateWithTimeIntervalSinceReferenceDate:refInterval];
        }
    }
    return refdate;
}
+(NSString*)simulatorUrl{
    return nil;
}
@end
