module MoActions
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_initializer
        template "mo_actions.rb", "config/initializers/mo_actions.rb"
      end

      def remind_about_migrations
        say "\nCopy engine migrations with:\n  bin/rails mo_actions:install:migrations\n  bin/rails db:migrate\n", :green
      end
    end
  end
end
