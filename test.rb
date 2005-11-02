#!/usr/local/bin/ruby
# $Id: test.rb,v 1.4 2005-11-02 00:48:50 tommy Exp $
# Copyright (C) 2004 TOMITA Masahiro
# tommy@tmtm.org
#

require "test/unit"
require "./optconfig.rb"

class TC_OptConfig < Test::Unit::TestCase
  def setup()
    @o = OptConfig.new
  end
  def teardown()
  end

  def test_noarg()
    @o.options = {
      "a" => nil,
    }
    assert_equal(0, @o.parse(["a","b","c"]))
    assert_equal(nil, @o["a"])

    assert_equal(1, @o.parse(["-a","b","c"]))
    assert_equal(true, @o["a"])

    assert_equal(1, @o.parse(["--a","b","c"]))
    assert_equal(true, @o["a"])
  end

  def test_needarg()
    @o.options = {
      "a" => true,
    }
    assert_equal(0, @o.parse(["a","b","c"]))
    assert_equal(nil, @o["a"])

    assert_raises(OptConfig::Error){@o.parse(["-a"])}

    assert_equal(2, @o.parse(["-a", "b", "c"]))
    assert_equal("b", @o["a"])

    assert_equal(1, @o.parse(["-ab", "c"]))
    assert_equal("b", @o["a"])

    assert_equal(1, @o.parse(["--a=b","c"]))
    assert_equal("b", @o["a"])

    assert_equal(2, @o.parse(["--a", "b","c"]))
    assert_equal("b", @o["a"])

    assert_equal(1, @o.parse(["--a=","b","c"]))
    assert_equal("", @o["a"])
  end

  def test_long_noarg()
    @o.options = {
      "long" => nil,
    }
    assert_equal(0, @o.parse(["long","b","c"]))
    assert_equal(nil, @o["long"])

    assert_raises(OptConfig::Error){@o.parse(["-long","b","c"])}

    assert_equal(1, @o.parse(["--long","b","c"]))
    assert_equal(true, @o["long"])
  end

  def test_long_needarg()
    @o.options = {
      "long" => true,
    }
    assert_equal(0, @o.parse(["long","b","c"]))
    assert_equal(nil, @o["long"])

    assert_raises(OptConfig::Error){@o.parse(["--long"])}

    assert_equal(2, @o.parse(["--long","b","c"]))
    assert_equal("b", @o["long"])

    assert_equal(1, @o.parse(["--long=b","c"]))
    assert_equal("b", @o["long"])

    assert_equal(1, @o.parse(["--long=","b","c"]))
    assert_equal("", @o["long"])

    assert_raises(OptConfig::Error){@o.parse(["-long","b","c"])}
  end

  def test_regexp()
    @o.options = {
      "long" => /^abc$/
    }
    assert_equal(2, @o.parse(["--long", "abc", "def"]))
    assert_equal("abc", @o["long"])

    assert_raises(OptConfig::Error){@o.parse(["--long", "xyz", "def"])}

    assert_equal(1, @o.parse(["--long=abc", "def"]))
    assert_equal("abc", @o["long"])

    assert_raises(OptConfig::Error){@o.parse(["--long=xyz", "def"])}
  end

  def test_multioption()
    @o.options = {
      "a" => nil,
      "b" => nil,
    }
    assert_equal(2, @o.parse(["-a", "-b", "c"]))
    assert_equal(true, @o["a"])
    assert_equal(true, @o["b"])

    assert_equal(1, @o.parse(["-ab", "c"]))
    assert_equal(true, @o["a"])
    assert_equal(true, @o["b"])
  end

  def test_multiname()
    @o.options = {
      ["opt1", "opt2"] => true,
    }

    assert_equal(1, @o.parse(["--opt2=abc"]))
    assert_equal("abc", @o["opt1"])
    assert_equal("abc", @o["opt2"])
  end

  def test_parseB()
    @o.options = {
      "a" => true,
      "opt" => nil,
    }
    arg = ["-a", "b", "--opt", "c"]
    assert_equal(3, @o.parse!(arg))
    assert_equal("b", @o["a"])
    assert_equal(true, @o["opt"])
    assert_equal(["c"], arg)
  end

  def test_file()
    require "tempfile"
    tmpf = Tempfile.new("optconfig-test")
    tmpf.puts <<EOS
hoge = fuga
hage=gege
EOS
    tmpf.flush
    @o.options = {}
    @o.file = tmpf.path
    assert_equal(0, @o.parse([]))

    @o.options = {
      "hoge" => true,
      "hage" => true,
      "a" => true,
    }
    assert_equal(2, @o.parse(["-a", "abc"]))
    assert_equal("fuga", @o["hoge"])
    assert_equal("gege", @o["hage"])
    assert_equal("abc", @o["a"])
    tmpf.close!
  end

  def test_idlist()
    require "tempfile"
    tmpf = Tempfile.new("optconfig-test")
    tmpf.puts <<EOS
[opt1]
abc = def
[opt2]
xyz = 987
EOS
    tmpf.flush
    @o.file = tmpf.path
    @o.options = {
      "abc" => true,
      "xyz" => true,
    }
    @o.idlist = ["opt1"]
    assert_equal(0, @o.parse([]))
    assert_equal("def", @o["abc"])
    assert_equal(nil, @o["xyz"])
    @o.idlist = ["opt1", "opt2"]
    assert_equal(0, @o.parse([]))
    assert_equal("def", @o["abc"])
    assert_equal("987", @o["xyz"])
    tmpf.close!
  end

  def test_idlist2()
    require "tempfile"
    tmpf = Tempfile.new("optconfig-test")
    tmpf.puts <<EOS
[opt1]
hoge = [xxx]
abc = def
[opt2]
xyz = 987
EOS
    tmpf.flush
    @o.file = tmpf.path
    @o.options = {
      "abc" => true,
      "xyz" => true,
    }
    @o.idlist = ["opt1"]
    assert_equal(0, @o.parse([]))
    assert_equal("def", @o["abc"])
    assert_equal(nil, @o["xyz"])
    @o.idlist = ["opt1", "opt2"]
    assert_equal(0, @o.parse([]))
    assert_equal("def", @o["abc"])
    assert_equal("987", @o["xyz"])
    tmpf.close!
  end

  def test_file_unknown()
    require "tempfile"
    tmpf = Tempfile.new("optconfig-test")
    tmpf.puts <<EOS
hoge = fuga
unkonwn = xxx
EOS
    tmpf.flush
    @o.options = {"hoge" => true}
    @o.file = tmpf.path
    @o.ignore_unknown_file_option = true
    @o.parse

    @o.ignore_unknown_file_option = false
    assert_raises(OptConfig::Error){@o.parse}
  end

end
