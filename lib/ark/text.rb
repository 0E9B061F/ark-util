module ARK

# Methods for manipulating text
module Text

  def self.wrap_segments(segments, width: 78, indent: 0, indent_after: false)
    segments = segments.flatten.map(&:to_s)
    lines = []
    line = ''
    current_indent = indent
    segments.each do |seg|
      if lines.empty? && indent_after
        current_indent = 0
      else
        current_indent = indent
      end
      if line.size + seg.size >= width
        lines << line
        line = (' ' * indent) + seg
      elsif line.empty?
        line = (' ' * current_indent) + seg
      else
        line << ' ' << seg
      end
    end
    lines << line if line
    return lines.join("\n")
  end

  # Wrap a string to a given width, with an optional indent. Indented text
  # will fall within the specified width.
  # [+text+] The text to be wrapped
  # [+width+] The number of columns to wrap within
  # [+indent+] Indent each wrapped line of +text+ by this number of columns
  def self.wrap(text, width: 78, indent: 0, indent_after: false)
    if text.is_a?(Array)
      text = text.flatten.join(' ')
    end
    text = text.split(' ')
    self.wrap_segments(text, width: width, indent: indent, indent_after: indent_after)
  end
end

# Build text progressively, line by line
class TextBuilder
  # Initialize a TextBuilder instance
  def initialize()
    @lines = [[]]
    @line  = 0
  end

  # Push one or more strings onto the current line
  def push(*str)
    @lines[@line] += str.flatten.compact.map(&:to_s)
    return self
  end

  # Concatenate any strings given, then append them to the last element on the
  # line. No spaces will be added before or between the given strings.
  def add(*str)
    @lines[@line][-1] += str.flatten.compact.join
    return self
  end

  # Wrap the current line to +width+, with an optional +indent+. After
  # wrapping, the current line will be the last line wrapped.
  def wrap(width: 78, indent: 0, indent_after: false, segments: false)
    if segments
      text = Text.wrap_segments(@lines[@line], width: width, indent: indent, indent_after: indent_after)
    else
      text = Text.wrap(@lines[@line], width: width, indent: indent, indent_after: indent_after)
    end
    @lines.delete_at(@line)
    @line -= 1
    text.split("\n").each {|line| self.next(line) }
    return self
  end

  # Indent the current line by +count+ columns
  def indent(count)
    @lines[@line].unshift(' ' * (count - 1))
    return self
  end

  # Start a new line. If +str+ is provided, push +str+ onto the new line
  def next(str=nil)
    @lines << []
    @line  += 1
    self.push(str) if str
    return self
  end

  # Insert a blank line and start the line after it. If +str+ is given, push
  # +str+ onto the new line.
  def skip(str=nil)
    self.next()
    self.next(str)
    return self
  end

  # Print the constructed text
  def print()
    return @lines.map {|line| line.join(' ') }.join("\n")
  end

  # Synonym for #print
  def to_s()
    return self.print
  end
end

end # module ARK

