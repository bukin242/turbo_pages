module Apress
  module TurboPages
    module Queues
      class ProductsQueueService
        attr_reader :region_id, :filled_count, :existed_count

        include ::Sysloggable::InjectLogger(
          ident: "#{Rails.application.config.turbo_pages[:log_prefix]}_turbo_pages"
        )

        REDIS_KEY = 'turbo_pages:products'.freeze
        DEFAULT_INTERVAL_DAYS = 1

        def initialize(region_id:)
          @region_id = region_id
          @filled_count = 0
          @existed_count = total_count
        end

        def fill(products_ids)
          @filled_count += redis.sadd(region_id, products_ids) if products_ids.present?
          @filled_count
        end

        def select(count)
          ids = redis.spop(region_id, count)
          ids_count = ids.size

          return ids if ids_count.zero?

          msg = "COUNT - drop: #{ids_count}"
          logger.info('', operation: 'products_drop', region_id: region_id, msg: msg)

          ids.map!(&:to_i)
        end

        def save_date(date = Date.current)
          redis.set("last_save_date:#{region_id}", date)

          msg = "COUNT - filled: #{filled_count}, existed: #{existed_count}, total: #{total_count}, save date: #{date}"
          logger.info('', operation: 'products_fill', region_id: region_id, msg: msg)

          date
        end

        def delay_interval
          return @interval if defined?(@interval)
          return DEFAULT_INTERVAL_DAYS unless date

          current = Date.current
          @interval = (current - date.to_date).to_i + DEFAULT_INTERVAL_DAYS

          if @interval > DEFAULT_INTERVAL_DAYS
            msg = "DATE - saved: #{date}, current: #{current}"
            logger.warn(msg, operation: 'products_fill', region_id: region_id)
          end

          @interval
        end

        def total_count
          redis.scard(region_id)
        end

        private

        def date
          @date ||= redis.get("last_save_date:#{region_id}")
        end

        def redis
          @redis ||= ::Redis::Namespace.new(REDIS_KEY, redis: TurboPages.config.redis)
        end
      end
    end
  end
end
