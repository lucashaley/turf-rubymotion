//
//  ClayRelaxer.h
//  objcvoronoi
//


#import <Foundation/Foundation.h>

@class Cell;
@class Edge;
@class Halfedge;
@class Vertex;

@interface ClayRelaxer : NSObject {
    NSMutableArray *cells;
    NSMutableArray *newSites;
}

// Call this to use the relaxer.
+ (NSMutableArray *)relaxSitesInCells:(NSMutableArray *)cellArray;

- (id)initWithCells:(NSMutableArray *)cellArray;
- (void)processCells;
- (NSMutableArray *)newSites;

@end
