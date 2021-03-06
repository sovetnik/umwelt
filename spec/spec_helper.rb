# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'umwelt'

require 'fabrication'
require 'faker'
require 'minitest/autorun'
require 'minitest/reporters'

Minitest::Reporters.use! [
  # Minitest::Reporters::SpecReporter.new,
  Minitest::Reporters::ProgressReporter.new
]

class MiniTest::Mock
  def respond_to_missing?(symbol, include_private = false)
    @expected_calls.key?(symbol) || super
  end
end

class Minitest::Test
  make_my_diffs_pretty!

  # method for semantic specs, which returnes AST
  def s(type, *children)
    Parser::AST::Node.new(type, children)
  end

  # HACK: get constant from first describe
  def described_class
    Object.const_get((
      self.class.ancestors -
      MiniTest::Spec.ancestors
    ).last.name)
  rescue NameError
    raise NameError, "described_class:
    Class name '#{class_name}' is not exist.
    Provide a constant to --> describe <-- block above
    for use #described_class method."
  end
end
