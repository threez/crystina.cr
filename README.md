# crystina

A fluent DSL for generating Crystal source code.

Instead of building strings or wrestling with templates, crystina gives you a
chainable builder API that handles indentation, keywords, and formatting
automatically. Every appender method returns `self`, so calls chain naturally.

## Background

crystina is inspired by [jennifer](https://github.com/dave/jennifer), Dave
Brophy's code generation library for Go. jennifer's name is a play on "Go" +
"Jennifer" — a name that starts with the letter J. crystina follows the same
pattern: **Crys**tal + Chris**tina**.

## Installation

Add to your `shard.yml`:

```yaml
dependencies:
  crystina:
    github: threez/crystina
    version: ~> 1.0
```

## Quick start

```crystal
require "crystina"

C = Crystina

src = C.build do
  req "http"
  blank
  comment "Generated — do not edit by hand"
  blank
  mod "Pets" do
    klass "Client" do
      def_method "initialize", [param("@http", "HTTP::Client")]
      blank
      def_method "list", [param("limit", "Int32?", "nil")], "Array(String)" do
        return_val "[] of String"
      end
    end
  end
end

puts src
```

Output:

```crystal
require "http"

# Generated — do not edit by hand

module Pets
  class Client
    def initialize(@http : HTTP::Client)
    end

    def list(limit : Int32? = nil) : Array(String)
      return [] of String
    end
  end
end
```

## Entry point

`Crystina.build` has two forms:

```crystal
# Block form — DSL methods available unqualified inside the block
src = Crystina.build { req "json"; blank; line "# hello" }

# Chain form — returns a bare Builder for method chaining
src = Crystina.build.req("json").blank.line("# hello")
```

## Params

`param(name, type?, default?)` creates a `Param` for use with method
definitions. The `@` prefix on a name produces an ivar-initialising parameter.

```crystal
param("x")                      # x
param("x", "Int32")             # x : Int32
param("x", "Int32", "0")        # x : Int32 = 0
param("count", nil, "0")        # count = 0
param("@http", "HTTP::Client")  # @http : HTTP::Client
```

`param` is available both as `Crystina.param(...)` and unqualified inside a
`build` block.

## Leaf methods

These produce a single line and return `self`.

```crystal
line "x = 1"                                    # x = 1
blank                                           # (empty line)
comment "some text"                             # # some text
comment "a very long line of text", wrap: true  # wrapped at 80 cols
blank_comment                                   # #
req "json"                                      # require "json"
mixin "Comparable"                              # include Comparable
prop :name, :age                                # getter name, age
type_alias "Id", "Int64"                        # alias Id = Int64
annotate "JSON::Serializable"                   # @[JSON::Serializable]
annotate "DB::Field", "key: \"id\""             # @[DB::Field(key: "id")]
raise_ex "ArgumentError.new"                    # raise ArgumentError.new
raise_ex_unless "ArgumentError.new", "x"        # raise ArgumentError.new unless x
return_val                                      # return
return_val "result"                             # return result
```

## Block containers

These yield a child builder with DSL methods available unqualified:

```crystal
mod "Animals" do     # module Animals
  klass "Dog" do     #   class Dog
    line "# ..."     #     # ...
  end                #   end
end                  # end

struct_def "Point" do ... end
klass "Base", abstract_class: true do ... end

if_block "x.nil?" do raise_ex "ArgumentError.new" end
unless_block "ready?" do raise_ex "NotReadyError.new" end
while_loop "queue.any?" do line "queue.shift" end
until_loop "done?" do line "tick" end
```

For constructs not covered by the typed helpers, `scope` accepts any header and
an optional footer (defaults to `"end"`):

```crystal
scope "query = HTTP::Params.build do |p|", "end" do |bldr|
  bldr.line "p.add(\"limit\", limit.to_s)"
end
# query = HTTP::Params.build do |p|
#   p.add("limit", limit.to_s)
# end
```

## Method definitions

The Array(Param) form yields the body builder with DSL methods unqualified:

```crystal
def_method "greet", [param("name", "String")], "String" do
  return_val %("Hello, " + name)
end
# def greet(name : String) : String
#   return "Hello, " + name
# end
```

Omit the block to produce an empty body:

```crystal
def_method "initialize", [param("@name", "String")]
# def initialize(@name : String)
# end
```

The Hash form is handy when building param lists dynamically. It passes the body
builder as an explicit block argument rather than rebinding `self`:

```crystal
def_method "list", {"limit" => "Int32? = nil"}, "Array(Pet)" do |meth|
  meth.line "[]"
end
```

For long parameter lists that exceed 80 characters, crystina automatically
breaks them onto separate lines.

`abstract_def` produces a single-line abstract signature with no body:

```crystal
abstract_def "call", [param("ctx", "Context")], "Nil"
# abstract def call(ctx : Context) : Nil
```

## Assignments

Three overloads cover the common cases:

```crystal
assign "@name", "name"          # @name = name
assign "@count", 0              # @count = 0
assign("result") { line "42" }  # result = 42  (block must be single-line)
```

`assign(target)` returns an `AssignmentBuilder` for richer right-hand sides:

```crystal
assign("value").method_call("parse", "input")
# value = parse(input)

assign("value").method_call(:parse, "input")
# value = parse input   (Symbol → bare call, no parens)

assign("status").if_block("ok?") { line "\"ready\"" }
# status = if ok?
#   "ready"
# end
```

`assign_call` is shorthand for `target = method(\n  args\n)`:

```crystal
assign_call "response", "@http.post" do |asgn|
  asgn.line "\"/path\","
  asgn.line "body: data,"
end
# response = @http.post(
#   "/path",
#   body: data,
# )
```

## Method calls

```crystal
method_call :puts, "\"hello\""        # puts "hello"
method_call "foo", "a", "b"           # foo(a, b)
method_call "foo", "a", braces: false # foo a
```

## Multi-branch conditionals

`cond` builds `if/elsif/else`. The block receives an `IfNodeBuilder` that
exposes `elsif` and `else_clause`; all other `Builder` methods work unqualified
inside each branch:

```crystal
cond "x > 0" do |if_bldr|
  if_bldr.line "positive"
  if_bldr.elsif("x == 0") { line "zero" }
  if_bldr.else_clause { line "negative" }
end
# if x > 0
#   positive
# elsif x == 0
#   zero
# else
#   negative
# end
```

## Case statements

`case_when` builds `case/when/else`. The block receives a `CaseNodeBuilder`.
When every branch is a single line, crystina uses the compact `then` form
automatically:

```crystal
case_when "status" do |case_bldr|
  case_bldr.when(%("ok"))    { line "200" }
  case_bldr.when(%("error")) { line "500" }
  case_bldr.else_clause      { line "0" }
end
# case status
# when "ok"    then 200
# when "error" then 500
# else              0
# end
```

To produce a case expression on the left side of an assignment, use
`assign(target).case_when`:

```crystal
assign("code").case_when("status") do |case_bldr|
  case_bldr.when(%("ok")) { line "200" }
end
# code = case status
# when "ok" then 200
# end
```

## Rescue blocks

`rescue_block` wraps a `begin … rescue … end` construct. The block receives a
`RescueBlockBuilder`:

```crystal
rescue_block "begin" do |rb|
  rb.body do
    line "risky_call"
  end
  rb.rescue_clause(:ex, "IO::Error") do
    raise_ex "RuntimeError.new(ex.message)"
  end
end
# begin
#   risky_call
# rescue ex : IO::Error
#   raise RuntimeError.new(ex.message)
# end
```

## Free-standing constructors

All block-type constructors are also available as module-level methods that
return a node without needing a builder context:

```crystal
node = Crystina.mod("Util") { line "VERSION = 1" }
Crystina.klass("Base") { ... }
Crystina.struct_def("Point") { ... }
Crystina.def_method("id", [Crystina.param("x", "Int32")], "Int32") { line "x" }
```

Use `builder.node(n)` to append any pre-built node into an ongoing builder:

```crystal
C.build.node(some_node).blank.line("# done")
```

## Development

```
make          # fmt + lint + docs + spec (full pipeline)
make fmt      # auto-format sources
make fmtcheck # check formatting without modifying
make lint     # run ameba linter
make fix      # ameba --fix (auto-correct style issues)
make spec     # crystal spec -v
make docs     # generate API docs in docs/
make clean    # remove docs/
make version  # sync VERSION constant in src/ to shard.yml's version field
make tag      # create an annotated git tag vX.Y.Z from shard.yml's version field
```

## License

MIT
