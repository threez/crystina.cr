module Crystina
  # Represents a single method parameter with an optional type annotation and default value.
  record Param, name : String, type : String? = nil, default : String? = nil do
    # Parameter name, written as-is (include `@` prefix for ivar-initialising params).
    getter name : String

    # Crystal type annotation (e.g. `"String"`, `"Int32?"`). Omit for untyped params.
    getter type : String?

    # Default value expression as a string (e.g. `"nil"`, `"0"`).
    getter default : String?

    # :nodoc:
    def to_s(io : IO) : Nil
      io << name
      if t = type
        io << " : " << t
      end
      if d = default
        io << " = " << d
      end
    end
  end
end
