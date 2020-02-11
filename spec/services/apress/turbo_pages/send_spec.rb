require 'spec_helper'

describe Apress::TurboPages::SendService do
  let(:file_name) { 'turbo_page.xml' }
  let!(:region) { create :region, name: 'Москва', name_lat: 'msk' }
  let(:service) { described_class.new(region_id: region.id, file_name: file_name) }
  let(:file_path) { Rails.root.join('fixtures', file_name) }
  let(:result) { {} }
  let(:queue) { Apress::TurboPages::Queues::XmlQueueService.new(region_id: region.id) }
  let(:logger) { service.send(:logger) }

  subject { service.call }

  before do
    allow_any_instance_of(described_class).to receive(:file_path).and_return(file_path)
    allow_any_instance_of(Sysloggable::Logger).to receive(:info)
    allow_any_instance_of(Sysloggable::Logger).to receive(:warn)
    allow_any_instance_of(Sysloggable::Logger).to receive(:error)
    allow(File).to receive(:delete)
    allow(FileUtils).to receive(:mv)
  end

  context '.call' do
    before do
      allow_any_instance_of(Apress::TurboPages::ExternalApi::Client).to receive(:upload_address)
        .and_return(upload_address: HOST)
      allow_any_instance_of(Apress::TurboPages::ExternalApi::Client).to receive(:upload).and_return(result)
      queue.enqueue(file_name)
    end

    context 'when no such file' do
      let(:file_name) { '123.xml' }

      it do
        expect(subject).to eq false
        expect(logger).to have_received(:error)
        expect(queue.total_count).to eq 1
      end
    end

    context 'when retry with error' do
      let(:result) { {error_code: 'TOO_MANY_REQUESTS_ERROR'} }

      it do
        expect(Resque).to receive(:enqueue_at).once.with(anything, ::Apress::TurboPages::SendJob, region.id, file_name)
        expect(subject).to eq nil
        expect(queue.total_count).to eq 1
      end
    end

    context 'when any error' do
      let(:result) { {error_code: 'tralala'} }

      it do
        expect(Resque).not_to receive(:enqueue_at)
        expect(subject).to eq nil
        expect(logger).to have_received(:error).twice
        expect(queue.total_count).to eq 0
        expect(FileUtils).to have_received(:mv)
      end
    end

    context 'when sended file' do
      let(:result) { {task_id: '123'} }

      it do
        expect(Resque).to receive(:enqueue_at)
          .with(anything, ::Apress::TurboPages::SendCheckJob, region.id, '123', file_name)
        expect(subject).to eq '123'
        expect(logger).to have_received(:info)
        expect(queue.total_count).to eq 0
      end
    end
  end

  context '#processing?' do
    let(:stats) { {pages_count: 1, errors_count: 0, warnings_count: 0} }

    before { allow_any_instance_of(Apress::TurboPages::ExternalApi::Client).to receive(:task_info).and_return(result) }

    subject { service.processing?('123') }

    context 'when processing' do
      let(:result) { {load_status: 'PROCESSING'} }
      it { expect(subject).to eq true }
    end

    context 'when ok' do
      let(:result) { {load_status: 'OK', stats: stats} }

      it do
        expect(subject).to eq false
        expect(logger).to have_received(:info)
        expect(File).to have_received(:delete)
      end
    end

    context 'when error' do
      let(:result) { {load_status: 'ERROR', stats: stats} }

      it do
        expect(subject).to eq false
        expect(logger).to have_received(:error).twice
        expect(FileUtils).to have_received(:mv)
      end
    end

    context 'when warning' do
      let(:result) { {load_status: 'WARNING', stats: stats} }

      context 'when result' do
        it do
          expect(subject).to eq false
          expect(logger).to have_received(:warn)
        end
      end

      context 'when stats' do
        before { subject }

        context 'when warnings less failures percent' do
          let(:stats) do
            {pages_count: 100, errors_count: 0, warnings_count: described_class::MOVE_TO_FAILURES_PERCENT - 1}
          end

          it { expect(File).to have_received(:delete) }
        end

        context 'when warnings greater failures percent' do
          let(:stats) do
            {pages_count: 100, errors_count: 0, warnings_count: described_class::MOVE_TO_FAILURES_PERCENT + 1}
          end

          it { expect(FileUtils).to have_received(:mv) }
        end

        context 'when errors greater failures percent' do
          let(:stats) do
            {pages_count: 100, errors_count: described_class::MOVE_TO_FAILURES_PERCENT + 1, warnings_count: 0}
          end

          it { expect(FileUtils).to have_received(:mv) }
        end
      end
    end
  end
end
