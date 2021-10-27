//
//  Site.h
//  objcvoronoi
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Site : NSObject {
    CGPoint coord;
    int voronoiId;
}

@property (assign, readwrite) int voronoiId;
@property (nonatomic, strong) NSUUID *uuID;

- (id)initWithCoord:(CGPoint)tempCoord;
- (id)initWithValue:(NSValue *)valueWithCoord;

- (void)setCoord:(CGPoint)tempCoord;
- (CGPoint)coord;

- (void)setCoordAsValue:(NSValue *)valueWithCoord;
- (NSValue *)coordAsValue;

- (void)setX:(double)tempX;
- (double)x;

- (void)setY:(double)tempY;
- (double)y;

+ (void)sortSites:(NSMutableArray *)siteArray;
- (NSComparisonResult)compare:(Site *)s;

@end
