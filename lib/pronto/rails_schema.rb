require 'pronto'
require "pronto/rails_schema/version"

module Pronto
  class RailsSchema < Runner
    def run(patches, _)
      return [] unless patches

      migration_patches = patches
        .select { |patch| detect_added_migration_file(patch) }
      return [] unless migration_patches.any?

      schema_patch = patches.find { |patch| detect_schema_file(patch.new_file_full_path) }
      return generate_messages_for(migration_patches, 'schema.rb') unless changes_detected?(schema_patch)

      structure_patch = patches.find { |patch| detect_structure_file(patch.new_file_full_path) }
      return generate_messages_for(migration_patches, 'structure.sql') unless changes_detected?(structure_patch)
      []
    end

    private

    def generate_messages_for(patches, target)
      patches.map do |patch|
        Message.new(patch.delta.new_file[:path], nil, :warning,
          "Migration file detected, but no changes in #{target}")
      end
    end

    def detect_added_migration_file(patch)
      return unless patch.delta.added?
      /(.*)db[\\|\/]migrate[\\|\/](\d{14}_([_A-Za-z]+)\.rb)$/i =~ patch.delta.new_file[:path]
    end

    def detect_schema_file(path)
      /db[\\|\/]schema.rb/i =~ path.to_s
    end

    def changes_detected?(patch)
      patch && (patch.additions > 0 || patch.deletions > 0)
    end

    def detect_structure_file(path)
      /db[\\|\/]structure.sql/i =~ path.to_s
    end
  end
end