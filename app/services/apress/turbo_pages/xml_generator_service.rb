module Apress
  module TurboPages
    class XmlGeneratorService
      attr_reader :region_id

      class_attribute :config
      self.config = ::Rails.application.config.turbo_pages

      DATA_BATCH_SIZE = 1_000
      WRAPPER_BYTES = (XmlTemplateService::HEADER + XmlTemplateService::FOOTER).bytesize

      include ::Sysloggable::InjectLogger(
        ident: "#{config[:log_prefix]}_turbo_pages"
      )

      def initialize(region_id:)
        @region_id = region_id
      end

      def self.call(**kwargs)
        new(**kwargs).call
      end

      def call
        return if products_ids.blank?

        log { generate_file }

        service.enqueue(file_name)
        file_name
      end

      private

      def products_ids
        @products_ids ||= products_service.select(config[:max_products])
      end

      def products
        @products ||= products_ids.each_slice(DATA_BATCH_SIZE).flat_map do |ids_batch|
          products = ::Product.where(id: ids_batch)
          ActiveRecord::Associations::Preloader.new(products, config.fetch(:xml_products_preload_associations)).run

          products
        end

        @products
      end

      def generate_file
        file_size = WRAPPER_BYTES
        deleted_count = 0
        updated_count = 0

        writer do |file|
          file.write(XmlTemplateService::HEADER)

          XmlTemplateService.call(region_id: region_id, products: products) do |xml, product|
            xml_part_size = xml.bytesize
            break if (file_size + xml_part_size) >= config[:xml_max_size]

            file_size += xml_part_size

            file.write(xml)

            @products_ids.delete(product.id)

            if config.fetch(:send_turbo_page?).call(product)
              updated_count += 1
            else
              deleted_count += 1
            end
          end

          file.write(XmlTemplateService::FOOTER)
        end

        returned_to_queue = products_service.fill(@products_ids)

        {
          returned_to_queue: returned_to_queue,
          deleted_count: deleted_count,
          updated_count: updated_count,
          file_size: file_size,
          file_name: file_name
        }
      end

      def log
        time_start = Time.current

        result = yield

        time_end = Time.current
        time_diff = ((time_start - time_end) / 1.minutes).ceil

        info = result.map { |name, value| "#{name}: #{value}" }.join(', ')

        msg = "GENERATED - time: #{time_diff} minutes, #{info}"
        logger.info('', operation: 'xml_files', region_id: region_id, msg: msg)
      end

      def file_path
        @file_path ||= File.join(config[:xml_storage], region_id.to_s, file_name)
      end

      def file_name
        @file_name ||= "#{SecureRandom.hex}.#{(config[:api][:gzip] ? 'gz' : 'xml')}"
      end

      def redis
        @redis ||= ::Redis::Namespace.new(REDIS_KEY, redis: TurboPages.config.redis)
      end

      def products_service
        @products_service ||= Queues::ProductsQueueService.new(region_id: region_id)
      end

      def service
        @service ||= Queues::XmlQueueService.new(region_id: region_id)
      end

      def writer(&block)
        config[:api][:gzip] ? Zlib::GzipWriter.open(file_path, &block) : File.open(file_path, 'w', &block)
      end
    end
  end
end
