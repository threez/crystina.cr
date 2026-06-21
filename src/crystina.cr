require "./crystina/node"
require "./crystina/param"
require "./crystina/nodes/blank"
require "./crystina/nodes/line"
require "./crystina/nodes/comment"
require "./crystina/nodes/sequence"
require "./crystina/nodes/block"
require "./crystina/nodes/method_def"
require "./crystina/nodes/if_node"
require "./crystina/nodes/case_node"
require "./crystina/nodes/rescue_block"
require "./crystina/builder"
require "./crystina/if_node_builder"
require "./crystina/case_node_builder"
require "./crystina/rescue_block_builder"
require "./crystina/assignment_builder"

# Crystina — Crystal source-code builder DSL.
# Entry point: `Crystina.build`.
module Crystina
  VERSION  = "1.0.0"
  MAX_LINE = 80

  # Returns a fresh `Builder` for method chaining without a block.
  def self.build : Builder
    Builder.new
  end

  # Yields a fresh `Builder` with DSL methods available unqualified inside the block.
  def self.build(&) : Builder
    b = Builder.new
    with b yield
    b
  end

  # Creates a `Param` without qualifying the module — usable unqualified inside a build block.
  def self.param(name : String, type : String? = nil, default : String? = nil) : Param
    Param.new(name, type, default)
  end

  # Returns a `Block` node for a `module` definition — usable outside a builder context.
  def self.mod(name : String, &) : Block
    child = Builder.new
    with child yield
    Block.new("module #{name}", child.to_sequence)
  end

  # Returns a `Block` node for a `class` definition — usable outside a builder context.
  def self.klass(name : String, &) : Block
    child = Builder.new
    with child yield
    Block.new("class #{name}", child.to_sequence)
  end

  # Returns a `Block` node for a `struct` definition — usable outside a builder context.
  def self.struct_def(name : String, &) : Block
    child = Builder.new
    with child yield
    Block.new("struct #{name}", child.to_sequence)
  end

  # Returns a `MethodDef` node for a method definition — usable outside a builder context.
  def self.def_method(name : String,
                      params : Array(Param) = [] of Param,
                      return_type : String? = nil, &) : MethodDef
    param_strs = params.map(&.to_s)
    child = Builder.new
    with child yield
    MethodDef.new(false, name, param_strs, return_type, child.to_sequence)
  end
end
