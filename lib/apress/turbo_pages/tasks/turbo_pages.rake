namespace :apress do
  namespace :turbo_pages do
    desc 'Заполнение очереди товарами'
    task products_fill: :environment do
      if hosts = ::Apress::TurboPages.config.hosts
        hosts.each_key { |region_id| ::Apress::TurboPages::ProductsQueueJob.enqueue(region_id) }
      end
    end

    desc 'Генерация XML файлов'
    task xml_generate: :environment do
      if hosts = ::Apress::TurboPages.config.hosts
        hosts.each_key do |region_id|
          service = ::Apress::TurboPages::Queues::XmlQueueService.new(region_id: region_id)
          service.files_count_to_generate.times { Resque.enqueue(::Apress::TurboPages::XmlGeneratorJob, region_id) }
        end
      end
    end

    desc 'Отправка XML файлов'
    task send: :environment do
      if hosts = ::Apress::TurboPages.config.hosts
        hosts.each_key do |region_id|
          service = ::Apress::TurboPages::Queues::XmlQueueService.new(region_id: region_id)

          count = 0

          service.each_file_to_send do |file_name|
            Resque.remove_delayed(::Apress::TurboPages::SendJob, region_id, file_name)
            Resque.enqueue_in(
              ::Apress::TurboPages::SendService::DELAY_INTERVAL + count,
              ::Apress::TurboPages::SendJob,
              region_id,
              file_name
            )

            count += 1
          end
        end
      end
    end

    desc 'Заполнение очереди старыми товарами'
    task products_fill_old: :environment do
      hosts = ::Apress::TurboPages.config.hosts
      abort unless hosts

      unless ENV.include?('REGION_ID')
        abort <<-MSG
          rake apress:turbo_pages:products_fill_old REGION_ID=<ид региона>
          доступные: #{hosts}
        MSG
      end

      begin
        region_id = Integer(ENV['REGION_ID'])
      rescue ArgumentError
        abort 'REGION_ID должен быть числом'
      end

      abort 'REGION_ID не определен в config/turbo_pages.yml' unless hosts[region_id]

      batch_size = (ENV['BATCH_SIZE'] || 10_000).to_i
      products_count_in_day = (ENV['COUNT'] || 200_000).to_i

      sql = <<-SQL.strip_heredoc
        select products.id from products
          join companies on products.company_id = companies.id
          join packets on companies.packet = packets.id
          join product_properties on products.id = product_properties.product_id
         where companies.products_region_id = #{region_id} and
               companies.state = 'accepted' and
               packets.is_paid is True and
               products.rubric_id is not Null and
               products.state = 'accepted' and
               products.public_state = '#{Apress::Products::Product::PUBLIC_STATE_PUBLISHED}' and
               products.created_at < (
                 current_date::timestamp
                 - interval '#{::Apress::TurboPages::SuitableProductsFinder::CREATED_LT_INTERVAL}'
               )
         order by products.id desc
      SQL

      products_count = 0
      total_count = 0
      days_offset = (Date.current + 1.day).to_time + 3.minutes

      ::Product.
        each_row_by_sql(
          sql,
          with_hold: true,
          block_size: batch_size,
          connection: ::ActiveRecord::Base.on(Rails.application.config.turbo_pages[:db_connection]).connection
        ).
        each_slice(batch_size) do |products_ids|
          products_ids.map! { |row| row['id'].to_i }

          Resque.remove_delayed(::Apress::TurboPages::ProductsQueueJob, region_id, products_ids)
          Resque.enqueue_at(days_offset, ::Apress::TurboPages::ProductsQueueJob, region_id, products_ids)

          count = products_ids.count
          products_count += count
          total_count += count

          puts "#{days_offset.strftime('%Y-%m-%d')} - will be filled: #{products_count} products."

          if products_count >= products_count_in_day
            products_count = 0
            days_offset += 1.day
          end
        end

      puts "total: #{total_count} products"
    end
  end
end
