# frozen_string_literal: true

module Umwelt::Tree
  class Imprint < Umwelt::Abstract::Interactor
    expose :written_paths

    def initialize(trunk, location: nil)
      @trunk = trunk
      @location = location
      @written_paths = {}
    end

    def call(semantic_name)
      error! not_clean unless location_clean?

      @trunk.nodes.map do |node|
        write node.semantic(semantic_name)
      end
    end

    private

    def write(semantic)
      path = semantic.path(location: @location)

      path.dirname.mkpath

      count = path.write(semantic.code)

      @written_paths[path] = count
    end

    def location_clean?
      imprint_root.mkpath
      imprint_root.empty?
    end

    def not_clean
      <<~WARN_MESSAGE
        #{imprint_root} contain files.
        Try use another --target, or delete them.
      WARN_MESSAGE
    end

    def imprint_root
      Pathname.pwd / @location
    end
  end
end
