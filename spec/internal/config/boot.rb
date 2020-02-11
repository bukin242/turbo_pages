require 'rails'
%w(active_record action_controller action_view).each { |mod| require "#{mod}/railtie" }
require 'protected_attributes'

ActiveSupport::Deprecation.silenced = true

require 'apress/turbo_pages'
require 'combustion'

Combustion::Application.configure_for_combustion
Combustion::Database::Reset.call if ENV['DATABASE_RESET'].to_s == 'true'
Combustion::Application.load_tasks
