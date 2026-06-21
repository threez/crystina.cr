module Crystina
  # Builder yielded inside `cond {}` blocks. Provides `elsif` and `else_clause` to
  # build multi-branch `if/elsif/else` nodes. All `Builder` methods are available
  # unqualified inside each branch block.
  class IfNodeBuilder < Builder
    # :nodoc:
    def initialize(@node : IfNode)
      super()
    end

    # :nodoc:
    def finalize : Nil
      @node.then_body = to_sequence
    end

    # Adds an `elsif condition` branch; yields the branch body builder with DSL methods unqualified.
    def elsif(condition : String, &) : self
      child = Builder.new
      with child yield
      @node.add_elsif(condition, child.to_sequence)
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
