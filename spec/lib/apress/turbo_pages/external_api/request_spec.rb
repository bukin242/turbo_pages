require 'spec_helper'

describe Apress::TurboPages::ExternalApi::Client do
  let!(:region) { create :region, name: 'Орел', name_lat: 'orel' }
  let(:service) { described_class.new(region_id: region.id) }

  before do
    allow_any_instance_of(described_class).to receive(:host_id)
      .and_return("http:#{region.name_lat}.test-pulscen.ru:80")
  end

  context '#hosts' do
    subject { VCR.use_cassette('hosts') { service.hosts } }

    it do
      expect(subject[:hosts][0][:host_id]).to eq 'http:orel.test-pulscen.ru:80'
      expect(subject[:hosts][0][:ascii_host_url]).to eq 'http://orel.test-pulscen.ru/'
      expect(subject[:hosts][0][:unicode_host_url]).to eq 'http://orel.test-pulscen.ru/'
    end
  end

  context '#upload_address' do
    context 'when success' do
      let(:upload_address) do
        'https://api.webmaster.yandex.net/v4/upload/turbo/' \
        'J9gmTNnRY_n4Z-Ven5hy4EdoQSV9losNvMFduXhGbfLWiG06JdjfGYvhYg7yIyvGi-mSezej04CDaIvQkc3iww==/'
      end

      subject { VCR.use_cassette('upload_address') { service.upload_address } }

      it { expect(subject[:upload_address]).to eq upload_address }
    end

    context 'when host not verified' do
      let!(:region) { create :region, name: 'Москва', name_lat: 'msk' }
      let(:logger) { service.send(:logger) }

      subject { VCR.use_cassette('upload_address_host_not_verified') { service.upload_address } }
      before { allow(logger).to receive(:error) }

      let!(:result) do
        {
          "host_id" => "http:msk.test-pulscen.ru:80",
          "error_message" => "Host not verified by user",
          "error_code" => "HOST_NOT_VERIFIED"
        }
      end

      it do
        expect(subject).to eq result
        expect(logger).to have_received(:error)
      end
    end

    context 'when invalid user' do
      let(:logger) { service.send(:logger) }

      subject { VCR.use_cassette('upload_address_invalid_user') { service.upload_address } }

      before do
        allow_any_instance_of(described_class).to receive(:user_id).and_return(0)
        allow(logger).to receive(:error)
      end

      let!(:result) do
        {
          "error_code" => "FIELD_VALIDATION_ERROR",
          "error_message" => "Error validating field \"host-id\": This field is required",
          "field_name" => "host-id",
          "field_value" => nil
        }
      end

      it do
        expect(subject).to eq result
        expect(logger).to have_received(:error)
      end
    end
  end

  context '#tasks' do
    subject { VCR.use_cassette('tasks') { service.tasks } }

    let!(:result) do
      [
        {
          "created_at" => "2019-05-23T20:43:13.281+03:00",
          "load_status" => "OK",
          "task_id" => "3cebaf10-7d82-11e9-a489-6f1e33256dd4"
        }
      ]
    end

    it { expect(subject[:tasks]).to eq result }
  end

  context '#task_info' do
    subject { VCR.use_cassette('task_info') { service.task_info('3cebaf10-7d82-11e9-a489-6f1e33256dd4') } }

    let!(:result) do
      {
        "mode" => "DEBUG",
        "load_status" => "OK",
        "turbo_pages" => [
          {
            "link" => "https://orel.test-pulscen.ru/products/brusok_20kh30_2m_51540347",
            "preview" => "https://yandex.ru/turbo?text=turbo",
            "title" => ""
          }
        ],
        "errors" => [],
        "stats" => {
          "pages_count" => 1,
          "errors_count" => 0,
          "warnings_count" => 0
        }
      }
    end

    it { expect(subject).to eq result }
  end

  context '#free_queues_count' do
    subject { VCR.use_cassette('tasks_processing') { service.free_queues_count } }

    it { expect(subject).to eq 9 }
  end

  context '#upload' do
    context 'when valid xml' do
      let(:file) { Rack::Test::UploadedFile.new('spec/internal/fixtures/turbo_page.xml', 'text/xml') }
      subject { VCR.use_cassette('upload') { service.upload(file.read) } }

      it { expect(subject[:task_id]).to eq 'ecb15370-86a9-11e9-b486-49e35bbfd004' }
    end

    context 'when invalid xml' do
      let(:file) { Rack::Test::UploadedFile.new('spec/internal/fixtures/turbo_page_invalid.xml', 'text/xml') }
      subject { VCR.use_cassette('upload_invalid') { service.upload(file.read) } }

      let!(:result) do
        {
          "error_message" => "Expected valid xml, found: \"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n...\"",
          "error_code" => "ENTITY_VALIDATION_ERROR"
        }
      end

      it { expect(subject).to eq result }
    end
  end
end
