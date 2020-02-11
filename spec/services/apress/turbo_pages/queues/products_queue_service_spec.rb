require 'spec_helper'

describe Apress::TurboPages::Queues::ProductsQueueService do
  let!(:region) { create :region, name: 'Москва', name_lat: 'msk' }

  subject { described_class.new(region_id: region.id) }

  let(:logger) { subject.send(:logger) }

  def ids_in_queue
    subject.send(:redis).smembers(region.id).map(&:to_i)
  end

  before do
    allow_any_instance_of(Sysloggable::Logger).to receive(:info)
    allow_any_instance_of(Sysloggable::Logger).to receive(:warn)
  end

  context '#fill' do
    before do
      subject.fill(products_ids)
      allow(Redis.current).to receive(:spop).and_return(products_ids)
    end

    context 'when products_ids present' do
      let!(:products_ids) { [1, 2, 2, 3] }
      it { expect(ids_in_queue).to match_array [1, 2, 3] }
    end

    context 'when products_ids blank' do
      let!(:products_ids) { [] }
      it { expect(ids_in_queue).to eq [] }
    end
  end

  context '#save_date' do
    context 'when date is current day' do
      before { subject.save_date }

      it do
        expect(subject.send(:date)).to eq Date.current.to_s
        expect(subject.send(:logger)).to have_received(:info)
      end
    end

    context 'when was set other date' do
      before { subject.save_date('2019-01-01') }
      it { expect(subject.send(:date)).to eq '2019-01-01' }
    end
  end

  context '#delay_interval' do
    context 'when default interval days' do
      it { expect(subject.delay_interval).to eq 1 }
    end

    context 'when last saved date today' do
      before { subject.save_date(Date.today) }
      it { expect(subject.delay_interval).to eq 1 }
    end

    context 'when lase saved date yesterday' do
      before { subject.save_date(Date.yesterday) }
      it { expect(subject.delay_interval).to eq 2 }
    end
  end
end
