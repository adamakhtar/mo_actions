module MoActions
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_initializer
        template "mo_actions.rb", "config/initializers/mo_actions.rb"
      end

      def print_migration_instructions
        say "Run `bin/rails mo_actions:install:migrations` to copy Mo Actions migrations into your app.", :green
      end
    end
  end
end
