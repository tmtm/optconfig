#!/usr/local/bin/ruby
# $Id: test.rb,v 1.1.1.1 2004-09-27 14:29:02 tommy Exp $
# Copyright (C) 2004 TOMITA Masahiro
# tommy@tmtm.org
#

require "./optconfig.rb"

o = OptConfig.new
o.options = {"a" => [nil, nil], "b" => [true, nil], "c" => [/xyz/, "xyz"]}
raise "error" unless o.parse(["-a", "b", "c"]) == 1
raise "error" unless o["a"] == true
begin
  o.parse(["-x"])
  raise "error"
rescue OptConfig::Error
end
begin
  o.parse(["-axyz"])
  raise "error"
rescue OptConfig::Error
end
o.parse(["-abc"])
raise "error" unless o["a"] == true and o["b"] == "c"
o.parse(["-c", "xyz"])
o.parse(["-cxyz"])
o.parse(["-c", "xyz987"])
o.parse(["-cxyz987"])
o.parse(["-c", "123xyz987"])
o.parse(["-c123xyz987"])

o.options = {"long-option1" => [nil, nil], "long-option2" => [true, nil], "long-option3" => [/xyz/, "xyz"]}
raise "error" unless o.parse(["--long-option1", "--long-option2=a", "--long-option3", "xyzabc"]) == 4
raise "error" unless o["long-option1"] == true and o["long-option2"] == "a" and o["long-option3"] == "xyzabc"
raise "error" unless o.parse(["--long-option1", "aaa"]) == 1 and o["long-option3"] == "xyz"
begin
  o.parse(["--long-option1=aaa"])
  raise "error"
rescue OptConfig::Error
end

o.options = {["opt1", "opt2"] => [true, nil]}
o.parse(["--opt2=abc"])
raise "error" unless o["opt1"] == "abc"

require "tempfile"
tmpf = Tempfile.new("optconfig-test")
tmpf.puts "hoge = fuga\nhage=gege\n"
tmpf.flush
o.options = {}
o.file = tmpf.path
o.parse([])
o.options = {"hoge" => [true, nil], "hage" => [true, nil], "a" => [true, nil]}
o.parse(["-a", "abc"])
raise "error" unless o["hoge"] == "fuga" and o["hage"] == "gege" and o["a"] == "abc"
tmpf.close

tmpf = Tempfile.new("optconfig-test")
tmpf.puts "[opt1]\nabc=def\n[opt2]\nxyz=987\n"
tmpf.flush
o.options = {"abc" => [true, nil], "xyz" => [true, nil]}
o.file = tmpf.path
o.idlist = ["opt1"]
o.parse([])
raise "error" unless o["abc"] == "def" and not o.key? "xyz"
o.idlist = ["opt1", "opt2"]
o.parse([])
raise "error" unless o["abc"] == "def" and o["xyz"] == "987"
tmpf.close
