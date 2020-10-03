# Dispatchable

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/dispatchable`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem "dispatchable", github: "ky-s/dispatchable", branch: "main"

```

And then execute:

    $ bundle install


## Usage

```
module MyModule
  extend Dispatchable

  define_dispatcher something, rules: {
    { conditions ... } => proper,
    { conditions ... } => proper,
    :
  }
end

MyModule.dispatch_something(concrete_case)
# => returns dispatched proper
```

### arguments:
#### label:
label is target of `dispatch`.
It is used for method name.
It can be omitted.

#### rules:
Hash of rules contain `conditions` and `proper`.
`conditions` is `Hash` of keys and the conditions.
`conditions` can be nested.

`Mathcer#match?` is used to match conditions.

Use appropriate matching method for condition class.

| Object | matching method | description |
| --- | --- | --- |
| `Regexp` | `#match?(value)` | only concrete_case is `String` |
| `String` | `#match?(value)` | only concrete_case is `Regexp` |
| `Range` | `#cover?(value)` | - |
| `Enumerable` | `#include?(value)` | - |
| `Proc`, `Method` | `#call(value)` | it should returns true/false. |
| `:any` (`Symbol`) | - | always true |
| Others | `#==(value)` |  |

`proper` can be any objects.

### obtains:
  Defined dispatching method that follow rules given.

  It takes one `Hash` argument.
  It is concrete case for apply rules.

  If more than one condition is matched,
  first one found will be dispatched.
  
  If any conditions are not matched, returns `nil`.

### examples:
```
define_dispatcher rules: {
  { x: 10...20 } => 10,
  { x: 20...30 } => 23,
  { x: 30...40 } => 36,
  { x: 40...50 } => 41,
}

extended_object.dispatch(x: 13)
# => 10
```

```
define_dispatcher "class", rules: {
  { value: ->(val) { val.is_a?(Integer) } } => Integer,
  { value: ->(val) { val.is_a?(Float)   } } => Float,
  { value: ->(val) { val.is_a?(String)  } } => String
}

extended_object.dispatch_class(10)
# => Integer
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/dispatchable. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/dispatchable/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Dispatchable project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/dispatchable/blob/master/CODE_OF_CONDUCT.md).
