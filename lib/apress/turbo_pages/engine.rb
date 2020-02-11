module Apress
  module TurboPages
    class Engine < ::Rails::Engine
      config.autoload_paths += Dir["#{config.root}/lib"]
      config.i18n.load_path += Dir[config.root.join('locales', '*.{rb,yml}').to_s]

      initializer :apress_turbo_pages, before: :load_init_rb do |app|
        app.config.paths['db/migrate'].concat(config.paths['db/migrate'].expanded) unless app.root.to_s.match root.to_s

        app.config.turbo_pages = YAML.safe_load(
          ERB.new(
            File.read(
              Rails.root.join('config/turbo_pages.yml')
            )
          ).result
        ).with_indifferent_access

        app.config.turbo_pages.merge!(
          max_products: (app.config.turbo_pages[:api][:mode] == 'DEBUG' ? 50 : 10_000),
          max_files: 10,
          xml_max_size: 10.megabytes,
          xml_storage: Rails.root.join('public', 'system', 'turbo_pages', 'send'),
          xml_failures: Rails.root.join('public', 'system', 'turbo_pages', 'failures'),
          product: {
            images_count: 5,
            image_style: :big
          },
          redis: {},
          db_connection: :slave_direct,
          xml_products_preload_associations: %i(images product_properties measure_unit company rubric),
          send_turbo_page?: ->(product) { !product.declined? && product.published? }
        )

        app.config.turbo_pages[:suitable_products_sql] = ->(region_id, delay_interval) do
          <<-SQL.strip_heredoc
          select products.id from products
            join companies on products.company_id = companies.id
            join product_properties on products.id = product_properties.product_id
          where companies.products_region_id = #{region_id} and
                 companies.state = 'accepted' and
                 companies.packet in (#{Apress::Packets::Packet.packets_paid.join(',')}) and
                 products.rubric_id is not Null and
                 products.created_at < (
                   current_date::timestamp
                   - interval '#{Apress::TurboPages::SuitableProductsFinder::CREATED_LT_INTERVAL}'
                 ) and
                 (
                   products.created_at >= (
                     current_date::timestamp
                     - interval '#{Apress::TurboPages::SuitableProductsFinder::CREATED_LT_INTERVAL}'
                     - interval '#{delay_interval} day'
                   ) or
                   (
                     product_properties.updated_at >= (
                       current_date::timestamp
                       - interval '#{delay_interval} day'
                     ) and product_properties.updated_at < current_date::timestamp
                   )
                 )
          SQL
        end

        Apress::TurboPages.make_storage_dirs unless Rails.env.test?
      end

      initializer :apress_turbo_pages_factories, after: "factory_girl.set_factory_paths" do |app|
        FactoryGirl.definition_file_paths.unshift root.join('spec', 'factories') if defined?(FactoryGirl)
      end

      rake_tasks do
        root_path = config.root
        Dir.glob(root_path.join('lib/apress/turbo_pages/tasks/*.rake')) do |filename|
          load(root_path.join(filename))
        end
      end
    end
  end
end
