
require 'parslet'
require 'pp'

# SelfML is a simple, human writable, machine readable, configuration
# language. This is the ruby implementation.
module SelfML
  # The current version.
  VERSION = "0.0.1"

  module_function
  # Parse a SelfML document inputed as a string.
  # Returns an array. That array will contain both strings an arrays,
  # and so on.
  #
  #    SelfML.parse("(test awesome x)") #=> [["test", "awesome", "x"]] 
  #
  #    SelfML.parse("(x (1 2 3) [This is a test])") 
  #        #=> [[:x, [1, 2, 3], "This is a test"]]
  def parse(string)
    Transformer.new.apply(Parser.new.parse(string))
  end

  # This is a slightly heavier weight way of parsing SelfML strings.
  #
  #    ml = SelfML::Document.new
  #    ml.parse("test") #=> ["test"]
  #
  # This might be slightly more efficient (what with alocating parser
  # and transformer resources) but it's more verbose.
  class Document
    # Create a new document object, with which, you can parse SelfML
    # documents.
    def initialize
      @parser = Parser.new
      @transformer = Transformer.new
    end

    # Parse a string of SelfML. See SelfML#parse for more information on
    # SelfML parsing.
    def parse(string)
      @transformer.apply(@parser.parse(string))
    end
  end

  # This is the parser for SelfML. Looking at this might be useful. This
  # outputs a strange, verbose parse tree full of hashes, arrays, and
  # symbols. See SelfML::Transformer to convert this tree into useable
  # data.
  class Parser < Parslet::Parser
    # Whitespace stuff
    rule(:space)      { match('\s').repeat(1) }
    rule(:space?)     { space.maybe }

    rule(:line_comment) { match("#.+\n") }
    rule(:block_comment) {
      str("{#") >>
      (str("#}").absent? >> any).repeat >>
      str("#}")
    }

    # String literals
    rule(:word_literal) { match('[^\(\)\[\]\{\}#` \n]').repeat(1).as(:literal) }
    rule(:bracket_literal) { 
      str("[") >> 
      space? >> 
      (
        (str("]").absent? >> any) # []] and [[] are valid, shouldn't be
      ).repeat.as(:literal) >> 
      str("]") >>
      space? 
    }

    rule(:backtick_literal) { 
      str("`") >> 
      space? >> 
      (
        (str("`").absent? >> any).as(:tmp_literal) |
        (str("``")).as(:double_backtick)
      ).repeat.as(:backtick_literal) >> 
      str("`") >>
      space? 
    }
    rule(:literal) { ( bracket_literal | backtick_literal | word_literal ) >> space? }

    rule(:subnodes) { str("(") >> nodes >> space? >> str(")") >> space? }

    rule(:line_comment) {
      str("#") >>
      (str("\n").absent? >> any).repeat.maybe >> 
      str("\n")
    }

    # Node!
    rule(:node) { ( literal | line_comment | block_comment | subnodes.as(:nodes) ) >> space? }

    # Root stuff
    rule(:nodes) { node.repeat }
    root(:nodes)
  end

  # This is the transformer for SelfML. This takes the parse tree and
  # converts it to useful data.
  class Transformer < Parslet::Transform
    rule(:backtick_literal => subtree(:x)) do
      x.map do |y|  
        if y.has_key?(:double_backtick)
          '`'
        else
          y[:tmp_literal]
        end
      end.join("")
    end

    rule(:literal => simple(:y)) do
      x = y.to_s
      if x =~ /[0-9]+/
        x.to_i
      elsif x.split(" ").length == 1
        x.to_sym
      else
        x
      end
    end
    
    rule(:nodes => subtree(:x)) { x }

  end
end

if $0 == __FILE__
  pp SelfML.parse(IO.readlines(ARGV.first).join(''))
end
