require 'spec_helper'

describe Apress::TurboPages::Queues::XmlQueueService do
  let!(:region) { create :region, name: 'Москва', name_lat: 'msk' }

  subject { described_class.new(region_id: region.id) }

  let(:logger) { subject.send(:logger) }

  def files_in_queue
    subject.send(:redis).smembers(region.id)
  end

  before do
    allow_any_instance_of(Sysloggable::Logger).to receive(:info)
    allow_any_instance_of(Sysloggable::Logger).to receive(:warn)
    allow(Redis.current).to receive(:spop).and_return([1])
  end

  context '#enqueue' do
    before { subject.enqueue(files) }

    context 'when files present' do
      let!(:files) { ['1.xml', '2.xml', '2.xml', '3.xml'] }
      it { expect(files_in_queue).to match_array ['1.xml', '2.xml', '3.xml'] }
    end

    context 'when files blank' do
      let!(:files) { '' }
      it { expect(files_in_queue).to eq [] }
    end
  end

  context '#select' do
    let!(:files) { ['1.xml', '2.xml', '3.xml', '4.xml', '5.xml', '6.xml', '7.xml', '8.xml', '9.xml'] }
    before { subject.enqueue(files) }
  end

  context '#delete' do
    let!(:files) { ['1.xml', '2.xml', '3.xml'] }
    before { subject.enqueue(files) }

    context 'when file exists' do
      before { subject.delete('2.xml') }
      it { expect(files_in_queue).to match_array ['1.xml', '3.xml'] }
    end

    context 'when file not exists' do
      before { subject.delete('456.xml') }
      it { expect(files_in_queue).to match_array ['1.xml', '2.xml', '3.xml'] }
    end
  end

  context '#delete' do
    let!(:files) { ['1.xml', '2.xml', '3.xml'] }
    before { subject.enqueue(files) }

    context 'when file exists' do
      before { subject.delete('2.xml') }
      it { expect(files_in_queue).to match_array ['1.xml', '3.xml'] }
    end

    context 'when file not exists' do
      before { subject.delete('456.xml') }
      it { expect(files_in_queue).to match_array ['1.xml', '2.xml', '3.xml'] }
    end
  end

  context '#total_count' do
    context 'when file exists' do
      let!(:files) { ['1.xml', '2.xml', '3.xml'] }
      before { subject.enqueue(files) }
      it { expect(subject.total_count).to eq 3 }
    end

    context 'when file not exists' do
      it { expect(subject.total_count).to eq 0 }
    end
  end

  context '#files_count_to_generate' do
    before { subject.enqueue(files) }

    context 'when files left' do
      let!(:files) { ['1.xml', '2.xml', '3.xml'] }

      it do
        expect(subject.files_count_to_generate).to eq 7
        expect(subject.send(:logger)).to have_received(:info)
      end
    end

    context 'when files left full' do
      let!(:files) { (1..10).to_a.map { |x| "#{x}.xml" } }

      it do
        expect(subject.files_count_to_generate).to eq 0
        expect(subject.send(:logger)).to have_received(:warn)
      end
    end
  end

  context '#each_file_to_send' do
    let!(:files) { ['1.xml', '2.xml', '3.xml'] }

    before do
      allow(subject).to receive(:select).and_return([])

      subject.enqueue(files)
      allow_any_instance_of(Apress::TurboPages::ExternalApi::Client).to receive(:free_queues_count)
        .and_return(api_count)
    end

    context 'when xml files less than api files' do
      let!(:api_count) { 10 }
      before { subject.each_file_to_send }

      it { expect(subject).to have_received(:select).with(3) }
    end

    context 'when xml files greater than api files' do
      let!(:api_count) { 2 }
      before { subject.each_file_to_send }

      it { expect(subject).to have_received(:select).with(2) }
    end
  end
end
