//
//  ClayPathMaker.h
//  objcvoronoi
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class Edge;
@class Vertex;

@interface ClayPathMaker : NSObject {
    NSMutableArray *solution;
    NSMutableArray *edges;
    NSMutableArray *newEdges;
    CGPoint startPoint;
    CGPoint endPoint;
    Vertex *startVertex;
    Vertex *endVertex;
    CGRect theBounds;
    NSMutableDictionary *vertices;
    
    NSMutableArray *pathNodes;
    
    NSMutableArray *points;
    
    int pathsToCalculate;
    
    BOOL workingOnFirstPath;
    BOOL workingOnLastPath;
}

@property (copy, readwrite) NSMutableArray *edges;
@property (retain, readwrite) NSMutableArray *points;
@property (assign, readwrite) CGPoint startPoint;
@property (assign, readwrite) CGPoint endPoint;
@property (retain, readwrite) Vertex *startVertex;
@property (retain, readwrite) Vertex *endVertex;
@property (assign, readwrite) CGRect theBounds;

+ (BOOL)equalWithEpsilonA:(double)a andB:(double)b;

- (id)initWithEdges:(NSMutableArray *)voronoiEdges nodesForPath:(NSMutableArray *)pointsArray andBounds:(CGRect)bbox;
- (NSMutableArray *)solution;
- (void)calculate;
- (double)distanceFromPoint:(CGPoint)pt toVertex:(Vertex *)dv;
- (BOOL)boundingBoxSharesEdgeWithVertex:(Vertex *)dv;
- (void)prepareData;
- (void)setStartAndEndForPathNum:(int)pathNum;
- (void)pathByClay;
- (NSMutableArray *)pathNodes;
- (Vertex *)vertexMatchingByPosition:(Vertex *)v;

@end