module Crystina
  # :nodoc:
  class CaseNode < Node
    @when_branches : Array({String, Sequence})
    @else_body : Sequence?

    # :nodoc:
    def initialize(@expr : String, @lhs : String? = nil)
      @when_branches = Array({String, Sequence}).new
      @else_body = nil
    end

    # :nodoc:
    def add_when(value : String, seq : Sequence) : Nil
      @when_branches << {value, seq}
    end

    # :nodoc:
    def else=(seq : Sequence) : Nil
      @else_body = seq
    end

    # :nodoc:
    def render(io : IO, indent : Int32 = 0) : Nil
      spaces = "  " * indent
      all_single = @when_branches.all? { |(_, body)| body.single_line }
      else_single = (eb = @else_body) ? !!eb.single_line : true

      io << spaces << (@lhs ? "#{@lhs} = case " : "case ") << @expr << "\n"

      if all_single && else_single
        max_val_len = @when_branches.max_of { |(val, _)| val.size }
        when_prefix = "when ".size + max_val_len + " then ".size
        @when_branches.each do |(val, body)|
          if sl = body.single_line
            io << spaces << "when " << val.ljust(max_val_len) << " then " << sl << "\n"
          end
        end
        if eb = @else_body
          if sl = eb.single_line
            io << spaces << "else" << " " * (when_prefix - "else".size) << sl << "\n"
          end
        end
      else
        @when_branches.each do |(val, body)|
          io << spaces << "when " << val << "\n"
          body.render(io, indent + 1)
        end
        if eb = @else_body
          io << spaces << "else\n"
          eb.render(io, indent + 1)
        end
      end

      io << spaces << "end\n"
    end
  end
end
