module Apress
  module TurboPages
    class SuitableProductsFinder
      attr_reader :region_id

      DATA_BATCH_SIZE = 5_000
      CREATED_LT_INTERVAL = '2 weeks'.freeze

      def initialize(region_id:)
        @region_id = region_id
      end

      def call
        ::Product.
          each_row_by_sql(
            sql,
            with_hold: true,
            block_size: DATA_BATCH_SIZE,
            connection: ::ActiveRecord::Base.on(Rails.application.config.turbo_pages[:db_connection]).connection
          ).
          each_slice(DATA_BATCH_SIZE) do |products_ids|
            yield products_ids.map! { |row| row['id'].to_i }
          end
      end

      def self.call(**kwargs, &block)
        new(**kwargs).call(&block)
      end

      private

      def sql
        Apress::TurboPages.config.app_config.fetch(:suitable_products_sql).call(region_id, service.delay_interval)
      end

      def service
        @service ||= Queues::ProductsQueueService.new(region_id: region_id)
      end
    end
  end
end
