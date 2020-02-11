module Apress
  module TurboPages
    module ExternalApi
      class Client
        attr_reader :region_id
        class_attribute :config
        self.config = ::Rails.application.config.turbo_pages

        include ::Sysloggable::InjectLogger(
          ident: "#{config[:log_prefix]}_turbo_pages"
        )

        MAX_QUEUES = 10
        INIT_HEADERS = {
          'Content-Type' => 'application/rss+xml',
          'Authorization' => "OAuth #{config[:api][:token]}"
        }.freeze

        STATE_PROCESSING = 'PROCESSING'.freeze
        STATE_WARNING = 'WARNING'.freeze
        STATE_ERROR = 'ERROR'.freeze
        STATE_OK = 'OK'.freeze

        class RequestError < StandardError; end

        def initialize(region_id:)
          @region_id = region_id
        end

        def hosts
          log :request_hosts do
            get("/user/#{user_id}/hosts")
          end
        end

        def upload_address
          log :request_upload_address do
            get("/user/#{user_id}/hosts/#{host_id}/turbo/uploadAddress")
          end
        end

        def task_info(task_id)
          log :request_task_info do
            get("/user/#{user_id}/hosts/#{host_id}/turbo/tasks/#{task_id}")
          end
        end

        def tasks(params = {})
          log :request_tasks do
            get("/user/#{user_id}/hosts/#{host_id}/turbo/tasks", params)
          end
        end

        def upload(xml_data)
          uri = upload_address[:upload_address]
          return unless uri

          post(uri, xml_data)
        end

        def free_queues_count
          count = tasks(load_status_filter: STATE_PROCESSING)[:count]
          count ? MAX_QUEUES - count : 0
        end

        private

        def user_id
          @user_id ||= config[:api][:user_id]
        end

        def host_id
          @host_id ||= TurboPages.config.hosts[region_id]
        end

        def get(api_path, params = {})
          uri = URI("#{config[:api][:endpoint]}#{api_path}")

          uri.query = URI.encode_www_form(params.merge(mode: config[:api][:mode]))
          request = Net::HTTP::Get.new(uri, INIT_HEADERS)

          response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
            http.request(request)
          end

          raise RequestError, response.body unless response.is_a?(Net::HTTPSuccess)

          JSON.parse(response.body).with_indifferent_access
        end

        def post(api_upload_uri, xml_data)
          uri = URI(api_upload_uri)

          headers = config[:api][:gzip] ? INIT_HEADERS.merge('Content-Encoding' => 'gzip') : INIT_HEADERS
          request = Net::HTTP::Post.new(uri, headers)
          request.body = xml_data

          response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
            http.request(request)
          end

          JSON.parse(response.body).with_indifferent_access
        end

        def log(operation)
          yield
        rescue RequestError => e
          data = JSON.parse(e.message).with_indifferent_access

          msg = "ERROR - code: #{data[:error_code]}, message: #{data[:error_message]}"
          logger.error('', operation: operation, region_id: region_id, msg: msg)
          data
        end
      end
    end
  end
end
