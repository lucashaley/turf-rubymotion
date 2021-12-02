# class Cell
#   attr_accessor :site,
#                 :halfedges
#
#   DEBUGGING = true
#
#   def initialize(in_site)
#     puts "CELL INITIALIZE".green if DEBUGGING
#     @site = in_site
#     @halfedges = []
#   end
#
#   def prepare
#     puts "CELL PREPARE".blue if DEBUGGING
#     @halfedges.reverse.each_with_index do | halfedge, index |
#       edge = halfedge.edge
#       if !edge.vertex_b || !edge.vertex_a
#         @halfedges.delete_at(index)
#       end
#     end
#
#     in_halfedge.sort_array_of_halfedges(@halfedges)
#
#     @halfedges.length
#   end
#
#   def add_halfedge_to_array(in_halfedge)
#     puts "CELL ADD_HALFEDGE_TO_ARRAY".blue if DEBUGGING
#     @halfedges << in_halfedge
#   end
# end
