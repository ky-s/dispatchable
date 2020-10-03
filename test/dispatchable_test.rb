require "test_helper"

module DispatchableModule
  extend Dispatchable
end

class DispatchableClass
  extend Dispatchable
end

class DispatchableTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Dispatchable::VERSION
  end

  def test_module_get_dispatch
    DispatchableModule.define_dispatcher rules: {
      { x: 1    } => 10,
      { x: 2    } => 100,
      { x: 3    } => 1000,
      { x: :any } => -1
    }

    assert_equal   10, DispatchableModule.dispatch(x: 1)
    assert_equal  100, DispatchableModule.dispatch(x: 2)
    assert_equal 1000, DispatchableModule.dispatch(x: 3)
    assert_equal(  -1, DispatchableModule.dispatch(x: 4))
  end

  def test_class_get_dispatch
    DispatchableClass.define_dispatcher rules: {
      { x:  0,   y: 0    } => "10".method(:==),
      { x: -1,   y: 0    } => "20".method(:==),
      { x: :any, y: :any } => nil.method(:==)
    }

    assert DispatchableClass.new.dispatch(x:  0, y: 0).call("10")
    assert DispatchableClass.new.dispatch(x: -1, y: 0).call("20")
    assert DispatchableClass.new.dispatch(x: -1, y: -1).call(nil)
  end

  def test_nested_conditions
    DispatchableModule.define_dispatcher :test, rules: {
      { x: 1,    y: { z: 10   }                      } => 10,
      { x: 1,    y: { z: "10" }                      } => 20,
      { x: 1,    y: [20, 22, 24]                     } => 30,
      { x: 1,    y: 20..29                           } => 31,
      { x: 1,    y: { z: -> (z) { z.is_a?(Float) } } } => 40,
      { x: :any, y: { z: /^rege/ }                   } => 50,
      { x: :any, y: :any, z: 1                       } => 60,
      { x: :any, y: "string"                         } => 70,
      { x: :any, y: :any                             } => -1
    }

    assert_equal 10, DispatchableModule.dispatch_test(x: 1, y: { z: 10 })
    assert_equal 20, DispatchableModule.dispatch_test(x: 1, y: { z: "10" })
    assert_equal 30, DispatchableModule.dispatch_test(x: 1, y: 20)
    assert_equal 31, DispatchableModule.dispatch_test(x: 1, y: 21)
    assert_equal 40, DispatchableModule.dispatch_test(x: 1, y: { z: 10.1 })
    assert_equal 50, DispatchableModule.dispatch_test(x: 1, y: { z: "regexp"})
    assert_equal 60, DispatchableModule.dispatch_test(x: 1, y: 1, z: 1)
    assert_equal 70, DispatchableModule.dispatch_test(x: 1, y: /rin/)
    assert_equal(-1, DispatchableModule.dispatch_test(x: 2,  y: { z: 10 }))
  end

  def test_raise_matching_error
    DispatchableModule.define_dispatcher :raise, rules: {
      { x: ->(x) { x.no_method_error } } => :cannot_get_here
    }

    error = assert_raises(Dispatchable::MatchingError) {
      DispatchableModule.dispatch_raise(x: 1)
    }

    assert_match(
      /An error was occured at matching .*undefined method `no_method_error' for 1:Integer/,
      error.message
    )
  end
end
