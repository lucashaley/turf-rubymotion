#!/usr/bin/env ruby
#
#  ported from p bourke's triangulate.c
#  http://astronomy.swin.edu.au/~pbourke/terrain/triangulate/triangulate.c
#
#  C to Java:
#  fjenett, 20th february 2005, offenbach-germany.
#  contact: http://www.florianjenett.de/
#
#  Java to Ruby:
#  Gregory Seidman, 2006-11-28, Washington, DC, USA
#  contact: gmail account gseidman
#
#  to view the output: http://processing.org/
#
#  usage: (random vertices) ruby triangulate.rb [num vertices]
#         (benchmark)       ruby triangulate.rb bm
# http://paulbourke.net/papers/triangulate/

module Delaunay
  extend self
  ITRIANGLE = Struct.new(:p1, :p2, :p3, :complete)
  class IEDGE < Struct.new(:p1, :p2)
    def ==(o)
      (p1 == o.p1 && p2 == o.p2) || (p1 == o.p2 && p2 == o.p1)
    end

    def valid?
      p1 and p2
    end

    def reset!
      self.p1 = self.p2 = nil
    end
  end
  Coord = Struct.new(:x, :y)
  EPSILON = 0.000001

  # Triangulation subroutine
  # Takes as input vertices in array verts
  # Returned is a list of triangular faces in the array tris
  # These triangles are arranged in a consistent clockwise order.

  def triangulate(verts)
    edges = []
    tris = []

    # lucas
    centers = []

    # sort by X coord
    verts = verts.sort_by {|p|p.x}
    # center/radius cache used by circum_circle
    cc_cache = {}

    # Find the maximum and minimum vertex bounds.
    # This is to allow calculation of the bounding triangle
    xmin = verts[0].x
    ymin = verts[0].y
    xmax = xmin
    ymax = ymin
    verts.each { |p|
      xmin = p.x if (p.x < xmin)
      xmax = p.x if (p.x > xmax)
      ymin = p.y if (p.y < ymin)
      ymax = p.y if (p.y > ymax)
    }
    dx = xmax - xmin
    dy = ymax - ymin
    dmax = (dx > dy) ? dx : dy
    xmid = (xmax + xmin) / 2.0
    ymid = (ymax + ymin) / 2.0

    # Set up the supertriangle
    # This is a triangle which encompasses all the sample points.
    # The supertriangle coordinates are added to the end of the
    # vertex list. The supertriangle is the first triangle in
    # the triangle list.
    nv = verts.size
    verts << Coord.new(xmid - 2.0 * dmax, ymid - dmax)
    verts << Coord.new(xmid, ymid + 2.0 * dmax)
    verts << Coord.new(xmid + 2.0 * dmax, ymid - dmax)
    tris << ITRIANGLE.new(nv, nv+1, nv+2)


    # Include each point one at a time into the existing mesh
    (0...verts.size).each { |i|
      p = verts[i]
      edges.clear

      # Set up the edge buffer.
      # If the point (xp,yp) lies inside the circumcircle then the
      # three edges of that triangle are added to the edge buffer
      # and that triangle is removed.
      j = 0
      while j < tris.size
        unless tris[j].complete
          p1 = verts[tris[j].p1]
          p2 = verts[tris[j].p2]
          p3 = verts[tris[j].p3]
          inside,xc,yc,r = circum_circle(p, p1, p2, p3, cc_cache)

          # lucas
          # puts "circum_circle: #{inside}, #{xc}, #{yc}, #{r}"
          centers << Coord.new(xc, yc) unless inside

          if (xc + r) < p.x
            tris[j].complete = true
          end
          if inside
            edges << IEDGE.new(tris[j].p1, tris[j].p2)
            edges << IEDGE.new(tris[j].p2, tris[j].p3)
            edges << IEDGE.new(tris[j].p3, tris[j].p1)
            tri = tris.pop
            tris[j] = tri unless j >= tris.size
            j -= 1
          end
        end
        j += 1
      end #while j

      # Tag multiple edges
      # Note: if all triangles are specified anticlockwise then all
      # interior edges are opposite pointing in direction.
      j = 0
      while j < edges.size - 1
        k = j+1
        while k < edges.size
          if (edges[j] == edges[k])
            edges[j].reset!
            edges[k].reset!
          end
          k += 1
        end #while k
        j += 1
      end #while j

      # Form new triangles for the current point
      # Skipping over any tagged edges.
      # All edges are arranged in clockwise order.
      j = 0
      while j < edges.size
        tris << ITRIANGLE.new(edges[j].p1, edges[j].p2, i) if edges[j].valid?
        j += 1
      end #while j
    } #each i

    # Remove supertriangle vertices
    verts[-3..-1] = nil
    nv = verts.size

    # Remove triangles with supertriangle vertices
    # These are triangles which have a vertex number greater than nv
    i = 0
    while i < tris.size
      if (tris[i].p1 >= nv ||
          tris[i].p2 >= nv ||
          tris[i].p3 >= nv)
        tri = tris.pop
        tris[i] = tri unless i >= tris.size
        i -= 1
      end
      i += 1
    end #while i

    # lucas
    # puts centers

    [ verts, tris, centers ]
  end #triangulate

  private

  # Return TRUE if a point p is inside the circumcircle made up of the
  # points p1, p2, p3
  # The circumcircle center is returned in (xc,yc) and the radius r
  # The return value is an array [ inside, xc, yc, r ]
  # Takes an optional cache hash to use for radius/center caching
  # NOTE: A point on the edge is inside the circumcircle
  def circum_circle(p, p1, p2, p3, cache = nil)
    dx,dy,rsqr,drsqr = []
    cached = cache && cache[[p1, p2, p3]]
    xc, yc, r = []
    rsqr = 0

    if cached
      xc, yc, r = cached
      rsqr = r*r
    else
      # Check for coincident points
      if (p1.y-p2.y).abs < EPSILON && (p2.y-p3.y).abs < EPSILON
#        puts("CircumCircle: Points are coincident.")
        return [ false, 0, 0, 0 ]
      end

      if (p2.y-p1.y).abs < EPSILON
        m2 = - (p3.x-p2.x) / (p3.y-p2.y)
        mx2 = (p2.x + p3.x) * 0.5
        my2 = (p2.y + p3.y) * 0.5
        xc = (p2.x + p1.x) * 0.5
        yc = m2 * (xc - mx2) + my2
      elsif (p3.y-p2.y).abs < EPSILON
        m1 = - (p2.x-p1.x) / (p2.y-p1.y)
        mx1 = (p1.x + p2.x) * 0.5
        my1 = (p1.y + p2.y) * 0.5
        xc = (p3.x + p2.x) * 0.5
        yc = m1 * (xc - mx1) + my1
      else
        m1 = - (p2.x-p1.x) / (p2.y-p1.y)
        m2 = - (p3.x-p2.x) / (p3.y-p2.y)
        mx1 = (p1.x + p2.x) * 0.5
        mx2 = (p2.x + p3.x) * 0.5
        my1 = (p1.y + p2.y) * 0.5
        my2 = (p2.y + p3.y) * 0.5
        xc = (m1 * mx1 - m2 * mx2 + my2 - my1) / (m1 - m2)
        yc = m1 * (xc - mx1) + my1
      end

      dx = p2.x - xc
      dy = p2.y - yc
      rsqr = dx*dx + dy*dy
      r = Math.sqrt(rsqr)
      cache[[p1, p2, p3]] = [ xc, yc, r ] if cache
    end

    dx = p.x - xc
    dy = p.y - yc
    drsqr = dx*dx + dy*dy

    [ (drsqr <= rsqr), xc, yc, r ]
  end #circum_circle

end #Delaunay

if __FILE__ == $PROGRAM_NAME
  require 'benchmark'

  def main
    if ARGV[0] == 'bm'
      bm
    else
      nv = ARGV[0].to_i
      nv = 20 if (nv <= 0 || nv > 1000)
      Delaunay.output_random(nv)
    end
  end

  def bm
    Benchmark.bm(5) { |b|
      (1..10).each { |i| i *= 100
        b.report("#{i}\t") { 10.times { Delaunay.run_random(i) } }
      }
    }
  end

  module Delaunay

    def run_random(nv)
      points = (0...nv).map { |i| Coord.new(i*4.0, 400.0 * rand) }
      triangulate(points)
    end

    def output(points, tris)
      puts "void setup() { size(800, 800); }\nvoid draw() {"

      puts "\tscale(2);\n\tstrokeWeight(0.5);\n\tnoFill();\n\tbeginShape(TRIANGLES);"
      puts tris.map{ |t|
        tri_verts = [ points[t.p1],points[t.p2],points[t.p3] ]
        tri_verts.map! { |p| "\tvertex(#{p.x}, #{p.y});" }
      }.flatten!.join("\n")
      puts "\tendShape();\n\trectMode(CENTER);\n\tfill(0);"
      puts points.map{ |p| "\trect(#{p.x}, #{p.y}, 3, 3);" }.join("\n")
      puts "}"
    end

    def output_random(nv)
      output(*run_random(nv))
    end

  end

  main
end
