//
//  Site.m
//  objcvoronoi
//

#import "Site.h"

@implementation Site
@synthesize voronoiId;

- (NSString *)description
{

    return [NSString stringWithFormat:@"(coord: %@, voronoiId: %i)", NSStringFromCGPoint(coord), voronoiId];
}

- (id)initWithCoord:(CGPoint)tempCoord
{
    self = [super init];
    if (self) {
        [self setCoord:tempCoord];
        _uuID = [NSUUID UUID];
    }
    return self;
}

- (id)initWithValue:(NSValue *)valueWithCoord
{
    self = [super init];
    if (self) {
        [self setCoord:[valueWithCoord CGPointValue]];
        _uuID = [NSUUID UUID];
    }
    return self;
}

- (id)init
{
    return [self initWithCoord:CGPointZero];
}

- (void)setCoord:(CGPoint)tempCoord
{
    coord = tempCoord;
}

- (CGPoint)coord
{
    return coord;
}

- (void)setCoordAsValue:(NSValue *)valueWithCoord
{
    coord = [valueWithCoord CGPointValue];
}

- (NSValue *)coordAsValue
{
    return [NSValue valueWithCGPoint:coord];
}

- (void)setX:(double)tempX
{
    [self setCoord:CGPointMake(tempX, coord.y)];
}

- (double)x
{
    return coord.x;
}

- (void)setY:(double)tempY
{
    [self setCoord:CGPointMake(coord.x, tempY)];
}

- (double)y
{
    return coord.y;
}

+ (void)sortSites:(NSMutableArray *)siteArray
{
    [siteArray sortUsingSelector:@selector(compare:)];
}

// TODO: Check that this is returning in the proper order;
- (NSComparisonResult)compare:(Site *)s
{
    if (self.y < s.y) return NSOrderedDescending;
    if (self.y > s.y) return NSOrderedAscending;
    if (self.x < s.x) return NSOrderedDescending;
    if (self.x > s.x) return NSOrderedAscending;
    
    return NSOrderedSame;
}

@end
