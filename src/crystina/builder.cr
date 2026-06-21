module Crystina
  # Fluent builder for Crystal source code. All appender methods return `self` for chaining.
  # Obtain an instance via `Crystina.build`.
  class Builder
    def initialize
      @nodes = Array(Node).new
    end

    # :nodoc:
    def to_sequence : Sequence
      Sequence.new(@nodes.dup)
    end

    def to_s(io : IO) : Nil
      to_sequence.to_s(io)
    end

    # Appends a pre-built `Node` directly — useful when composing nodes outside the DSL.
    def node(n : Node) : self
      @nodes << n
      self
    end

    # Appends a blank line.
    def blank : self
      @nodes << Blank.new
      self
    end

    # Appends a raw source line (no `# ` prefix, no indentation adjustment beyond the current level).
    def line(text : String) : self
      @nodes << Line.new(text)
      self
    end

    # Appends a `# text` comment line. `wrap` controls word-wrapping: `:auto` (default) wraps
    # single-line text that exceeds the column limit, `true` always wraps, `false` never wraps.
    def comment(text : String, wrap : Bool | Symbol = :auto) : self
      @nodes << Comment.new(text, wrap)
      self
    end

    # Appends an `include Name` line.
    def mixin(name : String) : self
      @nodes << Line.new("include #{name}")
      self
    end

    # Appends a `require "path"` line.
    def req(path : String) : self
      @nodes << Line.new(%{require "#{path}"})
      self
    end

    # Appends a `getter name1, name2, …` line.
    def prop(*names) : self
      @nodes << Line.new("getter #{names.join(", ")}")
      self
    end

    # Appends an `alias Name = Target` line.
    def type_alias(name : String, target : String) : self
      @nodes << Line.new("alias #{name} = #{target}")
      self
    end

    # Appends an `@[Name]` or `@[Name(args)]` annotation line.
    def annotate(name : String, *args) : self
      if args.empty?
        @nodes << Line.new("@[#{name}]")
      else
        @nodes << Line.new("@[#{name}(#{args.join(", ")})]")
      end
      self
    end

    # Creates a `Param` — usable unqualified inside a build block.
    def param(name : String, type : String? = nil, default : String? = nil) : Param
      Param.new(name, type, default)
    end

    # Appends an empty `module Name … end` block (no body).
    def mod(name : String) : self
      @nodes << Block.new("module #{name}", Sequence.new([] of Node))
      self
    end

    # Appends a `module Name … end` block; yields the body builder with DSL methods unqualified.
    def mod(name : String | Symbol, &) : self
      child = Builder.new
      with child yield child
      @nodes << Block.new("module #{name}", child.to_sequence)
      self
    end

    # Appends an empty `class Name … end` block (no body).
    def klass(name : String) : self
      @nodes << Block.new("class #{name}", Sequence.new([] of Node))
      self
    end

    # Appends a `class Name … end` (or `abstract class`) block; yields the body builder with DSL methods unqualified.
    def klass(name : String | Symbol, abstract_class : Bool = false, &) : self
      prefix = abstract_class ? "abstract " : ""
      child = Builder.new
      with child yield child
      @nodes << Block.new("#{prefix}class #{name}", child.to_sequence)
      self
    end

    # Appends an empty `struct Name … end` block (no body).
    def struct_def(name : String) : self
      @nodes << Block.new("struct #{name}", Sequence.new([] of Node))
      self
    end

    # Appends a `struct Name … end` block; yields the body builder with DSL methods unqualified.
    def struct_def(name : String, &) : self
      child = Builder.new
      with child yield
      @nodes << Block.new("struct #{name}", child.to_sequence)
      self
    end

    # Appends an empty `def name(params) : ReturnType … end` using `Array(Param)` params.
    def def_method(name : String,
                   params : Array(Param) = [] of Param,
                   return_type : String? = nil) : self
      param_strs = params.map(&.to_s)
      @nodes << MethodDef.new(false, name, param_strs, return_type, Sequence.new([] of Node))
      self
    end

    # Appends a `def` block using `Array(Param)` params; yields the body builder with DSL methods unqualified.
    def def_method(name : String,
                   params : Array(Param) = [] of Param,
                   return_type : String? = nil, &) : self
      child = Builder.new
      with child yield
      param_strs = params.map(&.to_s)
      @nodes << MethodDef.new(false, name, param_strs, return_type, child.to_sequence)
      self
    end

    # Appends an `abstract def` line using `Array(Param)` params.
    def abstract_def(name : String,
                     params : Array(Param) = [] of Param,
                     return_type : String? = nil) : self
      param_strs = params.map(&.to_s)
      @nodes << MethodDef.new(true, name, param_strs, return_type, nil)
      self
    end

    # Appends an `abstract def` line using a `Hash` of param-name → type-string.
    def abstract_def(name : String | Symbol,
                     params : Hash(String, String),
                     return_type : String? = nil) : self
      param_strs = params.map { |k, v| "#{k} : #{v}" }
      @nodes << MethodDef.new(true, name.to_s, param_strs, return_type, nil)
      self
    end

    # Appends an empty `def` block using a `Hash` of param-name → type-string (no block variant).
    def def_method(name : String | Symbol,
                   params : Hash(String, String),
                   return_type : String? = nil) : self
      param_strs = params.map { |k, v| "#{k} : #{v}" }
      @nodes << MethodDef.new(false, name.to_s, param_strs, return_type, Sequence.new([] of Node))
      self
    end

    # Appends a `def` block using a `Hash` of param-name → type-string; block receives the body
    # builder as an explicit parameter (caller's `self` is not rebound).
    def def_method(name : String | Symbol,
                   params : Hash(String, String),
                   return_type : String? = nil,
                   &block : Builder ->) : self
      child = Builder.new
      block.call(child)
      param_strs = params.map { |k, v| "#{k} : #{v}" }
      @nodes << MethodDef.new(false, name.to_s, param_strs, return_type, child.to_sequence)
      self
    end

    # Appends an `if condition … end` block; yields the body builder with DSL methods unqualified.
    def if_block(condition : String, &) : self
      child = Builder.new
      with child yield
      @nodes << Block.new("if #{condition}", child.to_sequence)
      self
    end

    # Appends an `unless condition … end` block; yields the body builder with DSL methods unqualified.
    def unless_block(condition : String, &) : self
      child = Builder.new
      with child yield
      @nodes << Block.new("unless #{condition}", child.to_sequence)
      self
    end

    # Appends a `while condition … end` block; yields the body builder with DSL methods unqualified.
    def while_loop(condition : String, &) : self
      child = Builder.new
      with child yield
      @nodes << Block.new("while #{condition}", child.to_sequence)
      self
    end

    # Appends an `until condition … end` block; yields the body builder with DSL methods unqualified.
    def until_loop(condition : String, &) : self
      child = Builder.new
      with child yield
      @nodes << Block.new("until #{condition}", child.to_sequence)
      self
    end

    # Appends a multi-branch `if/elsif/else` node. The block receives an `IfNodeBuilder`
    # as an explicit parameter; call `ib.elsif(cond) {}` and `ib.else_clause {}` inside.
    def cond(condition : String, &block : IfNodeBuilder ->) : self
      node = IfNode.new(condition)
      @nodes << node
      ib = IfNodeBuilder.new(node)
      block.call(ib)
      ib.finalize
      self
    end

    # Appends a `case expr / when … / else … end` node. The block receives a `CaseNodeBuilder`
    # as an explicit parameter; call `cb.when(value) {}` and `cb.else_clause {}` inside.
    def case_when(expr : String, &block : CaseNodeBuilder ->) : self
      node = CaseNode.new(expr)
      @nodes << node
      cb = CaseNodeBuilder.new(node)
      block.call(cb)
      self
    end

    # Appends an arbitrary `header … footer` block; block receives the body builder as an
    # explicit parameter. Use this for constructs not covered by the typed helpers.
    def scope(header : String, footer : String = "end", &block : Builder ->) : self
      child = Builder.new
      block.call(child)
      @nodes << Block.new(header, child.to_sequence, footer)
      self
    end

    # Appends `target = method_expr(…)` where the block fills the argument list.
    def assign_call(target : String, method_expr : String, &block : Builder ->) : self
      scope("#{target} = #{method_expr}(", ")", &block)
    end

    # Appends a `begin … rescue … end` block. The block receives a `RescueBlockBuilder`
    # as an explicit parameter; call `rb.body {}` and `rb.rescue_clause(var, type) {}` inside.
    def rescue_block(header : String, &block : RescueBlockBuilder ->) : self
      node = RescueBlock.new(header)
      rb = RescueBlockBuilder.new(node)
      block.call(rb)
      @nodes << node
      self
    end

    # Appends a bare method call — `method arg1, arg2` (Symbol name: no parens).
    def method_call(method : Symbol, *args) : self
      parts = args.map(&.to_s)
      text = parts.empty? ? method.to_s : "#{method} #{parts.join(", ")}"
      @nodes << Line.new(text)
      self
    end

    # Appends a method call with parentheses — `method(arg1, arg2)` (String name).
    def method_call(method : String, *args, braces : Bool = true) : self
      parts = args.map(&.to_s)
      text = braces ? "#{method}(#{parts.join(", ")})" : "#{method} #{parts.join(", ")}"
      @nodes << Line.new(text)
      self
    end

    # Appends a method call from an array of argument strings.
    def method_call(method : String, args : Array(String), braces : Bool = true) : self
      text = braces ? "#{method}(#{args.join(", ")})" : "#{method} #{args.join(", ")}"
      @nodes << Line.new(text)
      self
    end

    # Appends a bare `#` comment line (blank comment separator).
    def blank_comment : self
      @nodes << Line.new("#")
      self
    end

    # Appends `raise expr`.
    def raise_ex(expr : String) : self
      @nodes << Line.new("raise #{expr}")
      self
    end

    # Appends `raise expr unless condition`.
    def raise_ex_unless(expr : String, condition : String) : self
      @nodes << Line.new("raise #{expr} unless #{condition}")
      self
    end

    # Appends `return` or `return expr`.
    def return_val(expr : String? = nil) : self
      if e = expr
        @nodes << Line.new("return #{e}")
      else
        @nodes << Line.new("return")
      end
      self
    end

    # Returns an `AssignmentBuilder` for `target = …`; chain a call or block to complete the assignment.
    def assign(target : String) : AssignmentBuilder
      AssignmentBuilder.new(self, target)
    end

    # Appends `target = expr`.
    def assign(target : String, expr : String) : self
      @nodes << Line.new("#{target} = #{expr}")
      self
    end

    # Appends `target = value.inspect` for Bool/Number literals.
    def assign(target : String, value : Bool | Number::Primitive) : self
      @nodes << Line.new("#{target} = #{value.inspect}")
      self
    end

    # Appends `target = rhs` where `rhs` is the single-line result of the block.
    def assign(target : String, &block : Builder ->) : self
      child = Builder.new
      block.call(child)
      rhs = child.to_sequence.single_line || raise "assign block must produce exactly one line"
      @nodes << Line.new("#{target} = #{rhs}")
      self
    end
  end
end
