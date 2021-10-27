//
//  Voronoi.h
//  objcvoronoi
//
//  Created by Clay Heaton on 3/22/12.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class RBTree;
@class CircleEvent;
@class Beachsection;
@class Site;
@class VoronoiResult;
@class Edge;
@class Vertex;

@interface Voronoi : NSObject {
    NSMutableArray *edges;
    NSMutableArray *cells;
    NSMutableArray *beachsectionJunkyard;
    NSMutableArray *circleEventJunkyard;
    
    RBTree *beachline;
    RBTree *circleEvents;
    
    CircleEvent *firstCircleEvent;
    
    CGRect boundingBox;
    
}

@property (retain, readwrite) CircleEvent *firstCircleEvent;

@property (assign, readwrite) CGRect boundingBox;

- (VoronoiResult *)computeWithSites:(NSArray *)siteList andBoundingBox:(CGRect)bbox;
- (void)reset;

- (Beachsection *)createBeachsection:(Site *)site;
- (void)addBeachsection:(Site *)site;
- (void)removeBeachsection:(Beachsection *)bs;
- (void)detachBeachsection:(Beachsection *)bs;

- (double)rightBreakPointWithArc:(Beachsection *)arc andDirectrix:(double)directrix;
- (double)leftBreakPointWithArc:(Beachsection *)arc andDirectrix:(double)directrix;

- (void)setEdgeStartPointWithEdge:(Edge *)tempEdge lSite:(Site *)tempLSite rSite:(Site *)tempRSite andVertex:(Vertex *)tempVertex;
- (void)setEdgeEndPointWithEdge:(Edge *)tempEdge lSite:(Site *)tempLSite rSite:(Site *)tempRSite andVertex:(Vertex *)tempVertex;

- (void)closeCells:(CGRect)bbox;

- (void)attachCircleEvent:(Beachsection *)arc;
- (void)detachCircleEvent:(Beachsection *)arc;

- (Edge *)edgeWithSite:(Site *)lSite andSite:(Site *)rSite;
- (Edge *)createEdgeWithSite:(Site *)lSite andSite:(Site *)rSite andVertex:(Vertex *)va andVertex:(Vertex *)vb;
- (Edge *)createBorderEdgeWithSite:(Site *)lSite andVertex:(Vertex *)va andVertex:(Vertex *)vb;

- (BOOL)connectEdge:(Edge *)edge withBoundingBox:(CGRect)bbox;
- (BOOL)clipEdge:(Edge *)edge withBoundingBox:(CGRect)bbox;
- (void)clipEdges:(CGRect)bbox;

#pragma mark Math methods
// Basic math methods handled by the class
+ (BOOL)equalWithEpsilonA:(double)a andB:(double)b;
+ (BOOL)greaterThanWithEpsilonA:(double)a andB:(double)b;
+ (BOOL)greaterThanOrEqualWithEpsilonA:(double)a andB:(double)b;
+ (BOOL)lessThanWithEpsilonA:(double)a andB:(double)b;
+ (BOOL)lessThanOrEqualWithEpsilonA:(double)a andB:(double)b;



@end
