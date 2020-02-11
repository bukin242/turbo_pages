module Apress
  module TurboPages
    class XmlTemplateService
      attr_reader :region, :products

      HEADER = <<-XML.strip_heredoc.freeze
        <?xml version="1.0" encoding="UTF-8"?>
        <rss
          xmlns:yandex="http://news.yandex.ru"
          xmlns:media="http://search.yahoo.com/mrss/"
          xmlns:turbo="http://turbo.yandex.ru"
          version="2.0">
          <channel>
      XML

      FOOTER = <<-XML.strip_heredoc.freeze
          </channel>
        </rss>
      XML

      DEFAULT_XML_TEMPLATE = 'item'.freeze
      DELETE_XML_TEMPLATE = 'item_delete'.freeze
      PICKUP = 'Самовывоз'.freeze
      DESCRIPTION_LENGTH_HIDE = 1200

      def self.view
        return(@view) if defined?(@view)

        @view = ActionView::Base.new(ActionController::Base.view_paths, {})
        @view.class_eval do
          include Apress::Application::SeoHelper
          include Rails.application.routes.url_helpers
        end

        @view
      end

      def initialize(region_id:, products:)
        @region = ::Region.find(region_id)
        @products = products
      end

      def self.call(**kwargs, &block)
        new(**kwargs).call(&block)
      end

      def call
        products.each do |product|
          product = product.decorate

          xml_part = self.class.view.render(
            template: "apress/turbo_pages/#{product_xml_template(product)}",
            formats: :xml,
            locals: locals(product)
          )

          yield xml_part, product
        end
      end

      private

      def product_images(product)
        product.images.first(::Rails.application.config.turbo_pages[:product][:images_count])
      end

      def product_traits(product)
        product.trait_values.accepted.includes(:trait).order(:trait_id, :id).group_by(&:trait).reject do |trait, _|
          trait.inside?
        end
      end

      def product_pickup?(product)
        product.delivery_names.include?(PICKUP)
      end

      def product_deliveries?(product)
        (product.delivery_names - [PICKUP]).present?
      end

      def product_xml_template(product)
        if Apress::TurboPages.config.app_config.fetch(:send_turbo_page?).call(product)
          DEFAULT_XML_TEMPLATE
        else
          DELETE_XML_TEMPLATE
        end
      end

      def default_locals(product)
        {
          region: region,
          product: product
        }
      end

      def locals(product)
        return default_locals(product) if product.declined? || !product.published?

        default_locals(product).merge!(
          images: product_images(product),
          traits: product_traits(product),
          product_description_expanded: product.description && product.description.size <= DESCRIPTION_LENGTH_HIDE,
          product_pickup: product_pickup?(product),
          product_deliveries: product_deliveries?(product)
        )
      end
    end
  end
end
