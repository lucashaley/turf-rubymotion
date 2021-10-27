//
//  Vertex.h
//  objcvoronoi
//

// Most variations from Site are here to
// support working with Dijkstra's algorithm
// and are not necessary for Voronoi generation

#import "Site.h"

@class Edge;

@interface Vertex : Site {
    int uniqueID;
    double distance;
    BOOL visited;
    BOOL target;
    BOOL onBoundingBox;
    
    NSMutableArray *edges;
    NSMutableArray *neighborKeys;
    
    Vertex *previousVertex;
}

@property (assign, readwrite) BOOL visited;
@property (assign, readwrite) BOOL target;
@property (assign, readwrite) BOOL onBoundingBox;
@property (assign, readwrite) double distance;
@property (retain, readwrite) Vertex *previousVertex;

- (id)initWithCoord:(CGPoint)tempCoord;
- (id)initWithValue:(NSValue *)valueWithCoord;

- (NSString *)uniqueID;
- (int)uniqueIDAsInt;

- (double)distanceToVertex:(Vertex *)v;

- (void)addEdge:(Edge *)e;

- (void)calcNeighborKeys;
- (NSMutableArray *)neighborKeys;

@end
