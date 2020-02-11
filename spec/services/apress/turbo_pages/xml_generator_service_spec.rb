require 'spec_helper'

describe Apress::TurboPages::XmlGeneratorService do
  let!(:region) { create :region, name: 'Москва', name_lat: 'msk' }
  let(:service) { described_class.new(region_id: region.id) }
  let(:file_name) { 'test.xml' }
  let(:file_path) { Rails.root.join('fixtures', file_name) }
  let(:product) { create :normal_product, description: 'asd' * 5 }
  let(:logger) { service.send(:logger) }
  let(:product_ids) { [] }
  let(:view) { ActionView::Base.new }

  before do
    allow_any_instance_of(described_class).to receive(:file_name).and_return(file_name)
    allow_any_instance_of(described_class).to receive(:file_path).and_return(file_path)
    Apress::TurboPages::Queues::ProductsQueueService.new(region_id: region.id).fill(product_ids)
    allow(Redis.current).to receive(:spop).and_return(product_ids)

    allow(Apress::TurboPages::XmlTemplateService).to receive(:view).and_return(view)
    allow(view).to receive(:render).and_return('')
  end

  context '.call' do
    context 'when queued products are present' do
      let!(:delivery_trait) { create :trait, name: 'Доставка', inside: true }
      let(:product_ids) { [product.id] }
      let(:expected_generate_file_result) do
        {
          returned_to_queue: 0,
          deleted_count: 0,
          updated_count: 1,
          file_size: File.read(file_path).size,
          file_name: file_name
        }
      end

      context 'when generate' do
        context 'when product is accepted and published' do
          it { expect(service.call).to eq file_name }
          it do
            expect(service).to receive(:log).and_call_original
            expect(service).to receive(:generate_file).and_call_original
            expect(service.send(:service)).to receive(:enqueue).with(file_name)

            service.call
          end
          it do
            info = expected_generate_file_result.map { |name, value| "#{name}: #{value}" }.join(', ')
            msg = "GENERATED - time: 0 minutes, #{info}"
            expect(logger).to receive(:info).with(
              '',
              operation: 'xml_files',
              region_id: region.id,
              msg: msg
            )

            service.call
          end
        end

        context 'when product is accepted and unpublished' do
          let(:product) { create :normal_product, description: 'asd' * 5, public_state: :unpublished }
          let(:expected_generate_file_result) do
            {
              returned_to_queue: 0,
              deleted_count: 1,
              updated_count: 0,
              file_size: File.read(file_path).size,
              file_name: file_name
            }
          end

          it { expect(service.call).to eq file_name }
          it do
            expect(service).to receive(:log).and_call_original
            expect(service).to receive(:generate_file).and_call_original
            expect(service.send(:service)).to receive(:enqueue).with(file_name)

            service.call
          end
          it do
            info = expected_generate_file_result.map { |name, value| "#{name}: #{value}" }.join(', ')
            msg = "GENERATED - time: 0 minutes, #{info}"
            expect(logger).to receive(:info).with(
              '',
              operation: 'xml_files',
              region_id: region.id,
              msg: msg
            )

            service.call
          end
        end
      end

      context 'when different writers' do
        context 'when xml' do
          it do
            expect(File).to receive(:open)

            service.call
          end
        end

        context 'when gzip' do
          before { allow(Rails.application.config.turbo_pages[:api]).to receive(:[]).with(:gzip).and_return(true) }

          it do
            expect(Zlib::GzipWriter).to receive(:open)

            service.call
          end
        end
      end
    end

    context 'when queued products are not present' do
      it { expect(service.call).to eq nil }
      it do
        expect(service).not_to receive(:log)
        expect(service.send(:service)).not_to receive(:enqueue)

        service.call
      end
    end
  end
end
