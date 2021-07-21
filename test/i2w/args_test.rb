require 'test_helper'

require 'i2w/args'

class I2w::ArgsTest < ActiveSupport::TestCase
  test 'compose result with array' do
    actual = I2w::Args.call([:a, :b, :c, :e], {}) do |on|
      on.a { |r| r.merge(a: "handled") }
      on.b { |r| r.merge(b: "handled") }
      on.d { |r| r.merge(d: "not run") }
      on.missing { |a, r| r.merge(a => "missing") }
    end

    assert_equal({ a: "handled", b: "handled", c: "missing", e: "missing" }, actual)
  end

  test 'mutate result with array' do
    actual = {}

    I2w::Args.call([:a, :b, :c, :e]) do |on|
      on.a { actual[:a] = "handled" }
      on.b { actual[:b] = "handled" }
      on.d { actual[:d] = "not run" }
      on.missing { |a| actual[a] = "missing" }
    end

    assert_equal({ a: "handled", b: "handled", c: "missing", e: "missing" }, actual)
  end

  test 'unhandled with array' do
    assert_raise(I2w::Args::UnprocessedError) do
      I2w::Args.call([:a, :b, :c, :e]) do |on|
        on.a { :ok }
      end
    end
  end

  test 'unhandled with no block' do
    assert_raise(I2w::Args::UnprocessedError) do
      I2w::Args.call([:a])
    end
  end

  test 'with empty arg, raises no error' do
    assert_nil I2w::Args.call(nil)
    assert_nil I2w::Args.call([])
    assert_equal :result, I2w::Args.call({}, :result)
  end

  test 'compose result with hash' do
    actual = I2w::Args.call({ a: 1, b: 2, c: 3, e: 4 }, {}) do |on|
      on.a { |v, r| r.merge(a: "handled #{v}") }
      on.b { |v, r| r.merge(b: "handled #{v}") }
      on.d { |v, r| r.merge(d: "not run") }
      on.missing { |a, v, r| r.merge(a => "missing #{v}") }
    end

    assert_equal({ a: "handled 1", b: "handled 2", c: "missing 3", e: "missing 4" }, actual)
  end

  test 'mutate result with hash' do
    actual = {}

    I2w::Args.call({ a: 1, b: 2, c: 3, e: 4 }) do |on|
      on.a { |v| actual[:a] = "handled #{v}" }
      on.b { |v| actual[:b] = "handled #{v}" }
      on.d { |v| actual[:d] = "not run" }
      on.missing { |a, v| actual[a] = "missing #{v}" }
    end

    assert_equal({ a: "handled 1", b: "handled 2", c: "missing 3", e: "missing 4" }, actual)
  end

  test 'unhandled with hash' do
    assert_raise(I2w::Args::UnprocessedError) do
      I2w::Args.call({a: 1, b: 2}) do |on|
        on.a { :ok }
      end
    end
  end

end