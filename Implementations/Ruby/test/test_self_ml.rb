require "test/unit"
require "self-ml"

class TestSelfML < Test::Unit::TestCase
  def parse(string)
    SelfML.parse(string)
  end

  def test_single_literals
    assert_equal([:test], parse("test"))
    assert_equal([:awesome], parse("awesome"))
  end

  def test_numbers
    assert_equal([1], parse("1"))
    assert_equal([1234], parse("1234"))
  end

  def test_brackets
    assert_equal(["This is a test"], parse("[This is a test]"))
    assert_equal(["This is pretty cool"], parse("[This is pretty cool]"))
  end

  def test_backticks
    assert_equal(["This is a test"], parse("`This is a test`"))
    assert_equal(["This is a ` test"], parse("`This is a `` test`"))
    assert_equal([""], parse("``"))
  end

  def test_groups
    assert_equal([[:test]], parse("(test)"))
    assert_equal([[:test, :awesome]], parse("(test awesome)"))
  end

  def test_recursive_groups
    assert_equal([[:test, [:awesome]]], parse("(test (awesome))"))
    assert_equal([[:test, [1, 2, 3], [:qwer, :asdf, :zxcv]]], parse("(test (1 2 3) (qwer asdf zxcv))"))
    assert_equal([[1, 2, 3, 4], [5, 6, 7, 8]], parse("(1 2 3 4) (5 6 7 8)"))
  end
end
