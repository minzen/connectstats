//  MIT Licence
//
//  Created on 24/06/2013.
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

#import "GCFieldsCalculatedTrack.h"
#import "GCActivity.h"
#import "GCTrackPoint.h"
#import "GCLap.h"
#import "GCActivityCalculatedValue.h"

#define CALC_PREFIX @"__Calc"

#define CALC_ALTITUDE_GAIN CALC_PREFIX @"GainElevation"
#define CALC_ALTITUDE_LOSS CALC_PREFIX @"LossElevation"
#define CALC_NORMALIZED_POWER CALC_PREFIX @"NormalizedPower"
#define CALC_NONZERO_POWER CALC_PREFIX @"NonZeroAvgPower"


@implementation GCFieldsCalculatedTrack

-(void)setupActivity:(GCActivity *)act{

}

-(void)setupLap:(GCLap*)lap{

}

-(void)startWithPoint:(GCTrackPoint *)point{

}

-(void)newPoint:(GCTrackPoint*)point forLaps:(NSArray<GCLap*>*)lap inActivity:(GCActivity *)act{

}

+(void)addCalculatedFieldsToTrackPointsAndLaps:(GCActivity *)act{
    if( act.trackpoints && act.laps){
        NSArray * fields = @[ [[[GCFieldsCalculatedTrackElevation alloc] init] autorelease] ];

        if ([act hasTrackField:gcFieldFlagPower]) {
            fields = [fields arrayByAddingObject:[[[GCFieldsCalculatedTrackNormalizedPower alloc] init] autorelease]];
        }
        GCLap * totalActivityLap = [[[GCLap alloc] init] autorelease];

        for (GCLap * lap in act.laps) {
            for (GCFieldsCalculatedTrack * field in fields) {
                [field setupLap:lap];
            }
        }
        for (GCFieldsCalculatedTrack * field in fields) {
            [field setupLap:totalActivityLap];
        }


        BOOL started = false;
        for (GCTrackPoint * point in act.trackpoints) {
            if (!started) {
                started = true;
                for (GCFieldsCalculatedTrack * field in fields) {
                    [field startWithPoint:point];
                }
            }else{
                if (point.lapIndex < act.laps.count) {
                    GCLap * lap = act.laps[point.lapIndex];
                    for (GCFieldsCalculatedTrack * field in fields) {
                        [field newPoint:point forLaps:@[lap,totalActivityLap] inActivity:act];
                    }

                }
            }
        }

        NSMutableDictionary * newFields = [NSMutableDictionary dictionary];

        for (NSString * fieldKey in totalActivityLap.calculated) {
            GCActivityCalculatedValue * calcVal = [GCActivityCalculatedValue calculatedValue:fieldKey value:totalActivityLap.calculated[fieldKey]];
            newFields[fieldKey] = calcVal;
        }
        if(newFields.count>0){
            [act addEntriesToCalculatedFields:newFields];
        }
    }
}

@end

@implementation GCFieldsCalculatedTrackElevation

-(void)setupLap:(GCLap*)lap{
    [lap.calculated removeObjectForKey:CALC_ALTITUDE_GAIN];
    [lap.calculated removeObjectForKey:CALC_ALTITUDE_LOSS];
}

-(void)startWithPoint:(GCTrackPoint *)point{
    self.altitude = point.altitude;
}

-(void)newPoint:(GCTrackPoint*)point forLaps:(NSArray<GCLap*>*)laps inActivity:(GCActivity *)act{
    for (GCLap * lap in laps) {
        GCNumberWithUnit * altitudeGain = lap.calculated[CALC_ALTITUDE_GAIN];
        GCNumberWithUnit * altitudeLoss = lap.calculated[CALC_ALTITUDE_LOSS];
        if (!altitudeGain) {
            altitudeGain = [GCNumberWithUnit numberWithUnitName:STOREUNIT_ALTITUDE andValue:0.];
            [lap addNumberWithUnitForCalculated:altitudeGain forField:CALC_ALTITUDE_GAIN];
        }
        if (!altitudeLoss) {
            altitudeLoss = [GCNumberWithUnit numberWithUnitName:STOREUNIT_ALTITUDE andValue:0.];
            [lap addNumberWithUnitForCalculated:altitudeLoss forField:CALC_ALTITUDE_LOSS];
        }
        // after added calculation are done inplace so no need to re-add number
        double altitudeDiff = point.altitude-self.altitude;
        if (altitudeDiff > 0) {
            altitudeGain.value += altitudeDiff;
        }else{
            altitudeLoss.value += -altitudeDiff;
        }
    }
    self.altitude = point.altitude;
}


@end

@implementation GCFieldsCalculatedTrackNormalizedPower{
    size_t   _nSamples;
    size_t   _idxSamples;
    double * _samples;
    double _sampleSum;
    double _runningSum;
    double _nPoints;

    double _nonZeroSum;
    double _nNonZero;
}

-(GCFieldsCalculatedTrackNormalizedPower*)init{
    self = [super init];
    if (self) {
        self.movingAverage = 30;
        _samples = nil;
        _runningSum = 0.;
        _nPoints = 0.;
        _nSamples = 0;
        _idxSamples = 0;
    }
    return self;
}

-(void)dealloc{
    free(_samples);

    [super dealloc];
}

-(void)setupLap:(GCLap *)lap{
    [lap.calculated removeObjectForKey:CALC_NORMALIZED_POWER];
    [lap.calculated removeObjectForKey:CALC_NONZERO_POWER];
}

-(void)startWithPoint:(GCTrackPoint *)point{
}

-(void)newPoint:(GCTrackPoint*)point forLaps:(NSArray<GCLap*>*)laps inActivity:(GCActivity *)act{
    // Note, it get reset and samples restart at each lap
    // Not great as technically should restart only for each individual lap, but probably close enough for
    // now
    for (GCLap * lap in laps) {
        GCNumberWithUnit * normalized = lap.calculated[CALC_NORMALIZED_POWER];
        GCNumberWithUnit * nonzero    = lap.calculated[CALC_NONZERO_POWER];
        if (!normalized) {
            nonzero    = [GCNumberWithUnit numberWithUnitName:@"watt" andValue:0.];
            normalized = [GCNumberWithUnit numberWithUnitName:@"watt" andValue:0.];
            [lap addNumberWithUnitForCalculated:normalized  forField:CALC_NORMALIZED_POWER];
            [lap addNumberWithUnitForCalculated:nonzero     forField:CALC_NONZERO_POWER];
            // start new lap
            free(_samples);
            _samples = calloc(sizeof(double), self.movingAverage);

            _idxSamples = 0;
            _nSamples = 1;
            _sampleSum = 0.;
            _samples[_idxSamples++]=point.power;

            _nPoints = 0;
            _runningSum = 0.;

            _nonZeroSum = 0.;
            _nNonZero = 0.;
        }

        if (fabs(point.power)<1.e-1) {
            return;
        }

        if (_idxSamples == self.movingAverage) {
            _idxSamples = 0;
        }

        _nonZeroSum += point.power;
        _nNonZero++;
        nonzero.value = _nonZeroSum/_nNonZero;

        if (_nSamples < self.movingAverage) {
            _samples[_idxSamples++]=point.power;
            _sampleSum += point.power;
            _nSamples++;

        }else{
            _sampleSum += (point.power-_samples[_idxSamples]);
            _samples[_idxSamples++]=point.power;

            double v = (_sampleSum/self.movingAverage);

            _runningSum += pow(v, 4.);
            _nPoints+=1.;

            double val = pow(_runningSum/_nPoints, 1./4.);

            normalized.value = val;
        }
    }
}


@end

/*
 http://www.kreuzotter.de/english/espeed.htm

 P	Rider's power
 V	Velocity of the bicycle
 W	Wind speed
 Hnn	Height above sea level (influences air density)
 T	Air temperature, in ° Kelvin (influences air density)
 grade	Inclination (grade) of road, in percent
 β	("beta") Inclination angle, = arctan(grade/100)
 mbike	Mass of the bicycle (influences rolling friction, slope pulling force, and normal force)
 mrider	Mass of the rider (influences rolling friction, slope pulling force, and the rider's frontal area via body volume)
 Cd	Air drag coefficient
 A	Total frontal area (bicycle + rider)
 Cr	Rolling resistance coefficient
 CrV	Coefficient for velocity-dependent dynamic rolling resistance, here approximated with 0.1
 CrVn	Coefficient for the dynamic rolling resistance, normalized to road inclination; CrVn = CrV*cos(β)
 Cm	Coefficient for power transmission losses and losses due to tire slippage (the latter can be heard while pedaling powerfully at low speeds)
 ρ	("rho") Air density
 ρ0	Air density on sea level at 0° Celsius (32°F)
 p0	Air pressure on sea level at 0° Celsius (32°F)
 g	Gravitational acceleration
 Frg	Rolling friction (normalized on inclined plane) plus slope pulling force on inclined plane

 rho = rho0 * 373 / T * e(-rho0 * g * Hnn/p0)
 Frg = g *(mbike+mrider)*(Cr * cos(beta)+sin(beta))
 P = Cm * V * ( Cd * A *rho/2*(V+W)^2 + Frg + V * CrVn
*/

#define C_G 9.81
#define C_RHO0 1.

@implementation GCFieldsCalculatedTrackEstimatedPower{
    double _windspeed;
    double _temperature;
    double _mbike;
    double _mrider;
}

-(double)powerFrom:(GCTrackPoint*)from to:(GCTrackPoint*)to{

    double V = from.speed;
    double W = _windspeed;
    double Hnn = from.altitude;
    double T = _temperature;

    double grade = (to.altitude-from.altitude)/(to.distanceMeters-from.distanceMeters);
    double beta = atan(grade*0.01);

    double p0 = 1;
    double Cr = 1;
    double Cm = 1;
    double Cd = 1;
    double A  = 1;
    double CrVn = 1;

    double rho = C_RHO0 * 373. / T * exp(-1 * C_RHO0 * C_G * Hnn/p0);
    double Frg = C_G * (_mbike+_mrider)*(Cr+cos(beta)+sin(beta));
    double VW = V+W;
    double P = Cm * V * ( (Cd * A *rho*0.5*VW*VW) + Frg + V * CrVn);

    return P;
}

@end
