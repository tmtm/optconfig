# $Id: optconfig.rb,v 1.3 2005-06-30 05:52:16 tommy Exp $
#
# Copyright (C) 2004-2005 TOMITA Masahiro
# tommy@tmtm.org
#

# opt = OptConfig.new
# opt.options = {optname => flag}
# opt.options = {optname => [flag, default], ...}
# opt.options = {[opt1, opt2] => [flag, default], ...}
#     flag: nil/false:  no argument
#           true:       need argument
#           Regexp obj: need argument that have to match regular-exp
# opt.parse(["-abc", "--opt1", "--opt2=arg", "arg"]) => 3
# opt["a"] => true
# opt["opt1"] => true
# opt["opt2"] => "arg"
#

class OptConfig

  class Error < StandardError
  end

  def initialize()
    @file = nil
    @idlist = nil
    @options = {}
    @values = {}
    @ignore_unknown_file_option = true
  end

  attr_writer :file, :idlist
  attr_accessor :ignore_unknown_file_option

  def [](n)
    return nil unless @name.key? n
    @values[@name[n]]
  end

  def key?(n)
    @name.key? n and @values.key? @name[n]
  end

  def hash()
    ret = {}
    @values.keys.flatten.each do |n|
      ret[n] = @values[@name[n]]
    end
    ret
  end

  def check(n, v)
    raise Error, "unknown option: #{n}" unless @name.key? n
    r = @options[@name[n]][0]
    if r == false or r == nil then
      if v == nil or v.empty? then
        return true
      end
    elsif r == true then
      return v if v
    elsif r.kind_of? Regexp then
      if r =~ v then
        return v
      end
    end
    raise Error, "argument mismatch: #{n}: #{v}"
  end

  def options=(hash)
    @options = {}
    @name = {}
    hash.each do |n, v|
      unless v.is_a? Array then
        v = [v, nil]
      end
      if n.is_a? Array then
        n.each do |nn|
          raise Error, "duplicate options: #{nn}" if @name.key? nn
          @name[nn] = n
        end
        @options[n] = v
      else
        @name[n] = [n]
        @options[[n]] = v
      end
    end
  end

  def parse(argv=[])
    @values = {}
    @options.each do |n, v|
      @values[n] = v[1] if v[1]
    end
    if @file then
      @section = nil
      IO.foreach(@file) do |l|
        l.chomp!
        next if l[0, 1] == "#" or l =~ /^\s*$/
        if l =~ /\[([a-z0-9_-]+)\]/i then
          @section = $1
          next
        end
        next if @idlist and not @idlist.include? @section
        n, v = l.chomp.split(/\s*=\s*|\s+/, 2)
        unless @name.key? n then
          raise Error, "unknown option: #{n}" unless @ignore_unknown_file_option
          next
        end
        @values[@name[n]] = check(n, v)
      end
    end
    i = 0
    while i < argv.size do
      if argv[i] == "--" then
        i += 1
        break
      end
      if argv[i] == "-" then
        break
      end
      if argv[i][0,2] == "--" then
        a = argv[i][2..-1]
        if a.include? "=" then
          n, v = a.split(/=/, 2)
          @values[@name[n]] = check(n, v)
        else
          n = a
          raise Error, "unknown option: #{n}" unless @name.key? n
          unless @options[@name[n]][0] then
            @values[@name[n]] = true
          else
            @values[@name[n]] = check(n, argv[i+1])
            i += 1
          end
        end
      elsif argv[i][0,1] == "-" then
        a = argv[i][1..-1]
        while not a.empty? do
          n = a.slice!(0, 1)
          raise Error, "unknown option: #{n}" unless @name.key? n
          unless @options[@name[n]][0] then
            @values[@name[n]] = true
          else
            if not a.empty? then
              @values[@name[n]] = check(n, a)
            else
              @values[@name[n]] = check(n, argv[i+1])
              i += 1
            end
            break
          end
        end
      else
        break
      end
      i += 1
    end
    return i
  end

  def parse!(argv=[])
    n = parse(argv)
    argv.slice!(0, n)
    return n
  end
end
