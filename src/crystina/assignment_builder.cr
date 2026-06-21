module Crystina
  # Returned by `Builder#assign(target)`. Chain one call to complete the assignment statement.
  class AssignmentBuilder
    # :nodoc:
    def initialize(@builder : Builder, @target : String)
    end

    # Completes the assignment as `target = method(args)` (Symbol: bare call, String: with parens).
    def method_call(method : Symbol, *args) : Builder
      parts = args.map(&.to_s)
      text = parts.empty? ? method.to_s : "#{method} #{parts.join(", ")}"
      @builder.line("#{@target} = #{text}")
    end

    # Completes the assignment as `target = method(args)`.
    def method_call(method : String, *args, braces : Bool = true) : Builder
      parts = args.map(&.to_s)
      text = braces ? "#{method}(#{parts.join(", ")})" : "#{method} #{parts.join(", ")}"
      @builder.line("#{@target} = #{text}")
    end

    # Completes the assignment as `target = method(args)` from an array.
    def method_call(method : String, args : Array(String), braces : Bool = true) : Builder
      text = braces ? "#{method}(#{args.join(", ")})" : "#{method} #{args.join(", ")}"
      @builder.line("#{@target} = #{text}")
    end

    # Completes the assignment as `target = header … end` where the block fills the body.
    def scope(header : String, footer : String = "end", &block : Builder ->) : Builder
      child = Builder.new
      block.call(child)
      @builder.node(Block.new("#{@target} = #{header}", child.to_sequence, footer))
      @builder
    end

    # Completes the assignment as `target = if condition … end`.
    def if_block(condition : String, &block : Builder ->) : Builder
      scope("if #{condition}", &block)
    end

    # Completes the assignment as `target = unless condition … end`.
    def unless_block(condition : String, &block : Builder ->) : Builder
      scope("unless #{condition}", &block)
    end

    # Completes the assignment as `target = case expr … end`.
    def case_when(expr : String, &block : CaseNodeBuilder ->) : Builder
      node = CaseNode.new(expr, @target)
      cb = CaseNodeBuilder.new(node)
      block.call(cb)
      @builder.node(node)
      @builder
    end
  end
end
