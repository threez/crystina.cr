module Crystina
  # :nodoc:
  class Comment < Node
    # wrap: :auto  — wrap only if text is single-line (default)
    #        true  — always wrap
    #        false — never wrap
    def initialize(@text : String, @wrap : Bool | Symbol = :auto)
    end

    # :nodoc:
    def render(io : IO, indent : Int32 = 0) : Nil
      prefix = "  " * indent + "# "
      should_wrap = case @wrap
                    when :auto then !@text.includes?('\n')
                    when true  then true
                    else            false
                    end
      if should_wrap && @text.size > MAX_LINE - prefix.size
        wrap_text(@text, prefix, io)
      else
        io << prefix << @text << "\n"
      end
    end

    private def wrap_text(text : String, prefix : String, io : IO) : Nil
      available = MAX_LINE - prefix.size
      words = text.split(' ', remove_empty: true)
      buf = ""
      words.each do |word|
        if buf.empty?
          buf = word
        elsif buf.size + 1 + word.size <= available
          buf += " " + word
        else
          io << prefix << buf << "\n"
          buf = word
        end
      end
      io << prefix << buf << "\n" unless buf.empty?
    end
  end
end
