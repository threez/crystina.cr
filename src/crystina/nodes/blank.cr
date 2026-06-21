module Crystina
  # :nodoc:
  class Blank < Node
    # :nodoc:
    def render(io : IO, indent : Int32 = 0) : Nil
      io << "\n"
    end
  end
end
