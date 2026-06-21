module Crystina
  # Builder yielded inside `case_when {}` blocks. Provides `when` and `else_clause` to
  # build `case/when/else` nodes. Inside each branch block, DSL methods are available unqualified.
  class CaseNodeBuilder
    # :nodoc:
    def initialize(@node : CaseNode)
    end

    # Adds a `when value` branch; yields the branch body builder with DSL methods unqualified.
    def when(value : String, &) : self
      child = Builder.new
      with child yield
      @node.add_when(value, child.to_sequence)
      self
    end

    # Adds the `else` branch; yields the branch body builder with DSL methods unqualified.
    def else_clause(&) : self
      child = Builder.new
      with child yield
      @node.else = child.to_sequence
      self
    end
  end
end
