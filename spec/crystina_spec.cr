require "./spec_helper"

private alias C = Crystina

describe Crystina do
  describe "Blank" do
    it "renders an empty line" do
      C::Blank.new.to_s.should eq("\n")
    end

    it "ignores indent" do
      io = IO::Memory.new
      C::Blank.new.render(io, 3)
      io.to_s.should eq("\n")
    end
  end

  describe "Line" do
    it "renders text at indent 0" do
      C::Line.new("foo").to_s.should eq("foo\n")
    end

    it "renders indented text at indent 2" do
      io = IO::Memory.new
      C::Line.new("foo").render(io, 2)
      io.to_s.should eq("    foo\n")
    end
  end

  describe "Comment" do
    it "renders a comment at indent 0" do
      C::Comment.new("hello").to_s.should eq("# hello\n")
    end

    it "renders indented comment at indent 1" do
      io = IO::Memory.new
      C::Comment.new("hello").render(io, 1)
      io.to_s.should eq("  # hello\n")
    end
  end

  describe "Sequence" do
    it "renders children in order" do
      seq = C::Sequence.new([C::Line.new("a"), C::Line.new("b")] of C::Node)
      seq.to_s.should eq("a\nb\n")
    end

    it "renders empty sequence as empty string" do
      C::Sequence.new([] of C::Node).to_s.should eq("")
    end
  end

  describe "Block" do
    it "renders header, indented body, and end footer" do
      block = C::Block.new("module Foo", C::Sequence.new([C::Line.new("x = 1")] of C::Node))
      block.to_s.should eq("module Foo\n  x = 1\nend\n")
    end

    it "supports a custom footer" do
      block = C::Block.new("if true", C::Sequence.new([] of C::Node), "end # if")
      block.to_s.should eq("if true\nend # if\n")
    end

    it "increments indent for nested blocks" do
      inner = C::Block.new("class Bar", C::Sequence.new([C::Line.new("x = 1")] of C::Node))
      outer = C::Block.new("module Foo", C::Sequence.new([inner] of C::Node))
      outer.to_s.should eq("module Foo\n  class Bar\n    x = 1\n  end\nend\n")
    end
  end

  describe "Param" do
    it "renders name only" do
      C::Param.new("x").to_s.should eq("x")
    end

    it "renders name and type" do
      C::Param.new("x", "String").to_s.should eq("x : String")
    end

    it "renders name, type, and default" do
      C::Param.new("count", "Int32", "0").to_s.should eq("count : Int32 = 0")
    end

    it "renders name and default without type" do
      C::Param.new("x", nil, "42").to_s.should eq("x = 42")
    end
  end

  describe "Builder#node" do
    it "appends a pre-built node" do
      b = C::Builder.new
      b.node(C::Line.new("x = 1"))
      b.node(C::Blank.new)
      b.node(C::Line.new("y = 2"))
      b.to_s.should eq("x = 1\n\ny = 2\n")
    end

    it "appends a Block node at correct indent" do
      b = C::Builder.new
      b.node(C::Block.new("module Foo", C::Sequence.new([C::Line.new("x")] of C::Node)))
      b.to_s.should eq("module Foo\n  x\nend\n")
    end
  end

  describe "Builder — leaf methods" do
    it "blank appends an empty line" do
      C.build { blank }.to_s.should eq("\n")
    end

    it "line appends a line" do
      C.build { line "hello" }.to_s.should eq("hello\n")
    end

    it "comment appends a comment" do
      C.build { comment "note" }.to_s.should eq("# note\n")
    end

    it "mixin appends an include directive" do
      C.build { mixin "JSON::Serializable" }.to_s
        .should eq("include JSON::Serializable\n")
    end

    it "req appends a require directive" do
      C.build { req "json" }.to_s.should eq("require \"json\"\n")
    end

    it "prop with one name" do
      C.build { prop "name" }.to_s.should eq("getter name\n")
    end

    it "prop with multiple names" do
      C.build { prop "name", "age" }.to_s.should eq("getter name, age\n")
    end

    it "type_alias appends an alias line" do
      C.build { type_alias "MyStr", "String" }.to_s.should eq("alias MyStr = String\n")
    end

    it "annotate with no args" do
      C.build { annotate "JSON::Field" }.to_s.should eq("@[JSON::Field]\n")
    end

    it "annotate with args" do
      C.build { annotate "JSON::Field", "key: \"name\"" }.to_s
        .should eq("@[JSON::Field(key: \"name\")]\n")
    end
  end

  describe "Builder — chaining" do
    it "chains multiple leaf calls" do
      C.build.line("a").blank.line("b").to_s.should eq("a\n\nb\n")
    end

    it "chains req and blank" do
      C.build.req("json").blank.to_s.should eq("require \"json\"\n\n")
    end
  end

  describe "Builder — block DSL" do
    it "mod with block" do
      C.build { mod("Foo") { line "x = 1" } }.to_s
        .should eq("module Foo\n  x = 1\nend\n")
    end

    it "mod without block (empty body)" do
      C.build { mod("Foo") }.to_s.should eq("module Foo\nend\n")
    end

    it "klass with block" do
      C.build { klass("Bar") { line "x = 1" } }.to_s
        .should eq("class Bar\n  x = 1\nend\n")
    end

    it "klass without block" do
      C.build { klass("Bar") }.to_s.should eq("class Bar\nend\n")
    end

    it "struct_def with block" do
      C.build { struct_def("Point") { prop "x", "y" } }.to_s
        .should eq("struct Point\n  getter x, y\nend\n")
    end

    it "def_method with no params or return type" do
      C.build { def_method("foo") { line "x" } }.to_s
        .should eq("def foo\n  x\nend\n")
    end

    it "def_method with no block (empty body)" do
      C.build { def_method("foo") }.to_s.should eq("def foo\nend\n")
    end

    it "def_method with params" do
      C.build do
        def_method("greet", [param("name", "String"), param("age", "Int32")]) do
          line "name + age.to_s"
        end
      end.to_s.should eq("def greet(name : String, age : Int32)\n  name + age.to_s\nend\n")
    end

    it "def_method with return type" do
      C.build { def_method("size", [] of C::Param, "Int32") { line "@items.size" } }.to_s
        .should eq("def size : Int32\n  @items.size\nend\n")
    end

    it "abstract_def generates a single line without end" do
      C.build { abstract_def("call", [param("ctx", "Context")], "Nil") }.to_s
        .should eq("abstract def call(ctx : Context) : Nil\n")
    end

    it "param helper is available inside build block" do
      p = C.build { }.param("x", "Int32")
      p.to_s.should eq("x : Int32")
    end

    it "nested mod > klass > def_method" do
      C.build do
        mod("Foo") do
          klass("Bar") do
            def_method("baz") { line "42" }
          end
        end
      end.to_s.should eq("module Foo\n  class Bar\n    def baz\n      42\n    end\n  end\nend\n")
    end
  end

  describe "free functions" do
    it "Crystina.mod returns a Block node" do
      node = C.mod("Foo") { line "x" }
      node.class.should eq(C::Block)
      node.to_s.should eq("module Foo\n  x\nend\n")
    end

    it "Crystina.klass returns a Block node" do
      C.klass("Bar") { }.class.should eq(C::Block)
    end

    it "Crystina.struct_def returns a Block node" do
      C.struct_def("Point") { }.class.should eq(C::Block)
    end

    it "Crystina.def_method returns a MethodDef node" do
      C.def_method("foo") { }.class.should eq(C::MethodDef)
    end

    it "Crystina.param returns a Param" do
      C.param("x", "String").to_s.should eq("x : String")
    end
  end

  describe "Builder — control flow" do
    it "if_block" do
      C.build { if_block("x > 0") { line "ok" } }.to_s
        .should eq("if x > 0\n  ok\nend\n")
    end

    it "unless_block" do
      C.build { unless_block("x.nil?") { line "ok" } }.to_s
        .should eq("unless x.nil?\n  ok\nend\n")
    end

    it "while_loop" do
      C.build { while_loop("running") { line "tick" } }.to_s
        .should eq("while running\n  tick\nend\n")
    end

    it "until_loop" do
      C.build { until_loop("done") { line "wait" } }.to_s
        .should eq("until done\n  wait\nend\n")
    end

    it "cond — if only" do
      C.build { cond("x > 0", &.line("ok")) }.to_s
        .should eq("if x > 0\n  ok\nend\n")
    end

    it "cond — if/else" do
      C.build do
        cond("x > 0") do |if_bldr|
          if_bldr.line "positive"
          if_bldr.else_clause { line "not positive" }
        end
      end.to_s.should eq("if x > 0\n  positive\nelse\n  not positive\nend\n")
    end

    it "cond — if/elsif/else" do
      C.build do
        cond("x > 0") do |if_bldr|
          if_bldr.line "positive"
          if_bldr.elsif("x == 0") { line "zero" }
          if_bldr.else_clause { line "negative" }
        end
      end.to_s.should eq(
        "if x > 0\n  positive\nelsif x == 0\n  zero\nelse\n  negative\nend\n"
      )
    end

    it "cond — multiple elsif" do
      C.build do
        cond("x == 1") do |if_bldr|
          if_bldr.line "one"
          if_bldr.elsif("x == 2") { line "two" }
          if_bldr.elsif("x == 3") { line "three" }
        end
      end.to_s.should eq(
        "if x == 1\n  one\nelsif x == 2\n  two\nelsif x == 3\n  three\nend\n"
      )
    end

    it "cond nested inside mod" do
      C.build do
        mod("Foo") do
          def_method("sign", [param("x", "Int32")], "String") do
            cond("x > 0") do |if_bldr|
              if_bldr.return_val %{"positive"}
              if_bldr.else_clause { return_val %{"non-positive"} }
            end
          end
        end
      end.to_s.should eq(
        "module Foo\n  def sign(x : Int32) : String\n" \
        "    if x > 0\n      return \"positive\"\n    else\n      return \"non-positive\"\n    end\n  end\nend\n"
      )
    end

    it "case_when — with branches" do
      C.build do
        case_when("value") do |case_bldr|
          case_bldr.when(%("a")) { line "1" }
          case_bldr.when(%("b")) { line "2" }
        end
      end.to_s.should eq("case value\nwhen \"a\" then 1\nwhen \"b\" then 2\nend\n")
    end

    it "case_when — with else" do
      C.build do
        case_when("value") do |case_bldr|
          case_bldr.when(%("a")) { line "1" }
          case_bldr.else_clause { line "0" }
        end
      end.to_s.should eq("case value\nwhen \"a\" then 1\nelse          0\nend\n")
    end

    it "case_when nested indentation" do
      C.build do
        mod("Foo") do
          case_when("x") do |case_bldr|
            case_bldr.when("1") { line "y" }
          end
        end
      end.to_s.should eq("module Foo\n  case x\n  when 1 then y\n  end\nend\n")
    end
  end

  describe "Builder — simple statements" do
    it "raise_ex" do
      C.build { raise_ex "ArgumentError.new" }.to_s
        .should eq("raise ArgumentError.new\n")
    end

    it "return_val with no argument" do
      C.build { return_val }.to_s.should eq("return\n")
    end

    it "return_val with expression" do
      C.build { return_val "42" }.to_s.should eq("return 42\n")
    end

    it "assign" do
      C.build { assign "@name", "name" }.to_s.should eq("@name = name\n")
    end

    it "raise_ex inside if_block" do
      C.build do
        if_block("x.nil?") { raise_ex "ArgumentError.new(\"x is nil\")" }
      end.to_s.should eq("if x.nil?\n  raise ArgumentError.new(\"x is nil\")\nend\n")
    end
  end

  describe "Builder — def_method with hash params" do
    it "no-body version renders param as name : type" do
      C::Builder.new.def_method("initialize", {"@http" => "HTTP::Client"}).to_s
        .should eq("def initialize(@http : HTTP::Client)\nend\n")
    end

    it "explicit-yield version builds body" do
      b = C::Builder.new
      b.def_method("list", {"limit" => "Int32? = nil"}, "Array(Pet)") { |meth| meth.line "[]" }
      b.to_s.should eq("def list(limit : Int32? = nil) : Array(Pet)\n  []\nend\n")
    end

    it "symbol name is accepted" do
      C::Builder.new.def_method(:foo, {} of String => String, "Nil").to_s
        .should eq("def foo : Nil\nend\n")
    end

    it "multiple params joined with commas" do
      C::Builder.new.def_method("greet", {"name" => "String", "age" => "Int32"}).to_s
        .should eq("def greet(name : String, age : Int32)\nend\n")
    end
  end

  describe "Builder — scope / assign_call" do
    it "scope renders header, indented body, and end footer" do
      C.build.scope("module Foo", &.line("x = 1")).to_s
        .should eq("module Foo\n  x = 1\nend\n")
    end

    it "scope with custom footer" do
      C.build.scope("query = HTTP::Params.build do |p|", "end") { |bldr|
        bldr.line "p.add(\"limit\", limit.to_s)"
      }.to_s.should eq("query = HTTP::Params.build do |p|\n  p.add(\"limit\", limit.to_s)\nend\n")
    end

    it "assign_call renders target = method(\n  args\n)" do
      C.build.assign_call("result", "foo") { |asgn|
        asgn.line "arg1,"
        asgn.line "arg2,"
      }.to_s.should eq("result = foo(\n  arg1,\n  arg2,\n)\n")
    end

    it "assign_call nested inside scope" do
      C.build.scope("def post") { |bldr|
        bldr.assign_call("response", "@http.post") { |asgn|
          asgn.line "\"/path\","
          asgn.line "body: x,"
        }
      }.to_s.should eq(
        "def post\n  response = @http.post(\n    \"/path\",\n    body: x,\n  )\nend\n"
      )
    end
  end

  describe "round-trip" do
    it "builds a module with class and method" do
      result = C.build do
        mod("Petstore") do
          klass("Client") do
            def_method("initialize") { line %{@base_url = "http://localhost"} }
          end
        end
      end.to_s

      expected = "module Petstore\n" \
                 "  class Client\n" \
                 "    def initialize\n" \
                 "      @base_url = \"http://localhost\"\n" \
                 "    end\n" \
                 "  end\n" \
                 "end\n"

      result.should eq(expected)
    end

    it "builds a file preamble with chaining" do
      result = C.build
        .req("json")
        .req("yaml")
        .blank
        .comment("Generated by cryogen — do not edit")
        .to_s

      result.should eq(
        "require \"json\"\n" \
        "require \"yaml\"\n" \
        "\n" \
        "# Generated by cryogen — do not edit\n"
      )
    end
  end
end
