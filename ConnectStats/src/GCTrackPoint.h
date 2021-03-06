//  MIT Licence
//
//  Created on 18/09/2012.
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

#import <Foundation/Foundation.h>
#import "CoreLocation/CoreLocation.h"
#import "GCFields.h"
#import "GCField.h"
#import "GCTrackPointExtraIndex.h"

@class GCActivity;
@class GCActivitySummaryValue;

@interface GCTrackPoint : NSObject

/**
 @brief date and time of the point
 */
@property (nonatomic,retain) NSDate * time;
@property (nonatomic,assign) double longitudeDegrees;
@property (nonatomic,assign) double latitudeDegrees;

/**
 @brief Elapsed/Duration for which the Trackpoint is applicable
 */
@property (nonatomic,assign) NSTimeInterval elapsed;

/**
 @brief Distance since the beginning in meters
 */
@property (nonatomic,assign) double distanceMeters;

// Hard Coded Fields
@property (nonatomic,assign) double heartRateBpm;
@property (nonatomic,assign) double speed;
@property (nonatomic,assign) double cadence;
@property (nonatomic,assign) double altitude;
@property (nonatomic,assign) double power;
@property (nonatomic,assign) double verticalOscillation;
@property (nonatomic,assign) double groundContactTime;
@property (nonatomic,assign) double steps;

/**
 @brief Index in the laps
 */
@property (nonatomic,assign) NSUInteger lapIndex;
/**
 @brief flags with the fields available as gcFieldFlag
 */
@property (nonatomic,assign) NSUInteger trackFlags;
@property (nonatomic,retain) NSMutableDictionary * calculated;

/**
 @brief extra fields values. Either null or array of size kMaxExtraIndex
 */
@property (nonatomic,assign) double * fieldValues;

-(instancetype)init NS_DESIGNATED_INITIALIZER;
-(GCTrackPoint*)initWithDictionary:(NSDictionary*)aDict forActivity:(GCActivity*)act NS_DESIGNATED_INITIALIZER;
-(GCTrackPoint*)initWithResultSet:(FMResultSet*)res NS_DESIGNATED_INITIALIZER;
-(void)saveToDb:(FMDatabase*)trackdb;

+(GCTrackPoint*)trackPointWithCoordinate2D:(CLLocationCoordinate2D)coord;
+(GCTrackPoint*)trackPointWithCoordinate2D:(CLLocationCoordinate2D)coord
                                        at:(NSDate*)timestamp
                                       for:(NSDictionary<NSString*,GCActivitySummaryValue*>*)sumValues
                                inActivity:(GCActivity*)act;

-(NSString*)fullDescription:(NSString*)atype;

-(NSString*)displayLabel;

-(BOOL)validCoordinate;
-(CLLocationCoordinate2D)coordinate2D;
-(CLLocation*)location;
-(CLLocationDistance)distanceMetersFrom:(GCTrackPoint*)other;
-(NSTimeInterval)timeIntervalSince:(GCTrackPoint*)other;
-(NSComparisonResult)compareTime:(GCTrackPoint*)other;

-(BOOL)hasField:(gcFieldFlag)afield;
-(double)valueForField:(gcFieldFlag)aField;
-(void)setValue:(double)val forField:(gcFieldFlag)aField;
-(double)extraValueForIndex:(GCTrackPointExtraIndex*)idx;
-(void)setExtraValue:(double)val forIndex:(GCTrackPointExtraIndex*)idx;
-(void)setExtraValue:(GCNumberWithUnit*)nu forFieldKey:(NSString*)field in:(GCActivity*)act;

+(GCUnit*)unitForField:(gcFieldFlag)aField andActivityType:(NSString*)aType;
-(GCNumberWithUnit*)numberWithUnitForField:(gcFieldFlag)aField andActivityType:(NSString*)aType;

-(void)add:(GCTrackPoint*)other withAccrued:(double)accrued timeAxis:(BOOL)timeAxis;

-(void)mergeWith:(GCTrackPoint*)other;
-(BOOL)realisticForActivityType:(NSString*)aType;

// for derived classes
/**
 Main Access for value
 */
-(GCNumberWithUnit*)numberWithUnitForField:(GCField*)aF inActivity:(GCActivity*)act;

-(GCNumberWithUnit*)numberWithUnitForExtra:(GCTrackPointExtraIndex*)idx;
-(GCNumberWithUnit*)numberWithUnitForExtra:(NSString*)aF activityType:(NSString*)aType;
-(GCNumberWithUnit*)numberWithUnitForCalculated:(NSString*)aF;
-(void)addNumberWithUnitForCalculated:(GCNumberWithUnit*)aN forField:(NSString*)aF;

-(void)updateWithNextPoint:(GCTrackPoint*)next;

@end
