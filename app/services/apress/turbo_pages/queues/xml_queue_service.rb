module Apress
  module TurboPages
    module Queues
      class XmlQueueService
        attr_reader :region_id

        include ::Sysloggable::InjectLogger(
          ident: "#{Rails.application.config.turbo_pages[:log_prefix]}_turbo_pages"
        )

        REDIS_KEY = 'turbo_pages:xml'.freeze

        def initialize(region_id:)
          @region_id = region_id
        end

        def enqueue(files)
          return files if files.blank?

          redis.sadd(region_id, files)
        end

        def select(count)
          redis.spop(region_id, count)
        end

        def delete(files)
          redis.srem(region_id, files)
        end

        def total_count
          redis.scard(region_id)
        end

        def files_count_to_generate
          count = Rails.application.config.turbo_pages[:max_files] - total_count

          return count if Rails.application.config.turbo_pages[:max_files] == count

          if count.zero?
            msg = "LIMIT FULL - count: #{Rails.application.config.turbo_pages[:max_files]} files"
            logger.warn('', operation: 'xml_files_count', region_id: region_id, msg: msg)
          else
            msg = "FILES TO GENERATE - count: #{count}"
            logger.info('', operation: 'xml_files_count', region_id: region_id, msg: msg)
          end

          count
        end

        def each_file_to_send
          xml_count = total_count
          api_count = ExternalApi::Client.new(region_id: region_id).free_queues_count
          count = [api_count, xml_count].min

          select(count).each do |file_name|
            yield file_name
          end
        end

        private

        def redis
          @redis ||= ::Redis::Namespace.new(REDIS_KEY, redis: TurboPages.config.redis)
        end
      end
    end
  end
end
