module Crystina
  # Builder yielded inside `rescue_block {}` blocks. Call `body {}` for the guarded body
  # and `rescue_clause(var, type) {}` for each rescue handler.
  class RescueBlockBuilder
    # :nodoc:
    def initialize(@node : RescueBlock)
    end

    # Defines the guarded body; yields a builder with DSL methods unqualified.
    def body(&block : Builder ->) : self
      child = Builder.new
      block.call(child)
      @node.body = child.to_sequence
      self
    end

    # Adds a `rescue var : Type` clause; yields the handler body builder with DSL methods unqualified.
    def rescue_clause(var : Symbol, type : String, &block : Builder ->) : self
      child = Builder.new
      block.call(child)
      @node.add_clause("rescue #{var} : #{type}", child.to_sequence)
      self
    end
  end
end
