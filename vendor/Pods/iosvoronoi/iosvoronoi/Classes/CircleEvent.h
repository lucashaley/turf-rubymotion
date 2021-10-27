//
//  CircleEvent.h
//  objcvoronoi
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class Beachsection;
@class Site;

@interface CircleEvent : NSObject {
    CircleEvent *rbNext;
    CircleEvent *rbPrevious;
    CircleEvent *rbParent;
    CircleEvent *rbRight;
    CircleEvent *rbLeft;
    BOOL rbRed;
    
    CGPoint coord;
    
    Beachsection *arc;
    Site *site;
    double ycenter;
}

@property (retain, readwrite)CircleEvent *rbNext;
@property (retain, readwrite)CircleEvent *rbPrevious;
@property (retain, readwrite)CircleEvent *rbParent;
@property (retain, readwrite)CircleEvent *rbRight;
@property (retain, readwrite)CircleEvent *rbLeft;
@property (assign, readwrite) BOOL rbRed;


@property (assign, readwrite)CGPoint coord;

@property (retain, readwrite)Beachsection *arc;

// TODO: Look for uses of circle event coord and determine whether it should be site.
@property (retain, readwrite)Site *site;

@property (assign, readwrite)double ycenter;

- (void)setCoord:(CGPoint)tempCoord;
- (CGPoint)coord;

- (void)setCoordAsValue:(NSValue *)valueWithCoord;
- (NSValue *)coordAsValue;

- (void)setX:(double)tempX;
- (double)x;

- (void)setY:(double)tempY;
- (double)y;

@end
