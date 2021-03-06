# frozen_string_literal: true

require_relative '../structs/fragment'

module Umwelt::Fragment
  class Mapper < Umwelt::Abstract::Mapper
    def call(data)
      @struct = fill(Struct::Fragment, data)
    end
  end
end
