module Crystina
  # :nodoc:
  class MethodDef < Node
    # :nodoc:
    def initialize(
      @abstract : Bool,
      @name : String,
      @params : Array(String),
      @return_type : String?,
      @body : Sequence?,
    )
    end

    # :nodoc:
    def render(io : IO, indent : Int32 = 0) : Nil
      spaces = "  " * indent
      keyword = @abstract ? "abstract def" : "def"
      suffix = @return_type ? " : #{@return_type}" : ""

      if @params.empty?
        io << spaces << keyword << " " << @name << suffix << "\n"
      else
        single = "#{keyword} #{@name}(#{@params.join(", ")})#{suffix}"
        if spaces.size + single.size <= MAX_LINE
          io << spaces << single << "\n"
        else
          io << spaces << keyword << " " << @name << "(\n"
          @params.each_with_index do |param_str, i|
            comma = i < @params.size - 1 ? "," : ""
            io << spaces << "  " << param_str << comma << "\n"
          end
          io << spaces << ")" << suffix << "\n"
        end
      end

      if body = @body
        body.render(io, indent + 1)
        io << spaces << "end\n"
      end
    end
  end
end
