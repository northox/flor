
require 'io/console'


module Flor

  def self.to_djan(x, opts={}); to_d(x, opts); end

  def self.to_d(x, opts={})

    opts[:s] = StringIO.new
    opts[:c] = Flor.colours(opts)

    if opts[:width] == true
      opts[:width] = IO.console.winsize[1]
    elsif mw = (opts[:mw] || opts[:maxwidth] || opts[:max_width])
      opts[:width] = [ IO.console.winsize[1], mw ].min
    end

    Djan.to_d(x, opts)

    opts[:s].string
  end

  module Djan
    extend self

    def to_d(x, opts)

      case x
      when nil then nil_to_d(x, opts)
      when String then string_to_d(x, opts)
      when Hash then object_to_d(x, opts)
      when Array then array_to_d(x, opts)
      when TrueClass then boolean_to_d(x.to_s, opts)
      when FalseClass then boolean_to_d(x.to_s, opts)
      else num_to_d(x.to_s, opts)
      end
    end

    def len(x, opts)

      opts = opts.merge(
        s: StringIO.new, c: Flor.no_colours, indent: nil, width: nil)

      to_d(x, opts)

      opts[:s].string.length
    end

    def newline(opts)

      opts[:s] << "\n"
    end

    def space(opts, force=false)

      opts[:s] << ' ' if force || ! opts[:compact]
    end

    def newline_or_space(opts)

      if opts[:indent]
        newline(opts)
      elsif ! opts[:compact]
        space(opts)
      end
    end

    def indent_space(opts)

      return if opts.delete(:first)
      i = opts[:indent]
      opts[:s] << '  ' * i if i
    end

    def indent(opts, os={})

      if i = opts[:indent]
        opts.merge(indent: i + (os[:inc] || 1), first: os[:first])
      else
        opts
      end
    end

    def adjust(x, opts)

      i = opts[:indent]
      w = opts[:width]

      return opts unless i && w && i + len(x, opts) < w
      opts.merge(indent: nil)
    end

    def object_to_d(x, opts)

      inner = opts.delete(:inner)

      indent_space(opts)

      return c_inf('{}', opts) if x.empty?

      opts = adjust(x, opts)

      unless inner
        c_inf('{', opts); space(opts)
      end

      x.each_with_index do |(k, v), i|
        string_to_d(k, indent(opts, first: i == 0))
        c_inf(':', opts)
        newline_or_space(opts)
        to_d(v, indent(opts, inc: 2))
        if i < x.size - 1
          c_inf(',', opts)
          newline_or_space(opts)
        end
      end

      unless inner
        space(opts); c_inf('}', opts)
      end
    end

    def array_to_d(x, opts)

      inner = opts.delete(:inner)

      indent_space(opts)

      return c_inf('[]', opts) if x.empty?

      opts = adjust(x, opts)

      unless inner
        c_inf('[', opts); space(opts)
      end

      x.each_with_index do |e, i|
        to_d(e, indent(opts, first: i == 0))
        if i < x.size - 1
          c_inf(',', opts)
          newline_or_space(opts)
        end
      end

      unless inner
        space(opts); c_inf(']', opts)
      end
    end

    def string_to_d(x, opts)

      x = x.to_s

      indent_space(opts)

      if (
        x.match(/\A[^: \b\f\n\r\t"',()\[\]{}#\\+%\/><^!=-]+\z/) == nil ||
        x.to_i.to_s == x ||
        x.to_f.to_s == x
      )
        c_inf('"', opts)
        c_str(x.inspect[1..-2], opts)
        c_inf('"', opts)
      else
        c_str(x, opts)
      end
    end

    def boolean_to_d(x, opts)

      indent_space(opts)
      if x
        c_tru(x, opts)
      else
        c_fal(x, opts)
      end
    end

    def num_to_d(x, opts)

      indent_space(opts); c_num(x, opts)
    end

    def nil_to_d(x, opts)

      indent_space(opts); c_nil('null', opts)
    end

    def c_inf(s, opts); opts[:s] << opts[:c].dark_gray(s); end

    def c_nil(s, opts); opts[:s] << opts[:c].dark_gray(s); end
    def c_tru(s, opts); opts[:s] << opts[:c].green(s); end
    def c_fal(s, opts); opts[:s] << opts[:c].red(s); end
    def c_str(s, opts); opts[:s] << opts[:c].brown(s); end
    def c_num(s, opts); opts[:s] << opts[:c].light_blue(s); end
  end
end

