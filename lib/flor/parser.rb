#--
# Copyright (c) 2015-2016, John Mettraux, jmettraux+flon@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++

require 'raabro'


module Flor

  module Rad include Raabro

    # parsing

    def null(i); str(:null, i, 'null'); end
    def number(i); rex(:number, i, /-?[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?/); end

    def tru(i); str(nil, i, 'true'); end
    def fls(i); str(nil, i, 'false'); end
    def boolean(i); alt(:boolean, i, :tru, :fls); end

    def dqstring(i)

      rex(:dqstring, i, %r{
        "(
          \\["bfnrt] |
          \\u[0-9a-fA-F]{4} |
          [^"\\\b\f\n\r\t]
        )*"
      }x)
    end

    def sqstring(i)

      rex(:sqstring, i, %r{
        '(
          \\['bfnrt] |
          \\u[0-9a-fA-F]{4} |
          [^'\\\b\f\n\r\t]
        )*'
      }x)
    end

    def rxstring(i)

      rex(:rxstring, i, %r{
        /(
          \\[\/bfnrt] |
          \\u[0-9a-fA-F]{4} |
          [^'\\\b\f\n\r\t]
        )*/[a-z]*
      }x)
    end

    def symbol(i); rex(:symbol, i, /[^: \b\f\n\r\t"',()\[\]{}#\\]+/); end

    def shacomment(i); rex(nil, i, /#[^\r\n]*/); end
    def slacomment(i); rex(nil, i, /\/\/[^\r\n]*/); end
    def comment(i); alt(nil, i, :shacomment, :slacomment); end

    def wspace(i); rex(nil, i, /[ \t]/); end
    def retnew(i); rex(nil, i, /[\r\n]/); end
    def colon(i); str(nil, i, ':'); end
    def comma(i); str(nil, i, ','); end

    def pstart(i); str(nil, i, '('); end
    def pend(i); str(nil, i, ')'); end
    def sbstart(i); str(nil, i, '['); end
    def sbend(i); str(nil, i, ']'); end
    def pbstart(i); str(nil, i, '{'); end
    def pbend(i); str(nil, i, '}'); end

    def eol(i); seq(nil, i, :wspace, '*', :comment, '?', :retnew, '*'); end
    def postval(i); rep(nil, i, :eol, 0); end
    def sep(i); seq(nil, i, :comma, '?', :postval); end

    def ope(i); rex(:ope, i, /(\+|-|\/|\*|%|==?|!=|<>|>=?|<=?)/); end

    def rad_ent(i)
      seq(:rad_ent, i, :rad_key, :postval, :colon, :postval, :rad_val, :postval)
    end
    def rad_ent_qmark(i); rep(nil, i, :rad_ent, 0, 1); end

    def rad_obj(i)
      eseq(:rad_obj, i, :pbstart, :rad_ent_qmark, :sep, :pbend)
    end

    def rad_val_qmark(i); rep(nil, i, :rad_val, 0, 1); end

    def rad_arr(i)
      eseq(:rad_arr, i, :sbstart, :rad_val_qmark, :sep, :sbend)
    end

    def rad_ope(i)
      jseq(:rad_ope, i, :rad_val, :ope)
    end

    def rad_par(i)
      seq(:rad_par, i, :pstart, :eol, :wspace, '*', :rad_grp, :eol, :pend)
    end

    def rad_core_val(i)
#alt(:rad_val, i, :rad_par, :rad_ope)
      altg(:rad_val, i,
        :symbol,
        :sqstring, :dqstring, :rxstring,
        :rad_arr, :rad_obj,
        :number, :boolean, :null)
    end
    def rad_val(i); seq(nil, i, :rad_core_val, :postval); end

    def rad_key(i); alt(:rad_key, i, :dqstring, :sqstring, :symbol); end
      # TODO eventually, accept anything and stringify...

    def rad_kcol(i)
      seq(nil, i, :rad_key, :wspace, '*', :colon, :eol, :wspace, '*')
    end
    def rad_elt(i); seq(:rad_elt, i, :rad_kcol, '?', :rad_val); end
    def rad_coe(i); seq(nil, i, :comma, :eol); end
    def rad_com(i); seq(nil, i, :wspace, '*', :rad_coe, '?', :wspace, '*'); end
    def rad_cel(i); seq(nil, i, :rad_com, :rad_elt); end
    def rad_elts(i); rep(nil, i, :rad_cel, 0); end
    def rad_hed(i); seq(:rad_hed, i, :rad_val); end # ?
    def rad_grp(i); seq(:rad_grp, i, :rad_hed, :rad_elts); end
    def rad_ind(i); rex(:rad_ind, i, /[ \t]*/); end
    def rad_eol(i); rex(nil, i, /[ \t]*(#[^\n\r]*)?[\n\r]?/); end

    def rad_lin(i); seq(:rad_lin, i, :rad_ind, :rad_grp); end

    def rad_line(i); seq(nil, i, :rad_lin, '?', :rad_eol); end
    def radial(i); rep(:radial, i, :rad_line, 0); end

    # rewriting

    def line_number(t)

      t.input.string[0..t.offset].scan("\n").count + 1
    end
    alias ln line_number

    def rewrite_symbol(t); [ t.string, [], ln(t) ]; end
    alias rewrite_symbolk rewrite_symbol

    def rewrite_sqstring(t); [ '_sqs', t.string[1..-2], ln(t) ]; end
    def rewrite_dqstring(t); [ '_dqs', t.string[1..-2], ln(t) ]; end
    def rewrite_rxstring(t); [ '_rxs', t.string, ln(t) ]; end

    def rewrite_number(t)

      s = t.string; [ '_num', s.index('.') ? s.to_f : s.to_i, ln(t) ]
    end

    def rewrite_boolean(t); [ '_boo', t.string == 'true', line_number(t) ]; end
    def rewrite_null(t); [ '_nul', nil, line_number(t) ]; end

    def rewrite_rad_val(t); rewrite(t.c0); end

    def rewrite_rad_arr(t)

      [ '_arr', t.subgather(nil).collect { |n| rewrite(n) }, ln(t) ]
    end

    def rewrite_rad_obj(t)

      cn =
        t.subgather(nil).inject([]) do |a, tt|
          a.concat([ rewrite(tt.c0.c0), rewrite(tt.c4) ])
        end

      [ '_obj', cn, ln(t) ]
    end

    class Line

      attr_accessor :parent
      attr_reader :indent, :children

      def initialize(tree)

        @parent = nil
        @indent = -1
        @head = 'sequence'
        @children = []
        @line = 0

        read(tree) if tree
      end

      def append(line)

        if line.indent > self.indent
          @children << line
          line.parent = self
        else
          @parent.append(line)
        end
      end

      def to_a

        if @head.is_a?(Array) && @children.empty?
          @head
        else
          [ @head, @children.collect(&:to_a), @line ]
        end
      end

      protected

      def read(tree)

        gt = tree.lookup(:rad_grp)
        @line = Rad.line_number(gt)

        if it = tree.lookup(:rad_ind)
          @indent = it.string.length
        end

        #  nam =
        #    if vt.name == :symbol
        #      vt.string
        #    elsif vt.name == :dqstring || vt.name == :sqstring
        #      #vt.string[1..-2]
        #      Flor::Radial.rewrite(vt)
        #    elsif vt.name == :rad_p
        #      Flor::Radial.rewrite(vt)
        #    else
        #      Flor::Radial.to_val(vt)
        #    end
        vt = tree.lookup(:rad_hed).lookup(:rad_val).sublookup(nil)
        @head =
          if vt.name == :symbol
            vt.string
          else
            Flor::Rad.rewrite(vt)
          end

        attributes = []
        children = []

        tree.lookup(:rad_grp).c1.gather(:rad_elt).each do |et|

          if kt = et.lookup(:rad_key)
            attributes << Flor::Rad.rewrite(kt.c0)
            attributes << Flor::Rad.rewrite(et.lookup(:rad_val).c0)
          else
            children << Flor::Rad.rewrite(et.lookup(:rad_val).c0)
          end
        end

        @children << [ '_atts', attributes, @line ] if attributes.any?
        @children.concat(children)
      end
    end

    def rewrite_radial(t)

      root = Line.new(nil)
      prev = root

      t.gather(:rad_lin).each do |lt|
        l = Line.new(lt)
        prev.append(l)
        prev = l
      end

      return root.children.first.to_a if root.children.count == 1

      root.to_a
    end

    def parse(input, fname=nil, opts={})

      opts = fname if fname.is_a?(Hash) && opts.empty?

      r = super(input, opts)
      r << fname if fname

      r
    end
  end # module Rad

  module RadialX #include JsonX

    def to_val(t)

      as =
        case t.name
          when :sqstring, :dqstring
            { 't' => t.name.to_s, 'v' => Flor.unescape(t.string[1..-2]) }
          when :rxstring
            { 't' => t.name.to_s, 'v' => t.string }
          else
            { 'v' => rewrite(t) }
        end

      [ 'val', as, line_number(t), [] ]
    end

    def rewrite_rad_p(t)

      Line.new(t).to_a
    end
  end # module RadialX

  def self.unescape_u(cs)

    s = ''; 4.times { s << cs.next }

    [ s.to_i(16) ].pack('U*')
  end

  def self.unescape(s)

    sio = StringIO.new

    cs = s.each_char

    loop do

      c = cs.next

      break unless c

      if c == '\\'
        case cn = cs.next
          when 'u' then sio.print(unescape_u(cs))
          when '\\', '"', '\'' then sio.print(cn)
          when 'b' then sio.print("\b")
          when 'f' then sio.print("\f")
          when 'n' then sio.print("\n")
          when 'r' then sio.print("\r")
          when 't' then sio.print("\t")
          else sio.print("\\#{cn}")
        end
      else
        sio.print(c)
      end
    end

    sio.string
  end
end
