module Crystina
  # :nodoc:
  class IfNode < Node
    @branches : Array({String, Sequence})
    @else_body : Sequence?

    # :nodoc:
    def initialize(condition : String)
      @branches = Array({String, Sequence}).new
      @branches << {condition, Sequence.new([] of Node)}
      @else_body = nil
    end

    # :nodoc:
    def then_body=(seq : Sequence) : Nil
      @branches[0] = {@branches[0][0], seq}
    end

    # :nodoc:
    def add_elsif(condition : String, seq : Sequence) : Nil
      @branches << {condition, seq}
    end

    # :nodoc:
    def else=(seq : Sequence) : Nil
      @else_body = seq
    end

    # :nodoc:
    def render(io : IO, indent : Int32 = 0) : Nil
      spaces = "  " * indent
      @branches.each_with_index do |(cond, body), i|
        keyword = i == 0 ? "if" : "elsif"
        io << spaces << keyword << " " << cond << "\n"
        body.render(io, indent + 1)
      end
      if eb = @else_body
        io << spaces << "else\n"
        eb.render(io, indent + 1)
      end
      io << spaces << "end\n"
    end
  end
end
