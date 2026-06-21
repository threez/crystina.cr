module Crystina
  # :nodoc:
  class Sequence < Node
    # :nodoc:
    def initialize(@nodes : Array(Node))
    end

    # :nodoc:
    def single_line : String?
      if @nodes.size == 1 && (n = @nodes[0]).is_a?(Line)
        n.text
      end
    end

    # :nodoc:
    def render(io : IO, indent : Int32 = 0) : Nil
      @nodes.each(&.render(io, indent))
    end
  end
end
