//
//  Vertex.m
//  objcvoronoi
//

#import "Vertex.h"
#import "Edge.h"

static int identifier = 0;

@implementation Vertex
@synthesize visited, target, distance, onBoundingBox, previousVertex;

- (id)initWithCoord:(CGPoint)tempCoord
{
    self = [super initWithCoord:tempCoord];
    if (self) {
        uniqueID = identifier;
        identifier++;
        [self setVisited:NO];
        [self setTarget:NO];
        [self setOnBoundingBox:NO];
        [self setDistance:INFINITY];
        edges = [[NSMutableArray alloc] init];
        neighborKeys = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithValue:(NSValue *)valueWithCoord
{
    self = [super initWithValue:valueWithCoord];
    if (self) {
        uniqueID = identifier;
        identifier++;
        [self setVisited:NO];
        [self setTarget:NO];
        [self setDistance:INFINITY];
        edges = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"uniqueID: %i, x: %f, y: %f",[self uniqueIDAsInt], [self x], [self y]];
}

- (NSString *)uniqueID
{
    return [NSString stringWithFormat:@"%i", uniqueID];
}

- (int)uniqueIDAsInt
{
    return uniqueID;
}

- (double)distanceToVertex:(Vertex *)v
{
    double x1 = [self coord].x;
    double y1 = [self coord].y;
    double x2 = [v    coord].x;
    double y2 = [v    coord].y;
    
    double a = fabs(x2 - x1);
    double b = fabs(y2 - y1);
    
    // Weight against borderbox vertices
    if ([v onBoundingBox]) {
        a = a*a;
        b = b*b;
    }
    
    return sqrtf(a*a + b*b);
}

- (void)addEdge:(Edge *)e
{
    if (![edges containsObject:e]) {
        [edges addObject:e];
    }
}

- (void)calcNeighborKeys
{
    // We know that this vertex is associated with each edge in the edges array
    // We have to figure out which vertex it is on each edge and then store the
    // uniqueID of the other vertex in 
    
    for (Edge *e in edges) {
        Vertex *otherVertex;
        if (self == [e va]) {
            otherVertex = [e vb];
        } else if (self == [e vb]) {
            otherVertex = [e va];
        }
        NSAssert(otherVertex != nil, @"Vertex: neighborKeys -- otherVertex is nil");
        [neighborKeys addObject:[otherVertex uniqueID]];
    }
}

- (NSMutableArray *)neighborKeys
{
    return neighborKeys;
}

@end
