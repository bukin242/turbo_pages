module Apress
  module TurboPages
    class ProductsQueueJob
      include Resque::Integration

      queue :turbo_pages_products
      unique

      def self.execute(region_id, products_ids = nil)
        service = Queues::ProductsQueueService.new(region_id: region_id)

        if products_ids
          service.fill(products_ids)
        else
          SuitableProductsFinder.call(region_id: region_id) { |ids| service.fill(ids) }
          service.save_date
        end
      end
    end
  end
end
