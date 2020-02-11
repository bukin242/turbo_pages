require 'spec_helper'

describe Apress::TurboPages::SuitableProductsFinder do
  let!(:region) { create :region, name: 'Москва', name_lat: 'msk' }
  let!(:company) { create :company, main_region: region, products_region: region }

  subject do
    products_ids = []
    described_class.call(region_id: region.id) { |ids| products_ids += ids }
    products_ids
  end

  context 'when created products' do
    let!(:product) { Timecop.travel(2.weeks.ago - 1.day) { create :normal_product, company: company } }

    context 'when suitable product' do
      let!(:product_after) { create :normal_product, company: company }

      it { expect(subject).to eq [product.id] }
    end

    context 'when product public state is deleted' do
      let!(:product) { Timecop.travel(2.weeks.ago - 1.day) { create :normal_product, :deleted, company: company } }

      it { expect(subject).to eq [product.id] }
    end

    context 'when product rubric not exists' do
      let!(:product) { Timecop.travel(2.weeks.ago - 1.day) { create :normal_product, company: company } }

      before { product.update_attributes(rubric_id: nil) }

      it { expect(subject).to eq [] }
    end

    context 'when company not accepted' do
      let!(:company) { create :company, main_region: region, products_region: region, state: 'rejected' }

      it { expect(subject).to eq [] }
    end

    context 'when packet not paid' do
      let!(:packet) { create :packet_silver_test }
      let!(:company) { create :company, main_region: region, products_region: region, packet: packet.id }

      it { expect(subject).to eq [] }
    end
  end

  context 'when updated products' do
    before { Timecop.travel(1.day.ago) { product.update_attributes(name: 'test') } }

    context 'when suitable product' do
      let!(:product) { Timecop.travel(1.month.ago) { create :normal_product, company: company } }
      let!(:product_after) { create :normal_product, company: company }

      it { expect(subject).to eq [product.id] }
    end
  end

  context 'when products not found' do
    it { expect(subject).to eq [] }
  end
end
