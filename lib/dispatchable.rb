require "dispatchable/version"

module Dispatchable
  class MatchingError < StandardError; end
  # Define dispatching method.
  #
  # usage:
  # ```
  #   extend Dispatchable
  #
  #   define_dispatcher label, rules: {
  #     { conditions ... } => proper,
  #     { conditions ... } => proper,
  #     :
  #   }
  # ```
  #
  # arguments:
  #   label:
  #     label is target of `dispatch`.
  #     It is used for method name.
  #     It can be omitted.
  #
  #   rules:
  #     Hash of rules contain `conditions` and `proper`.
  #     `conditions` is Hash of keys and the conditions.
  #     `conditions` can be nested.
  #
  #     Mathcer#match? is used to match conditions.
  #     Use appropriate matching method for condition class.
  #
  #       Regexp        ... using #match?(value)
  #       Range         ... using #cover?(value)
  #       Enumerable    ... using #include?(value)
  #       Proc, Method  ... using #call(value), it should returns true/false.
  #       :any (Symbol) ... always true
  #       Hash          ... using Matcher#match? recursively
  #       Others        ... uinsg #==(value)
  #
  #     `proper` can be any objects.
  #
  # obtains:
  #   Defined dispatching method that follow rules given.
  #
  #   It takes one Hash argument.
  #   It is concrete case for apply rules.
  #
  #   If more than one condition is matched,
  #   first one found will be dispatched.
  #
  # examples:
  # ===
  # define_dispatcher rules: {
  #   { x: 10...20 } => 10,
  #   { x: 20...30 } => 23,
  #   { x: 30...40 } => 36,
  #   { x: 40...50 } => 41,
  # }
  #
  # extended_object.dispatch(x: 13)
  # # => 10
  #
  # ===
  # define_dispatcher "class", rules: {
  #   { value: ->(val) { val.is_a?(Integer) } } => Integer,
  #   { value: ->(val) { val.is_a?(Float)   } } => Float,
  #   { value: ->(val) { val.is_a?(String)  } } => String
  # }
  #
  # extended_object.dispatch_class(10)
  # # => Integer
  #
  def define_dispatcher(label = nil, rules:)
    dispatcher_name = ["dispatch", label].compact.join("_")

    define_method(dispatcher_name) do |concrete_case|

      _, proper = rules.detect do |conditions, _|
        Matcher.match?(conditions, concrete_case)
      end

      proper
    end

    if self.class == Module
      module_function dispatcher_name
    end
  end

  module Matcher
    def match?(condition, concrete_case)
      # :any is always match any rules.
      condition == :any and
        return true

      # Nested condition
      if condition.kind_of?(Hash)
        # If concrete_case is not Hash,
        #   that has not met the condition.
        concrete_case.kind_of?(Hash) or
          return false

        return condition.all? do |key, nested_conditions|
          match?(nested_conditions, concrete_case[key])
        end
      end

      # これで十分かどうかわからない
      # 他にも考慮したほうがいいことがあるかも
      begin
        condition.kind_of?(Proc) ||
          condition.kind_of?(Method) and
          return condition.call(concrete_case)

        condition.kind_of?(Regexp) && concrete_case.kind_of?(String) or
          condition.kind_of?(String) && concrete_case.kind_of?(Regexp) and
          return condition.match?(concrete_case)

        condition.kind_of?(Range) and
          return condition.cover?(concrete_case)

        condition.kind_of?(Enumerable) and
          return condition.include?(concrete_case)

        condition == concrete_case

      rescue => e
        raise MatchingError,
          "An error was occured at matching " +
          "(condition, value) = (#{condition.inspect}, #{concrete_case.inspect}). #{e}"
      end
    end

    module_function :match?
  end
end
