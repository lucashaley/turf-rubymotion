## Voronoi
### Properties
- firstCircleEvent:CircleEvent
- boundingBox:CGRect
- edges:Array
- cells:Array
### Functions
- computeWithSites
  - siteList: Array of Sites
  - andBoundingBox: CGRect
  - returns: VoronoiResult


## VoronoiResult
### Properties
- cells:Array
- edges:Array

## Site
### Properties
- coord:CGPoint
- voronoiId:int
### Functions
- initWithCoord
  - tempCoord:CGPoint
- sortSites
  - siteArray:Array of Sites

## Cell
### Properties
- site:Site
- halfedges:Array of Halfedges
### Functions
- initWithSite
  - site:Site

---

## VoronoiMap (BHEVoronoiMap)
### Properties
- pylons:Dictionary{uuID, Pylon}
### Functions
- voronoi_cells_from_pylons
  - in_pylons: Dictionary {uuID, Pylon}
  - returns: Array of Wakawakas

## Wakawaka (BHEVoronoiCell)
### Properties
- cell:Cell
- pylon:Pylon
