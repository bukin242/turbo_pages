require 'spec_helper'

describe Apress::TurboPages::XmlTemplateService do
  let!(:inside_trait) { create :trait, name: 'Доставка', inside: true }
  let!(:inside_trait_value) { create :trait_value, trait: inside_trait }
  let!(:trait) { create :trait }
  let!(:trait_value) { create :trait_value, trait: trait }
  let!(:product_image) { create :product_image, product: product }
  let!(:region) { product.company.products_region }
  let(:service) { described_class.new(region_id: region.id, products: [product]) }

  context '#call' do
    let(:view) { ActionView::Base.new }
    let(:decorated_product) { product.decorate }

    before do
      allow(described_class).to receive(:view).and_return(view)
      allow(view).to receive(:render).and_return('')

      create :trait_product, product: product, trait_value: inside_trait_value, trait: inside_trait
      create :trait_rubric, trait: trait, rubric: product.rubric
      create :trait_product, product: product, trait_value: trait_value, trait: trait
    end

    context 'when accepted and published product' do
      context 'when product description is present' do
        let(:product) { create :normal_product, description: 'asd' * 10 }

        it do
          service.call {}

          expect(view).to have_received(:render).with(
            template: 'apress/turbo_pages/item',
            formats: :xml,
            locals: {
              region: region,
              product: decorated_product,
              images: [product_image],
              traits: {
                trait => [trait_value]
              },
              product_description_expanded:
                decorated_product.description.size <= described_class::DESCRIPTION_LENGTH_HIDE,
              product_pickup: service.send(:product_pickup?, decorated_product),
              product_deliveries: service.send(:product_deliveries?, decorated_product)
            }
          )
        end
      end

      context 'when product description is nil' do
        let(:product) { create :normal_product, description: nil }

        it do
          service.call {}

          expect(view).to have_received(:render).with(
            template: 'apress/turbo_pages/item',
            formats: :xml,
            locals: {
              region: region,
              product: decorated_product,
              images: [product_image],
              traits: {
                trait => [trait_value]
              },
              product_description_expanded: nil,
              product_pickup: service.send(:product_pickup?, decorated_product),
              product_deliveries: service.send(:product_deliveries?, decorated_product)
            }
          )
        end
      end
    end

    context 'when unpublished product' do
      let(:product) do
        create :normal_product, description: 'asd' * 10, public_state: ::Product::PUBLIC_STATE_UNPUBLISHED
      end

      it do
        expect(service).to_not receive(:product_images).with(decorated_product)
        expect(service).to_not receive(:product_traits).with(decorated_product)
        expect(service).to_not receive(:product_pickup?).with(decorated_product)
        expect(service).to_not receive(:product_deliveries?).with(decorated_product)

        service.call {}

        expect(view).to have_received(:render).with(
          template: 'apress/turbo_pages/item_delete',
          formats: :xml,
          locals: {
            region: region,
            product: decorated_product
          }
        )
      end
    end
  end
end
