# frozen_string_literal: false
require 'test/unit'
require 'core_assertions'
require 'nkf'

class TestNKF < Test::Unit::TestCase
  include Test::Unit::CoreAssertions

  EUC_STR = "\xa5\xaa\xa5\xd6\xa5\xb8\xa5\xa7\xa5\xaf\xa5\xc8\xbb\xd8\xb8\xfe\
\xa5\xb9\xa5\xaf\xa5\xea\xa5\xd7\xa5\xc8\xb8\xc0\xb8\xec\
Ruby"

  def test_guess
    str_euc = EUC_STR
    str_jis = NKF.nkf('-j', str_euc)
    assert_equal(::NKF::JIS, NKF.guess(str_jis))
    assert_equal(::NKF::EUC, NKF.guess(str_euc))
  end

  def test_bom
    {
      "-w8" => ["a", Encoding::UTF_8],
      "--oc=UTF-8-BOM" => ["a", Encoding::UTF_8],
      "-w16" => ["\x00a", Encoding::UTF_16BE],
      "-w16L" => ["a\x00", Encoding::UTF_16LE],
      "--oc=UTF-16BE-BOM" => ["\x00a", Encoding::UTF_16BE],
      "--oc=UTF-16LE-BOM" => ["a\x00", Encoding::UTF_16LE],
      "--oc=UTF-16" => ["\xFE\xFF\x00a", Encoding::UTF_16],
      "-w32" => ["\x00\x00\x00a", Encoding::UTF_32BE],
      "-w32L" => ["a\x00\x00\x00", Encoding::UTF_32LE],
      "--oc=UTF-32BE-BOM" => ["\x00\x00\x00a", Encoding::UTF_32BE],
      "--oc=UTF-32LE-BOM" => ["a\x00\x00\x00", Encoding::UTF_32LE],
      "--oc=UTF-32" => ["\x00\x00\xFE\xFF\x00\x00\x00a", Encoding::UTF_32],
    }.each do |opt, (bytes, encoding)|
      result = NKF.nkf(opt, "a")
      assert_equal([bytes.b, encoding], [result.b, result.encoding], opt)
    end
  end

  def test_ruby_dev_36909
    assert_nothing_raised do
      100.times { NKF.nkf("--oc=eucJP-nkf", "foo") }
    end
  end

  def test_ractor
    assert_ractor("#{<<~"begin;"}\n#{<<~'end;'}", require: "nkf")
    STR_EUC = #{EUC_STR.dump}.freeze
    begin;
      STR_JIS = NKF.nkf('-j', STR_EUC).freeze
      r1 = Ractor.new do
        NKF.guess(STR_JIS)
      end
      r2 = Ractor.new do
        NKF.guess(STR_EUC)
      end
      assert_equal(::NKF::JIS, r1.value)
      assert_equal(::NKF::EUC, r2.value)
    end;
  end
end
