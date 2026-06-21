module Crystina
  # :nodoc:
  class Block < Node
    # :nodoc:
    def initialize(
      @header : String,
      @body : Sequence,
      @footer : String = "end",
    )
    end

    # :nodoc:
    def render(io : IO, indent : Int32 = 0) : Nil
      spaces = "  " * indent
      io << spaces << @header << "\n"
      @body.render(io, indent + 1)
      io << spaces << @footer << "\n"
    end
  end
end
