require 'rails'
require 'redis'
require 'active_record'
require 'apress/regions'
require 'apress/traits'
require 'apress/rubrics'
require 'apress/packets'
require 'apress/products'
require 'apress/companies'
require 'apress/turbo_pages'
require 'apress/trait_products'
require 'apress/turbo_pages/version'
require 'apress/turbo_pages/engine'
require 'resque-integration'
require 'sysloggable'
require 'apress/company_abouts'

module Apress
  module TurboPages
    class Configuration
      def redis
        @redis ||= app_config[:redis].present? ? Redis.new(app_config[:redis]) : Redis.current
      end

      def app_config
        @app_config ||= ::Rails.application.config.turbo_pages
      end

      def regions
        @regions ||= ::Region.where(name: app_config[:hosts].keys).pluck(:name, :id).to_h
      end

      def hosts
        @hosts ||= app_config[:hosts].each_with_object({}) do |(region, host), memo|
          memo[regions[region]] = host if regions[region]
        end
      end
    end

    class << self
      def config
        @config ||= Configuration.new
      end

      def make_storage_dirs
        config.regions.each do |_, region_id|
          storage_path = File.join(::Rails.application.config.turbo_pages[:xml_storage], region_id.to_s)
          FileUtils.mkdir_p(storage_path) unless File.directory?(storage_path)

          failures_path = File.join(::Rails.application.config.turbo_pages[:xml_failures], region_id.to_s)
          FileUtils.mkdir_p(failures_path) unless File.directory?(failures_path)
        end
      end
    end
  end
end
