//  MIT Licence
//
//  Created on 17/11/2012.
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

#import <UIKit/UIKit.h>
#import "GCFields.h"
#import "GCSimpleGraphCachedDataSource+Templates.h"
#import "GCActivity.h"
#import "GCTrackStats.h"
#import "GCActivityTrackOptions.h"
#import "GCMapLegendView.h"

@class GCSimpleGraphGestures;

@interface GCActivityTrackGraphViewController : UIViewController<RZChildObject>

@property (nonatomic,retain) GCActivity * activity;
@property (nonatomic,retain) GCTrackStats * trackStats;

@property (nonatomic,retain) GCField * field;

@property (nonatomic,retain) GCSimpleGraphView * graphView;
@property (nonatomic,retain) GCSimpleGraphCachedDataSource * dataSource;
@property (nonatomic,retain) GCSimpleGraphGestures * gestures;

@property (nonatomic,retain) NSArray * validOptions;
@property (nonatomic,assign) NSUInteger currentOptionIndex;
@property (nonatomic,retain) GCMapLegendView * legendView;
@property (nonatomic,retain) GCTrackStats * otherTrackStats;
@property (nonatomic,assign) BOOL otherWaitingDownload;
@property (nonatomic,assign) BOOL showSplitScreenIcon;
@property (nonatomic,retain) GCSimpleGraphRulerView * rulerView;

-(GCActivityTrackOptions*)currentOption;

-(void)refreshForCurrentOption;

@end
