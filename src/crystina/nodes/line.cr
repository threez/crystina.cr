module Crystina
  # :nodoc:
  class Line < Node
    # :nodoc:
    getter text : String

    # :nodoc:
    def initialize(@text : String)
    end

    # :nodoc:
    def render(io : IO, indent : Int32 = 0) : Nil
      io << "  " * indent << @text << "\n"
    end
  end
end
