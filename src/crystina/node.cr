module Crystina
  # :nodoc:
  abstract class Node
    # :nodoc:
    abstract def render(io : IO, indent : Int32 = 0) : Nil

    def to_s(io : IO) : Nil
      render(io)
    end
  end
end
