module Crystina
  # :nodoc:
  class RescueBlock < Node
    # :nodoc:
    record Clause, header : String, body : Sequence

    # :nodoc:
    def initialize(@header : String)
      @body = Sequence.new([] of Node)
      @clauses = Array(Clause).new
    end

    # :nodoc:
    def body=(seq : Sequence) : Nil
      @body = seq
    end

    # :nodoc:
    def add_clause(header : String, seq : Sequence) : Nil
      @clauses << Clause.new(header, seq)
    end

    # :nodoc:
    def render(io : IO, indent : Int32 = 0) : Nil
      spaces = "  " * indent
      io << spaces << @header << "\n"
      @body.render(io, indent + 1)
      @clauses.each do |clause|
        io << spaces << clause.header << "\n"
        clause.body.render(io, indent + 1)
      end
      io << spaces << "end\n"
    end
  end
end
