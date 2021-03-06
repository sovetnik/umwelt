# frozen_string_literal: true

require_relative '../../structs/history'

module Umwelt::Project::File
  class Restore < Umwelt::Abstract::File::Restore
    def initialize(
      path: '.umwelt',
      mapper: Umwelt::Project::Mapper
    )
      super
    end

    def call
      @struct = struct parse read full_path
    end

    def full_path
      umwelt_root_path / 'project.json'
    end
  end
end
