//  MIT Licence
//
//  Created on 02/01/2013.
//
//  Copyright (c) 2013 Brice Rosenzweig.
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

#import "GCGarminActivityDetailJsonParser.h"

@implementation GCGarminActivityDetailJsonParser

-(instancetype)init{
    return [super init];
}
-(GCGarminActivityDetailJsonParser*)initWithString:(NSString*)theString andEncoding:(NSStringEncoding)encoding{
    NSData *jsonData = [theString dataUsingEncoding:encoding];
    return [self initWithData:jsonData];
}
-(GCGarminActivityDetailJsonParser*)initWithData:(NSData*)jsonData{
    self = [super init];
    if (self) {
        NSError *e = nil;

        NSMutableDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&e];

        if (e) {
            self.success = false;
            RZLog(RZLogError, @"parsing failed %@", e);

        }else {
            self.success = true;
            if (json[@"metricDescriptors"]!=nil) {
                self.trackPoints = [NSArray arrayWithArray:[self parseModernFormat:json]];
            }else{
                NSArray * keys = json.allKeys;
                if (keys && [keys isKindOfClass:[NSArray class]] && keys.count > 0) {
                    if (json[@"error"]) {
                        self.success = false;
                        if ([json[@"error"] isEqualToString:@"WebApplicationException"]) {
                            RZLog(RZLogInfo, @"WebException, need login");
                            self.webError = true;
                        }else{
                            RZLog(RZLogError, @"Got json error %@", json[@"error"]);
                        }
                    }else{
                        self.trackPoints = [NSArray arrayWithArray:[self parseClassicFormat:json[json.allKeys[0]]]];
                    }
                }
            }
        }
    }

    return self;
}

-(NSArray*)parseClassicFormat:(NSDictionary*)data{
    if (![data isKindOfClass:[NSDictionary class]]) {
        RZLog(RZLogError, @"Expected NSDictionary got %@", NSStringFromClass([data class]));
        self.success = false;
        return nil;
    }

    NSArray * measurements = data[@"measurements"];
    NSArray * metrics = data[@"metrics"];
    if (metrics == nil || measurements == nil) {
        RZLog(RZLogError, @"Unexpected shape for NSDictionary");
        return nil;
    }
    NSMutableArray * rv = [NSMutableArray arrayWithCapacity:metrics.count];
    for (NSDictionary * one in metrics) {
        NSArray * values = one[@"metrics"];

        NSMutableDictionary * onemeasurement = [NSMutableDictionary dictionaryWithCapacity:values.count];


        for (NSDictionary * defs in measurements) {
            NSUInteger index = [defs[@"metricsIndex"] integerValue];
            if (index < values.count) {
                double measure = [values[index] doubleValue];
                NSDictionary * d = @{@"display": defs[@"display"],
                                    @"unit": defs[@"unit"],
                                    @"value": @(measure)};
                onemeasurement[defs[@"key"]] = d;
            }
        }
        [rv addObject:onemeasurement];
    }
    return rv;
}

-(NSArray*)parseModernFormat:(NSDictionary*)data{
    NSArray * descriptors = data[@"metricDescriptors"];
    NSArray * metrics = data[@"activityDetailMetrics"];
    NSMutableArray * rv = nil;
    BOOL errorReported = false;
    BOOL errorReportedDefs = false;
    if ([metrics isKindOfClass:[NSArray class]]) {
        rv = [NSMutableArray arrayWithCapacity:metrics.count];
        for (NSDictionary * one in metrics) {
            NSArray * values = one[@"metrics"];

            NSMutableDictionary * onemeasurement = [NSMutableDictionary dictionaryWithCapacity:values.count];

            for (NSDictionary * defs in descriptors) {
                if( [defs isKindOfClass:[NSDictionary class]]){
                    NSUInteger index = [defs[@"metricsIndex"] integerValue];
                    if (index < values.count) {
                        NSNumber * num = values[index];
                        if ([num respondsToSelector:@selector(doubleValue)]) {
                            double measure = [values[index] doubleValue];
                            NSString * key = defs[@"key"];
                            NSString * unitkey = nil;

                            NSDictionary * unitDict = defs[@"unit"];
                            if( [unitDict isKindOfClass:[NSDictionary class]]){
                                unitkey = unitDict[@"key"];
                            }else{
                                if( ! errorReported ){
                                    RZLog(RZLogError, @"Received unknown unit type %@: %@", NSStringFromClass([unitDict class]), unitDict);
                                    errorReported = true;
                                }
                            }
                            if( unitkey ){
                                NSDictionary * d = @{@"unit": unitkey,
                                                     @"value": @(measure)};
                                onemeasurement[key] = d;
                            }
                        }
                    }
                }else{
                    if( ! errorReportedDefs){
                        errorReportedDefs = true;
                        RZLog(RZLogError, @"Received unknown metrics defs %@: %@", NSStringFromClass([defs class]), defs);
                    }
                }
            }
            [rv addObject:onemeasurement];
        }
    }
    return rv;
}

-(NSArray*)laps{
    return @[];
}
-(void)dealloc{
    [_trackPoints release];
    [super dealloc];
}
@end
