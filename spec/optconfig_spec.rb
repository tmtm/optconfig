require "rubygems"
require "spec"
require "tempfile"

require "#{File.dirname __FILE__}/../lib/optconfig"

describe '未知のオプション指定' do
  it 'UnknownOption' do
    opt = OptConfig.new
    opt.option "s", "long"
    proc{opt.parse(["-z"])}.should raise_error(OptConfig::UnknownOption, 'unknown option: z')
    proc{opt.parse(["--hoge"])}.should raise_error(OptConfig::UnknownOption, 'unknown option: hoge')
  end
end

describe '短いオプション名で :argument=>false の場合' do
  before do
    @opt = OptConfig.new
    @opt.option "s", :argument=>false
    @opt.option "x", :argument=>false
  end
  it 'オプション指定で true' do
    @opt.parse(["-s"])
    @opt["s"].should == true
  end
  it 'オプションの次の引数はただの引数' do
    arg = ["-s", "hoge"]
    @opt.parse! arg
    @opt["s"].should == true
    arg.should == ["hoge"]
  end
  it 'オプション名に続いて文字列がある場合は別のオプション' do
    @opt.parse ["-sx"]
    @opt["s"].should == true
    @opt["x"].should == true
  end
end

describe '長いオプション名で :argument=>false の場合' do
  before do
    @opt = OptConfig.new
    @opt.option "long", :argument=>false
  end
  it 'オプション指定で true' do
    @opt.parse(["--long"])
    @opt["long"].should == true
  end
  it 'オプションの次の引数はただの引数' do
    arg = ["--long", "hoge"]
    @opt.parse! arg
    @opt["long"].should == true
    arg.should == ["hoge"]
  end
  it '「=」でオプション引数指定は UnnecessaryArgument' do
    proc{@opt.parse(["--long=hoge"])}.should raise_error(OptConfig::UnnecessaryArgument)
  end
end

describe '短いオプション名で :argument=>true の場合' do
  before do
    @opt = OptConfig.new
    @opt.option "s", :argument=>true
    @opt.option "x", :argument=>false
  end
  it '引数がない指定で ArgumentRequired' do
    proc{@opt.parse ["-s"]}.should raise_error(OptConfig::ArgumentRequired, "argument required: s")
  end
  it 'オプションの次の引数がオプション引数' do
    arg = ["-s", "hoge", "fuga"]
    @opt.parse! arg
    @opt["s"].should == "hoge"
    arg.should == ["fuga"]
  end
  it 'オプション名に続いて文字列がある場合はオプション引数' do
    arg = ["-shoge", "fuga"]
    @opt.parse! arg
    @opt["s"].should == "hoge"
    arg.should == ["fuga"]
  end
end

describe '長いオプション名で :argument=>true の場合' do
  before do
    @opt = OptConfig.new
    @opt.option "long", :argument=>true
  end
  it '引数がない指定で ArgumentRequired' do
    proc{@opt.parse ["--long"]}.should raise_error(OptConfig::ArgumentRequired, "argument required: long")
  end
  it 'オプションの次の引数がオプション引数' do
    arg = ["--long", "hoge", "fuga"]
    @opt.parse! arg
    @opt["long"].should == "hoge"
    arg.should == ["fuga"]
  end
  it '「=」でオプション引数指定可能' do
    arg = ["--long=hoge", "fuga"]
    @opt.parse! arg
    @opt["long"].should == "hoge"
    arg.should == ["fuga"]
  end
end

describe '短いオプション名で :argument=>:optional の場合' do
  before do
    @opt = OptConfig.new
    @opt.option "s", :argument=>:optional
  end
  it '次の引数がない指定で true' do
    @opt.parse ["-s"]
    @opt["s"].should == true
  end
  it 'オプションの次の引数が普通の引数' do
    arg = ["-s", "hoge"]
    @opt.parse! arg
    @opt["s"].should == true
    arg.should == ["hoge"]
  end
  it 'オプション名に続いて文字列がある場合はオプション引数' do
    arg = ["-shoge", "fuga"]
    @opt.parse! arg
    @opt["s"].should == "hoge"
    arg.should == ["fuga"]
  end
end

describe '長いオプション名で :argument=>:optional の場合' do
  before do
    @opt = OptConfig.new
    @opt.option "long", :argument=>:optional
  end
  it '次の引数がない指定で true' do
    @opt.parse ["--long"]
    @opt["long"].should == true
  end
  it 'オプションの次の引数が普通の引数' do
    arg = ["--long", "hoge"]
    @opt.parse! arg
    @opt["long"].should == true
    arg.should == ["hoge"]
  end
  it '「=」でオプション引数指定可能' do
    arg = ["--long=hoge", "fuga"]
    @opt.parse! arg
    @opt["long"].should == "hoge"
    arg.should == ["fuga"]
  end
end

describe ':argument=>nil & :format=>nil の場合' do
  before do
    @opt = OptConfig.new
    @opt.option "s", :argument=>nil, :format=>nil
    @opt.option "long", :argument=>nil, :format=>nil
  end
  it 'オプション引数を取らない' do
    proc{@opt.parse ["--long=hoge"]}.should raise_error(OptConfig::UnnecessaryArgument, 'option argument is unnecessary: long')
  end
end

describe ':argument=>nil & :format=>false の場合' do
  before do
    @opt = OptConfig.new
    @opt.option "s", :argument=>nil, :format=>false
    @opt.option "long", :argument=>nil, :format=>false
  end
  it 'オプション引数を取らない' do
    proc{@opt.parse ["--long=hoge"]}.should raise_error(OptConfig::UnnecessaryArgument, 'option argument is unnecessary: long')
  end
end

describe ':argument=>nil & :format=>true の場合' do
  before do
    @opt = OptConfig.new
    @opt.option "s", :argument=>nil, :format=>true
    @opt.option "long", :argument=>nil, :format=>true
  end
  it 'オプション引数を取る' do
    @opt.parse ["--long=hoge"]
    @opt["long"].should == "hoge"
    proc{@opt.parse ["--long"]}.should raise_error(OptConfig::ArgumentRequired, 'argument required: long')
    @opt.parse ["-shoge"]
    @opt["s"].should == "hoge"
  end
end

describe '同じオプションに短い名前と長い名前の２つを設定した場合' do
  before do
    @opt = OptConfig.new
    @opt.option "s", "long"
  end
  it 'どちらのオプション名も有効' do
    @opt.parse(["-s"])
    @opt["s"].should == true
    @opt["long"].should == true
    @opt.parse(["--long"])
    @opt["s"].should == true
    @opt["long"].should == true
  end
end

describe '同じオプションに長い名前２つを設定した場合' do
  before do
    @opt = OptConfig.new
    @opt.option "long1", "long2"
  end
  it 'どちらのオプション名も有効' do
    @opt.parse(["--long1"])
    @opt["long1"].should == true
    @opt["long2"].should == true
    @opt.parse(["--long2"])
    @opt["long1"].should == true
    @opt["long2"].should == true
  end
end

describe '不正なオプション名を設定した場合' do
  it 'RuntimeError が発生する' do
    opt = OptConfig.new
    proc{opt.option "-abc"}.should raise_error(RuntimeError, 'invalid option name: "-abc"')
  end
end

describe ':format=>Integer を指定した場合' do
  before do
    @opt = OptConfig.new
    @opt.option "s", :format=>Integer
  end
  it '数字の引数は正当' do
    @opt.parse(["-s123"])
    @opt["s"].should == 123
  end
  it '文字列引数はエラー' do
    proc{@opt.parse(["-sabc"])}.should raise_error(OptConfig::InvalidArgument, 'invalid argument for option `s\': not integer: abc')
  end
  it '引数なしはエラー' do
    proc{@opt.parse(["-s"])}.should raise_error(OptConfig::ArgumentRequired, 'argument required: s')
  end
end

describe ':format=>:boolean を指定した場合' do
  before do
    @opt = OptConfig.new
    @opt.option "s", :format=>:boolean
  end
  it '1, true, enable, yes, y, on が true になる' do
    @opt.parse(["-s","1"])
    @opt["s"].should == true
    @opt.parse(["-s","true"])
    @opt["s"].should == true
    @opt.parse(["-s","enable"])
    @opt["s"].should == true
    @opt.parse(["-s","yes"])
    @opt["s"].should == true
    @opt.parse(["-s","y"])
    @opt["s"].should == true
    @opt.parse(["-s","on"])
    @opt["s"].should == true
  end
  it '0, false, disable, no, n, off が false になる' do
    @opt.parse(["-s","0"])
    @opt["s"].should == false
    @opt.parse(["-s","false"])
    @opt["s"].should == false
    @opt.parse(["-s","disable"])
    @opt["s"].should == false
    @opt.parse(["-s","no"])
    @opt["s"].should == false
    @opt.parse(["-s","n"])
    @opt["s"].should == false
    @opt.parse(["-s","off"])
    @opt["s"].should == false
  end
  it '不正な値で InvalidArgument 例外になる' do
    proc{@opt.parse(["-s", "x"])}.should raise_error(OptConfig::InvalidArgument, 'invalid boolean value: s')
  end
end

describe ':format=>:boolean & :argument=>:optional の場合' do
  before do
    @opt = OptConfig.new
    @opt.option "s", "long", :format=>:boolean, :argument=>:optional
  end
  it 'オプション引数なしで true になる' do
    @opt.parse(["--long"])
    @opt["long"].should == true
    @opt.parse(["-s"])
    @opt["long"].should == true
  end
  it '"--no-" prefix で false になる' do
    @opt.parse(["--no-long"])
    @opt["long"].should == false
  end
  it '1文字のオプションには "--no-" prefix はつけられない' do
    proc{@opt.parse(["--no-s"])}.should raise_error(OptConfig::UnknownOption)
  end
end

describe ':format=>:boolean & :argument=>false の場合' do
  before do
    @opt = OptConfig.new
    @opt.option "s", "long", :format=>:boolean, :argument=>false
  end
  it 'オプション引数なしで true になる' do
    @opt.parse(["--long"])
    @opt["long"].should == true
    @opt.parse(["-s"])
    @opt["long"].should == true
  end
  it '"--no-" prefix で false になる' do
    @opt.parse(["--no-long"])
    @opt["long"].should == false
  end
  it '1文字のオプションには "--no-" prefix はつけられない' do
    proc{@opt.parse(["--no-s"])}.should raise_error(OptConfig::UnknownOption)
  end
end

describe ':format=>:boolean & argument=>true の場合' do
  before do
    @opt = OptConfig.new
    @opt.option "s", "long", :format=>:boolean, :argument=>true
  end
  it '"--no-long=true" で false になる' do
    @opt.parse(["--no-long=true"])
    @opt["long"].should == false
    @opt.parse(["--no-long", "true"])
    @opt["long"].should == false
  end
  it '"--no-long=false" で true になる' do
    @opt.parse(["--no-long=false"])
    @opt["long"].should == true
    @opt.parse(["--no-long", "false"])
    @opt["long"].should == true
  end
  it '1文字のオプションには "--no-" prefix はつけられない' do
    proc{@opt.parse(["--no-s"])}.should raise_error(OptConfig::UnknownOption)
  end
end

describe ':default を設定した場合' do
  before do
    @opt = OptConfig.new
    @opt.option "s", :format=>true, :default=>"abc"
  end
  it 'オプションを指定すると指定した値になる' do
    @opt.parse(["-s123"])
    @opt["s"].should == "123"
  end
  it 'オプションを指定しないとデフォルト値になる' do
    @opt.parse()
    @opt["s"].should == "abc"
  end
end

describe '未知のオプションの値を取り出そうとした場合' do
  it 'UnknownOption 例外になる' do
    opt = OptConfig.new
    proc{opt["hoge"]}.should raise_error(OptConfig::UnknownOption, 'unknown option: hoge')
  end
end

describe '長いオプションが途中まで指定された場合' do
  before do
    @opt = OptConfig.new
    @opt.option "longhoge"
    @opt.option "longfuga"
  end
  it '曖昧でなければ補完する' do
    @opt.parse(["--longh"])
    @opt["longhoge"].should == true
    @opt["longfuga"].should == nil
  end
  it '曖昧であれば AmbiguousOption 例外になる' do
    proc{@opt.parse(["--long"])}.should raise_error(OptConfig::AmbiguousOption, 'ambiguous option: long (candidate are longfuga, longhoge)')
  end
  it ':completion=>false 指定時は補完されない' do
    opt = OptConfig.new
    opt.option "longhoge", :completion=>false
    opt.option "longfuga"
    proc{opt.parse(["--longh"])}.should raise_error(OptConfig::UnknownOption, 'unknown option: longh')
  end
end

describe '説明がないオプションの #usage' do
  it '出力されない' do
    opt = OptConfig.new
    opt.option "x"
    opt.usage.should == ""
  end
end

describe '短いオプションの #usage' do
  it '出力される' do
    opt = OptConfig.new
    opt.option "x", :description=>"x option description"
    opt.usage.should == <<EOS
  -x                      x option description
EOS
  end
end

describe '長いオプションの #usage' do
  it '出力される' do
    opt = OptConfig.new
    opt.option "long", :description=>"long option description"
    opt.usage.should == <<EOS
  --long                  long option description
EOS
  end
end

describe '短いオプションと長いオプションの混在 #usage' do
  it '出力される' do
    opt = OptConfig.new
    opt.option "x", :description=>"x option description"
    opt.option "long", :description=>"long option description"
    opt.usage.should == <<EOS
  -x                      x option description
  --long                  long option description
EOS
  end
end

describe '短い名前と長い名前を持つオプションの #usage' do
  it '同じ行に出力される' do
    opt = OptConfig.new
    opt.option "x", "long", :description=>"option description"
    opt.usage.should == <<EOS
  -x, --long              option description
EOS
  end
end

describe '説明が複数行のオプションの #usage' do
  it '正しくインデントされる' do
    opt = OptConfig.new
    opt.option "long", :description=>"long option\nhogehoge\nfugafuga"
    opt.usage.should == <<EOS
  --long                  long option
                          hogehoge
                          fugafuga
EOS
  end
end

describe 'オプション名が長い場合の #usage' do
  it '説明が次の行に送られる' do
    opt = OptConfig.new
    opt.option "x"
    opt.option "s", "longlonglonglonglonglong", :description=>"option description"
    opt.usage.should == <<EOS
  -s, --longlonglonglonglonglong
                          option description
EOS
  end
end

describe 'オプション説明中に %s があった場合' do
  before do
    @opt = OptConfig.new
    @opt.option "s", :format=>true, :default=>"123", :description=>"short option (%s)"
  end
  it '#usage で %s がデフォルト値に置換される' do
    @opt.usage.should == "  -s                      short option (123)\n"
  end
  it 'parse 後は、#usage でオプション値に置換される' do
    @opt.parse ["-s", "abc"]
    @opt.usage.should == "  -s                      short option (abc)\n"
  end
end

describe 'オプションじゃない引数の後にオプションが書かれた場合' do
  before do
    @opt = OptConfig.new
    @opt.option "a"
  end
  it 'オプションとみなされる' do
    arg = ["arg", "-a"]
    @opt.parse! arg
    arg.should == ["arg"]
    @opt["a"].should == true
  end
  it '-- の後はオプションではない' do
    arg = ["arg", "--", "-a"]
    @opt.parse! arg
    arg.should == ["arg", "-a"]
    @opt["a"].should == nil
  end
  it ':stop_at_non_option_argument=>true の場合は通常の引数とみなす' do
    opt = OptConfig.new :stop_at_non_option_argument=>true
    opt.option "a"
    arg = ["arg", "-a"]
    opt.parse! arg
    arg.should == ["arg", "-a"]
    opt["a"].should == nil
  end
end

describe OptConfig, '#parse の戻り値' do
  before do
    @opt = OptConfig.new
    @opt.option "a"
    @opt.option "b", :format=>true
  end
  it 'オプションを除いた引数が返る' do
    @opt.parse(["-a", "arg"]).should == ["arg"]
    @opt.parse(["a", "-a", "b"]).should == ["a", "b"]
    @opt.parse(["-abc", "def"]).should == ["def"]
    @opt.parse(["-a", "-b", "hoge", "fuga"]).should == ["fuga"]
  end
  it '-- を含まない' do
    @opt.parse(["--", "-a", "arg"]).should == ["-a", "arg"]
  end
end

describe 'オプションをファイルで指定した場合' do
  before do
    @opt = OptConfig.new
    @opt.option "s", "long", :argument=>true
  end
  it 'オプションがファイルから読み込まれる' do
    tmpf = Tempfile.new "optconfig"
    tmpf.puts <<EOS
# コメント
long = hoge
EOS
    tmpf.close
    @opt.file = tmpf.path
    @opt.parse
    @opt["long"].should == "hoge"
  end
  it '長いオプション名だけ有効' do
    tmpf = Tempfile.new "optconfig"
    tmpf.puts <<EOS
# コメント
s = hoge
EOS
    tmpf.close
    @opt.file = tmpf.path
    @opt.parse
    @opt["long"].should == nil
  end
  it 'オプション名の補完なし' do
    tmpf = Tempfile.new "optconfig"
    tmpf.puts <<EOS
# コメント
lo = hoge
EOS
    tmpf.close
    @opt.file = tmpf.path
    @opt.parse
    @opt["long"].should == nil
  end
end

describe 'section を指定' do
  before do
    @opt = OptConfig.new
    @opt.option "s", "long", :argument=>true
    @opt.option "a", "long2", :argument=>true
  end
  it '指定したIDのセクションのみ読み込まれる' do
    tmpf = Tempfile.new "optconfig"
    tmpf.puts <<EOS
[x]
long = hoge
[y]
long2 = fuga
EOS
    tmpf.close
    @opt.file = tmpf.path
    @opt.section = ["y"]
    @opt.parse
    @opt["long"].should == nil
    @opt["long2"].should == "fuga"
  end
end

describe 'オプション名が --long=value 形式の場合' do
  it '= の前までをオプション名とみなし、オプション引数ありとみなす' do
    opt = OptConfig.new
    opt.option "long=value"
    opt.instance_variable_get(:@options)["long"].argument.should == true
  end
end

describe 'オプション名が --long[=value] 形式の場合' do
  it '= の前までをオプション名とみなし、オプション引数が省略可能とみなす' do
    opt = OptConfig.new
    opt.option "long[=value]"
    opt.instance_variable_get(:@options)["long"].argument.should == :optional
  end
end

describe 'OptConfig#parse!' do
  it '引数の配列が書き換わる' do
    @opt = OptConfig.new
    @opt.option "s"
    a = ["-s", "a"]
    @opt.parse!(a)
    a.should == ["a"]
  end
end

describe 'OptConfig#parse' do
  it '引数の配列が書き換わらない' do
    @opt = OptConfig.new
    @opt.option "s"
    a = ["-s", "a"]
    @opt.parse(a)
    a.should == ["-s", "a"]
  end
end

describe 'OptConfig#ignore_unknown_file_option が true の場合' do
  it 'ファイル中に未知のオプションがあっても無視される' do
    @opt = OptConfig.new
    @opt.ignore_unknown_file_option = true
    @opt.option "s", "long", :argument=>true
    tmpf = Tempfile.new "optconfig"
    tmpf.puts <<EOS
long = hoge
long2 = fuga
EOS
    tmpf.close
    @opt.file = tmpf.path
    @opt.parse
    @opt["long"].should == "hoge"
  end
end

describe 'OptConfig#ignore_unknown_file_option が false の場合' do
  it 'ファイル中に未知のオプションがあれば OptConfig::UnknownOption 例外になる' do
    @opt = OptConfig.new
    @opt.ignore_unknown_file_option = false
    @opt.option "s", "long", :argument=>true
    tmpf = Tempfile.new "optconfig"
    tmpf.puts <<EOS
long = hoge
long2 = fuga
EOS
    tmpf.close
    @opt.file = tmpf.path
    proc{@opt.parse}.should raise_error(OptConfig::UnknownOption, "unknown option: long2")
  end
end

describe 'オプションの二重定義' do
  it 'RuntimeError になる' do
    opt = OptConfig.new
    proc{opt.option "s"; opt.option "s"}.should raise_error(RuntimeError, 'option s is already defined')
  end
end

describe ':multiple 指定なし' do
  it '同じオプションの複数指定時、最後のオプションが有効' do
    opt = OptConfig.new
    opt.option "s", :format=>true
    opt.parse(["-s","123","-s","abc"])
    opt["s"].should == "abc"
  end
end

describe ':multiple=>:last を指定' do
  it '同じオプションの複数指定時、最後のオプションが有効' do
    opt = OptConfig.new
    opt.option "s", :format=>true, :multiple=>:last
    opt.parse(["-s","123","-s","abc"])
    opt["s"].should == "abc"
  end
end

describe ':multiple=>false を指定' do
  it '同じオプションの複数指定でエラー' do
    opt = OptConfig.new
    opt.option "s", :format=>true, :multiple=>false
    proc{opt.parse(["-s","123","-s","abc"])}.should raise_error(OptConfig::DuplicatedOption, "duplicated option: s")
  end
end

describe ':multiple=>true を指定' do
  it '同じオプションの複数指定で配列が返る' do
    opt = OptConfig.new
    opt.option "s", :format=>true, :multiple=>true
    opt.parse(["-s","123","-s","abc"])
    opt["s"].should == ["123","abc"]
  end
end

describe ':argument=>true を指定' do
  before do
    @opt = OptConfig.new
    @opt.option "s", "long", :argument=>true
  end
  it '長いオプション名: 「=」があれば、それ以降がオプション引数' do
    @opt.parse(["--long=hoge"])
    @opt["long"].should == "hoge"
  end
  it '短いオプション名: オプション名以降に文字列があれば、それがオプション引数' do
    @opt.parse(["-shoge"])
    @opt["s"].should == "hoge"
  end
  it '次の引数が「-」で始まっていても、オプション引数' do
    @opt.parse(["--long", "--hoge"])
    @opt["long"].should == "--hoge"
    @opt.parse(["-s", "--hoge"])
    @opt["s"].should == "--hoge"
  end
end

describe ':argument=>false を指定' do
  before do
    @opt = OptConfig.new
    @opt.option "s", "long", :argument=>false
  end
  it 'オプション引数が指定されたらエラー' do
    proc{@opt.parse(["--long=hoge"])}.should raise_error(OptConfig::UnnecessaryArgument, "option argument is unnecessary: long")
  end
  it 'オプションの次の引数はオプション引数でない' do
    arg = ["-s", "hoge"]
    @opt.parse!(arg)
    arg.should == ["hoge"]
    arg = ["--long", "hoge"]
    @opt.parse!(arg)
    arg.should == ["hoge"]
  end
end

describe ':argument=>:optional を指定' do
  before do
    @opt = OptConfig.new
    @opt.option "s", "long", :format=>true, :argument=>:optional
    @opt.option "hoge"
  end
  it '長いオプション名: 「=」があれば、それ以降がオプション引数' do
    @opt.parse(["--long=hoge"])
    @opt["long"].should == "hoge"
  end
  it '長いオプション名: 「=」がなければ、オプション引数なし' do
    @opt.parse(["--long", "hoge"])
    @opt["long"].should == true
  end
  it '短いオプション名: オプション名以降に文字列があれば、それがオプション引数' do
    @opt.parse(["-shoge"])
    @opt["s"].should == "hoge"
  end
  it '短いオプション名: オプション名以降に文字列がなければ、オプション引数なし' do
    @opt.parse(["-s", "hoge"])
    @opt["s"].should == true
  end
end

describe ':underscore_is_hyphen=>true を指定' do
  before do
    @opt = OptConfig.new
    @opt.option "long-opt", :format=>true, :underscore_is_hyphen=>true
  end
  it '--long-opt が --long_opt でも有効' do
    @opt.parse(["--long_opt=hoge"])
    @opt["long-opt"].should == "hoge"
  end
  it 'conf ファイル中の long_opt が有効' do
    tmpf = Tempfile.new "optconfig"
    tmpf.puts <<EOS
long_opt = hoge
EOS
    tmpf.close
    @opt.file = tmpf.path
    @opt.parse
    @opt["long-opt"].should == "hoge"
  end
end

describe ':underscore_is_hyphen=>true で "--no-" prefix の場合' do
  before do
    @opt = OptConfig.new
    @opt.option "long-opt", :format=>:boolean, :argument=>false, :underscore_is_hyphen=>true
  end
  it '--long_opt 指定で true' do
    @opt.parse(["--long_opt"])
    @opt["long-opt"].should == true
  end
  it '--no_long_opt 指定で false' do
    @opt.parse(["--no_long_opt"])
    @opt["long-opt"].should == false
  end
end

describe ':in_config=>false を指定' do
  before do
    @opt = OptConfig.new
    @opt.option "long", :format=>true, :in_config=>false
  end
  it '引数に書けば有効' do
    @opt.parse(["--long", "hoge"])
    @opt["long"].should == "hoge"
  end
  it '設定ファイルに書いても無効' do
    tmpf = Tempfile.new "optconfig"
    tmpf.puts <<EOS
long = hoge
EOS
    tmpf.close
    @opt.file = tmpf.path
    @opt.parse
    @opt["long"].should be_nil
  end
end

describe 'OptConfig.new でデフォルト属性を指定' do
  it 'オプションの属性に適用される' do
    opt = OptConfig.new :argument=>:optional, :completion=>false
    opt.option "s"
    opt.instance_variable_get(:@options)["s"].argument.should == :optional
    opt.instance_variable_get(:@options)["s"].completion.should == false
  end
end

describe ':proc' do
  before do
    @opt = OptConfig.new
    @cnt = 0
    block = proc do |name, opt, arg|
      @cnt += 1
      name.should == "p"
      arg.should == "hoge"
      "fuga"
    end
    @opt.option "p", "proc", :format=>"hoge", :proc=>block
  end
  it 'オプション毎に実行される' do
    @opt.parse(["-p", "hoge", "-p", "hoge"])
    @cnt.should == 2
  end
  it 'ブロックの結果が OptConfig#[] の戻り値になる' do
    @opt.parse(["-p", "hoge"])
    @opt["proc"].should == "fuga"
  end
  it 'オプション引数の正当性確認後に実行される' do
    proc{@opt.parse(["-p", "fuga"])}.should raise_error(OptConfig::InvalidArgument, "invalid argument for option `p': invalid value: fuga")
    @cnt.should == 0
  end
end

describe ':pre_proc' do
  before do
    @opt = OptConfig.new
    @cnt = 0
    block = proc do |name, opt, arg|
      @cnt += 1
      name.should == "p"
      arg == "fuga" ? "hoge" : arg
    end
    @opt.option "p", "proc", :format=>"hoge", :pre_proc=>block
  end
  it 'オプション毎に実行される' do
    @opt.parse(["-p", "hoge", "-p", "hoge"])
    @cnt.should == 2
  end
  it 'ブロックの結果をオプション引数とする' do
    @opt.parse(["-p", "fuga"])
    @opt["p"].should == "hoge"
  end
  it 'オプション引数の正当性確認前に実行される' do
    proc{@opt.parse(["-p", "xxx"])}.should raise_error(OptConfig::InvalidArgument, "invalid argument for option `p': invalid value: xxx")
    @cnt.should == 1
  end
end

describe 'options= でオプション設定' do
  before do
    @opt = OptConfig.new
    @opt.options = {
      "a" => nil,
      "b" => false,
      "c" => true,
      "long" => true,
      "long2" => [true, "abc"],
      "long3" => /abc/,
      ["d", "long4"] => true,
    }
  end
  it 'nil の場合は引数なし' do
    @opt.parse(["-a", "a"]).should == 1
    @opt["a"].should == true
  end
  it 'false の場合は引数なし' do
    @opt.parse(["-b", "a"]).should == 1
    @opt["b"].should == true
  end
  it 'true の場合は引数あり' do
    @opt.parse(["-c", "a"]).should == 2
    @opt["c"].should == "a"
  end
  it '長いオプション名も使用可能' do
    @opt.parse(["--long", "a"]).should == 2
    @opt["long"].should == "a"
  end
  it 'オプションが指定されなくても引数のデフォルト値が有効' do
    @opt.parse(["a"]).should == 0
    @opt["long2"].should == "abc"
  end
  it '引数の形式を指定可能' do
    @opt.parse(["--long3", "bcabcab"]).should == 2
    @opt["long3"].should == "bcabcab"
  end
  it '引数の形式に合わなければエラー' do
    proc{@opt.parse(["--long3", "hogehoge"])}.should raise_error(OptConfig::InvalidArgument, "invalid argument for option `long3': regexp mismatch: hogehoge")
  end
  it '同じオプションに短い名前と長い名前を指定可能' do
    @opt.parse(["-d", "a"]).should == 2
    @opt["long4"].should == "a"
  end
end
