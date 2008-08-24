# $Id$
# Copyright (C) 2004-2008 TOMITA Masahiro
# mailto:tommy@tmtm.org
#
# = OptConfig
# Author:: TOMITA Masahiro <tommy@tmtm.org>
# License:: Ruby's. see http://www.ruby-lang.org/en/LICENSE.txt
#
# * OptConfig はコマンドラインオプションのパーサです。
# * ファイルからオプションを読み込むこともできます。
# * -s 形式と --long-option 形式の両方を扱うことができます。
# * 長い形式のオプションは曖昧でなければ補完されます。
# * usage に使用する文字列を自動的に生成します。
# * オプションの引数の形式を指定できます。
#
# == Download
# * http://rubyforge.org/frs/?group_id=4777
# * http://tmtm.org/downloads/ruby/optconfig/
#
# == Required
# * StringValidator http://stringvalidator.rubyforge.org/
#
# == Install
#  $ make
#  # make install
#
# == Usage
#  require "optconfig"
#  opt = OptConfig.new
#  opt.option "p", "port=num", :format=>1..65535, :default=>110, :description=>"port number (%s)"
#  opt.option "h", "hostname=name", :format=>true, :default=>"localhost", :description=>"hostname (%s)"
#  opt.option "hogehoge", :description=>"enable hogehoge flag"
#
#  argv = %w[-p 12345 -h 192.168.1.1 arg1 arg2]
#  opt.parse argv    # => ["arg1", "arg2"]
#  opt["p"]          # => 12345
#  opt["port"]       # => 12345 (same as opt["p"])
#  opt["h"]          # => "192.168.1.1"
#  opt["hogehoge"]   # => nil (means not set)
#  opt["x"]          # raise OptConfig::UnknownOption
#  argv              # => ["-p", "12345", "-h", "192.168.1.1", "arg1", "arg2"]
#  opt.parse! argv   # => ["arg1", "arg2"]
#  argv              # => ["arg1", "arg2"]
#
# opt.usage は次の文字列を生成します。
#    -p, --port=num         port number (12345)
#    -h, --hostname=name    hostname (192.168.1.1)
#    --hogehoge             enable hogehoge flag
#
# === オプション定義
# OptConfig#option でオプションを定義します。
# 引数は、オプション名のリストと、オプションの属性を表す Hash です。
# [オプション名]
#   1文字の英数字、または2文字以上の英数字と「-」「_」。
#   同じオプションに複数の名前をつける場合は複数指定します。
#   "long-name=val" の形式で指定すると :argument 属性が true になります。
#   "long-name[=val]" の形式で指定すると :argument 属性が :optional になります。
#
# オプション属性(Hash)のキーは以下の通りです。
# [:argument]
#   オプションが引数を取るかどうか。
#   nil :: format が真の場合は引数必須、偽の場合は引数不要 (デフォルト)。
#   true :: 引数必須。
#   false :: 引数不要。
#   :optional :: 引数を省略可能。省略時は OptConfig#[] は true になる。
# [:format]
#   オプション引数の形式。
#   true :: 任意。
#   false/nil :: オプションが引数を必要としない (デフォルト)。
#   :boolean :: オプション引数が "1", "true", "enable", "yes", "y", "on" で true、"0", "false", "disable", "no", "n", "off" で false を返す。
#   その他 :: StringValidator の rule オブジェクトとみなして引数の形式をチェックする。
# [:default]
#   オプションが指定されなかった場合のデフォルト値。
# [:description]
#   オプションの説明文字列。説明は usage() で出力されます。
#   nil の場合は usage() でオプションについて出力されません。
#   文字列中の %s はオプションの値に置換されます。
# [:multiple]
#   複数指定された場合の振る舞い。
#   true ::      複数指定可能。OptConfig#[] は配列を返す。
#   false/nil :: 複数指定された場合はエラー。
#   :last ::     最後に指定されたものが有効(デフォルト)。
# [:completion]
#   長いオプションを補完するかどうか (デフォルト: true)。
# [:underscore_is_hyphen]
#   アンダースコアをハイフンとみなすかどうか (デフォルト: nil)
# [:in_config]
#   オプションファイル内に記述可能かどうか (デフォルト: true)。
# [:proc]
#   parse() 時にオプションを見つける度に実行される Proc オブジェクト。
#   オプション引数の正当性を確認した後に実行されます。
#   ブロック引数は、オプション名, Option オブジェクト, オプション引数です。
#   ブロックの評価結果は OptConfig#[] の戻り値として使用されます。
# [:pre_proc]
#   :proc と同じですが、オプション引数の正当性の確認前に実行されます。
#   ブロック引数は、オプション名, Option オブジェクト, オプション引数です。
#   ブロックの評価結果はオプション引数として使用されます。
#
# === オプションファイル
# parse よりも前に file= でファイル名を指定するか、OptConfig.new 時に
# :file 属性を指定すると、そのファイルからオプションを読み込みます。ファ
# イルで指定されたオプションよりも、parse の引数で指定されたオプション
# の方が優先度が高いです。
#
# オプションファイルの形式は次の通りです:
#  option-name = value
#
# option-name には1文字のオプション名は指定できません。
#
# 「=」の前後の空白はあってもなくても構いません。「=」は省略可能です。
# その場合は、オプション名と値との間に一つ以上の空白が必要です。
#
# 「#」で始まる行はコメントとみなされます。空行も無視されます。
# 指定できるオプションは長い形式のオプションだけです。
#
# ファイル中に「[_section_name_]」という行を置くと、その行以降がセクショ
# ンとして扱われます。OptConfig#section= でセクション名を指定すると、指
# 定したセクションのオプションのみが読み込まれます。OptConfig#section=
# に配列を設定すると、複数のセクションから読み込みます。
# OptConfig#section を設定しない場合は、すべてのセクションからオプショ
# ンを読み込みます。

require "stringvalidator"

class OptConfig
  class Error < StandardError; end
  # 未知のオプション
  class UnknownOption < Error; end
  # オプションに引数が必要
  class ArgumentRequired < Error; end
  # オプションの引数が不正
  class InvalidArgument < Error; end
  # オプション名が曖昧
  class AmbiguousOption < Error; end
  # オプションに不要な引数が指定された
  class UnnecessaryArgument < Error; end
  # 同じオプションが複数指定された
  class DuplicatedOption < Error; end

  # == 初期化
  # default_attr には各オプション属性のデフォルト値を Hash で指定可能。
  # オプション属性以外にも以下のものを指定できる。これらは OptConfig オブジェクト自身に影響する。
  # :file :: オプションファイル名 (String)。デフォルト: なし。
  # :section :: オプションファイル名のセクション名 (String または String の配列)。デフォルト: なし。
  # :ignore_unknown_file_option :: オプションファイル内に未知のオプションがあっtた時に無視するか(true)エラーにするか(false)。デフォルト: true。
  # :stop_at_non_option_argument :: オプションでない引数でオプションの解釈をやめるか(true)、それ以降もオプションの解釈を続けるか(false)。デフォルト: false。
  def initialize(default_attr={})
    @default_attr = default_attr
    @option_seq = []
    @options = {}
    @file = default_attr[:file]
    @section = default_attr[:section]
    @stop_at_non_option_argument = default_attr[:stop_at_non_option_argument]
    @ignore_unknown_file_option = default_attr.key?(:ignore_unknown_file_option) ? default_attr[:ignore_unknown_file_option] : true
    @obsolete_behavior = false
    @specified = {}               # オプションが指定されたかどうかを保持
  end
  attr_accessor :file, :section, :ignore_unknown_file_option

  alias idlist section
  alias idlist= section=

  # == オプション定義
  # args:: オプション名(String) のリスト、オプションの属性(Hash)
  # === 戻り値
  # Option オブジェクト
  # === 例外
  # RuntimeError:: オプションが既に定義されている
  def option(*args)
    args = args.dup
    if args.last.is_a? Hash
      attr = args.pop
      attr = @default_attr.merge attr
    else
      attr = @default_attr
    end
    args.push attr
    opt = Option.new *args
    opt.name.each do |n|
      raise "option #{n} is already defined" if @options.key? n
      @options[n] = opt
    end
    @option_seq << opt
  end

  # == オプション定義(古いインタフェース)
  # option:: オプション定義(ハッシュ)
  def options=(option)
    @options.clear
    @option_seq.clear
    option.each do |k,v|
      v = [v] unless v.is_a? Array
      arg = k.to_a
      arg.push({:format=>v[0], :default=>v[1]})
      opt = Option.new *arg
      opt.name.each do |n|
        raise "option #{n} is already defined" if @options.key? n
        @options[n] = opt
      end
      @option_seq << opt
    end
    @obsolete_behavior = true
    option
  end

  # == argv のオプションを解析し、オプションを取り除いたものに置き換える
  # argv:: 配列
  # === 戻り値
  # argv:: 残りの引数
  def parse!(argv=[])
    orig_argv_size = argv.size
    ret = []
    @options.each_key do |k|
      @options[k].value = @options[k].default
    end
    @specified.clear
    parse_file @file if @file
    @specified.clear

    until argv.empty?
      arg = argv.shift
      case arg
      when "--"
        ret.concat argv
        break
      when /\A--[a-zA-Z0-9_]/
        parse_long_opt arg.sub(/\A--/, ""), argv
      when /\A-[a-zA-Z0-9]/
        parse_short_opt arg.sub(/\A-/, ""), argv
      else
        ret.push arg
        if @stop_at_non_option_argument
          ret.concat argv
          break
        end
      end
    end

    if @obsolete_behavior
      n = orig_argv_size - ret.size
      argv.replace ret
      return n
    end
    argv.replace ret
    return argv
  end

  # == argv のオプションを解析する
  # argv:: 文字列の配列
  # === 戻り値
  # argv からオプションを取り除いたもの
  def parse(argv=[])
    parse!(argv.dup)
  end

  # == ファイルからオプションを読み込む
  # filename:: ファイル名
  # === 例外
  # UnknownOption
  def parse_file(filename)
    cur_sect = nil
    File.open filename do |f|
      f.each_line do |line|
        line.chomp!
        next if line =~ /\A#|\A\s*\z/
        if line =~ /\A\[(.*)\]\z/
          cur_sect = $1
          next
        end
        if @section.nil? or @section.empty? or @section.to_a.include? cur_sect
          name, value = line.split(/\s*=\s*|\s+/, 2)
          begin
            opt = parse_long_opt "#{name}=#{value}", [], false
            opt.value = opt.default unless opt.in_config
          rescue UnknownOption
            raise unless @ignore_unknown_file_option
          end
        end
      end
    end
  end

  # == オプションの値を返す
  # name:: オプション名
  # === 例外
  # UnknownOption
  def [](name)
    raise UnknownOption, "unknown option: #{name}" unless @options.key? name
    @options[name].value
  end

  # == オプションの説明文字列を返す
  def usage
    ret = ""
    @option_seq.each do |opt|
      next unless opt.description
      short = []
      long = []
      opt.usage_name.each do |n|
        if n.size == 1
          short << "-#{n}"
        else
          long << "--#{n}"
        end
      end
      line = "  "+(short+long).join(", ")
      if opt.description.empty?
        ret << line+"\n"
        next
      end
      if line.length >= 25
        line << "\n                          "
      else
        line << " "*(26-line.length)
      end
      desc = opt.description.gsub(/%s/, opt.value.to_s).split "\n"
      line << desc.shift+"\n"
      desc.each do |d|
        line << "                          #{d}\n"
      end
      ret << line
    end
    ret
  end

  private

  # == オプションに値を設定
  # name:: オプション名
  # value:: 値
  # === 例外
  # UnknownOption, DuplicatedOption
  def set_option(name, value)
    raise UnknownOption, "unknown option: #{name}" unless @options.key? name
    opt = @options[name]
    value = opt.pre_proc.call name, opt, value if opt.pre_proc
    raise DuplicatedOption, "duplicated option: #{name}" if !opt.multiple and @specified[name]
    value = check_option name, value unless value == true or value == false
    value = opt.proc.call name, opt, value if opt.proc
    if opt.multiple == :last
      opt.value = value
    elsif opt.multiple
      opt.value = [] unless @specified[name]
      opt.value << value
    else
      opt.value = value
    end
    @specified[name] = true
  end

  # == オプション名と値の正当性を確認
  # name:: オプション名
  # value:: 値 (String)
  # === 例外
  # UnnecessaryArgument, ArgumentRequired, InvalidArgument
  def check_option(name, value)
    a = @options[name].argument
    f = @options[name].format
    raise UnnecessaryArgument, "option argument is unnecessary: #{name}" if a == false or (a.nil? and !f)
    return true if a == :optional and value.nil?
    raise ArgumentRequired, "argument required: #{name}" if value.nil?
    return value if f == true
    if f == :boolean
      return true if ["1","true","enable","yes","y","on"].include? value.downcase
      return false if ["0","false","disable","no","n","off"].include? value.downcase
      raise InvalidArgument, "invalid boolean value: #{name}"
    end
    begin
      return StringValidator.validate(f, value)
    rescue StringValidator::Error => e
      raise InvalidArgument, "invalid argument for option `#{name}': #{e.message}: #{value}"
    end
  end

  # == 長い名前のオプションの解釈
  # name:: オプション名
  # argv:: それ以降の文字列配列
  # completion:: 補完の有無
  # === 戻り値
  # OptConfig オブジェクト
  def parse_long_opt(name, argv, completion=true)
    if name.include? "="
      n, v = name.split "=", 2
      n, invert = long_option n, completion
      set_option n, v
      @options[n].value = !@options[n].value if invert
      return @options[n]
    end
    n, invert = long_option name, completion
    opt = @options[n]
    if opt.argument == false or opt.argument == :optional or
        (opt.argument.nil? and !opt.format)
      set_option n, !invert
      return @options[n]
    end
    set_option n, argv.shift
    @options[n].value = !@options[n].value if invert
    return @options[n]
  end

  # == 短い名前のオプションの解釈
  # name:: オプション名
  # argv:: それ以降の文字列配列
  # === 戻り値
  # OptConfig オブジェクト
  def parse_short_opt(name, argv)
    arg = name.dup
    until arg.empty?
      n = arg.slice!(0, 1)
      raise UnknownOption, "unknown option: #{n}" unless @options.key? n
      opt = @options[n]
      if opt.argument == false or (opt.argument.nil? and !opt.format)
        set_option n, true
        next
      end
      unless arg.empty?
        set_option n, arg
        return @options[n]
      end
      if opt.argument == :optional
        set_option n, true
        return @options[n]
      end
      set_option n, argv.shift
      return @options[n]
    end
  end

  # == 長いオプション名の確認
  # name:: オプション名
  # completion:: 補完の有無
  # === 戻り値
  # String :: 補完後オプション名
  # true/false :: "no-" prefix 指定？
  # === 例外
  # UnknownOption
  def long_option(name, completion)
    n = completion ? long_option_completion(name) : name.size > 1 && @options.key?(name) ? name : nil
    return n, false if n
    if name =~ /\Ano-([a-zA-Z0-9][a-zA-Z0-9_-]+)\z/
      n = completion ? long_option_completion($1) : name.size > 1 && @options.key?(name) ? name : nil
      return n, true if n and (@options[n].may_not_take_argument? or @options[n].format == :boolean)
    end
    name2 = name.gsub(/_/, "-")
    n = completion ? long_option_completion(name2) : name.size > 1 && @options.key?(name2) ? name2 : nil
    return n, false if n and @options[n].underscore_is_hyphen
    if name2 =~ /\Ano-([a-zA-Z0-9][a-zA-Z0-9_-]+)\z/
      n = completion ? long_option_completion($1) : name.size > 1 && @options.key?(name2) ? name2 : nil
      return n, true if n and @options[n].underscore_is_hyphen and (@options[n].may_not_take_argument? or @options[n].format == :boolean)
    end
    raise UnknownOption, "unknown option: #{name}"
  end

  # == 長いオプション名の補完
  # opt:: オプション名
  # === 戻り値
  # オプション名 / nil(未知のオプション)
  # === 例外
  # AmbiguousOption
  def long_option_completion(opt)
    return opt if @options.key? opt
    candidate = @options.keys.sort.select{|k| opt == k[0, opt.size]}
    raise AmbiguousOption, "ambiguous option: #{opt} (candidate are #{candidate.join(", ")})" if candidate.size > 1
    return nil if candidate.empty? or not @options[candidate.first].completion
    return candidate.first
  end

  # = オプション定義
  class Option
    # == 初期化
    # args:: オプション名(String) のリスト、オプションの属性(Hash)
    def initialize(*args)
      name = args.dup
      if name.last.is_a? Hash
        attr = name.pop
      else
        attr = {}
      end
      raise "no option name: #{args.inspect}" if name.empty?
      argument = nil
      @usage_name = name
      @name = name.to_a.map do |n|
        unless n =~ /\A([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9_-]+)(\[?=.*)?\z/
          raise "invalid option name: #{n.inspect}"
        end
        n = $1
        argument = $2.nil? ? nil : $2 =~ /\A\[/ ? :optional : true
        n
      end
      @argument = attr.key?(:argument) ? attr[:argument] : argument
      @format = attr.key?(:format) ? attr[:format] : @argument ? true : nil
      @default = attr[:default]
      @description = attr[:description]
      @multiple = attr.key?(:multiple) ? attr[:multiple] : :last
      @completion = attr.key?(:completion) ? attr[:completion] : true
      @underscore_is_hyphen = attr[:underscore_is_hyphen]
      @in_config = attr.key?(:in_config) ? attr[:in_config] : true
      @proc = attr[:proc]
      @pre_proc = attr[:pre_proc]
      @value = @default
    end
    attr_reader :name, :argument, :format, :default, :description, :multiple
    attr_reader :completion, :underscore_is_hyphen, :in_config, :proc, :pre_proc
    attr_reader :usage_name
    attr_accessor :value

    def may_not_take_argument?
      argument == false or argument == :optional or (argument.nil? and !format)
    end
  end

end
