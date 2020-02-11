module Apress
  module TurboPages
    class SendService
      attr_reader :region_id, :file_name

      class_attribute :config
      self.config = ::Rails.application.config.turbo_pages

      include ::Sysloggable::InjectLogger(
        ident: "#{config[:log_prefix]}_turbo_pages"
      )

      DELAY_CHECK = 30.minutes
      DELAY_INTERVAL = 10.seconds
      MOVE_TO_FAILURES_PERCENT = 50
      RETRY_WITH_ERROR = 'TOO_MANY_REQUESTS_ERROR'.freeze

      def initialize(region_id:, file_name:)
        @region_id = region_id
        @file_name = file_name
      end

      def self.call(**kwargs)
        new(**kwargs).call
      end

      def call
        unless File.exist?(file_path)
          msg = "FILE DOES NO EXIST - path: #{file_path}"
          logger.error('', operation: 'xml_send', region_id: region_id, msg: msg)
          return false
        end

        result = api.upload(IO.binread(file_path))

        if result[:error_code] == RETRY_WITH_ERROR
          Resque.enqueue_in(DELAY_INTERVAL, ::Apress::TurboPages::SendJob, region_id, file_name)
          return
        end

        service.delete(file_name)

        task_id = result[:task_id]
        if task_id
          msg = "FILE SENDED - task_id: #{task_id}, name: #{file_name}"
          logger.info('', operation: 'xml_send', region_id: region_id, msg: msg)

          Resque.enqueue_in(DELAY_CHECK, ::Apress::TurboPages::SendCheckJob, region_id, task_id, file_name)
        else
          msg = <<-MSG.strip_heredoc
            FILE NOT SENDED - name: #{file_name}, code: #{result[:error_code]}, message: #{result[:error_message]}
          MSG

          logger.error('', operation: 'xml_send', region_id: region_id, msg: msg)

          file_move_to_failures
        end

        task_id
      end

      def processing?(task_id)
        info = api.task_info(task_id)
        load_status = info[:load_status]

        return false unless load_status
        return true if load_status == api.class::STATE_PROCESSING

        stats = info[:stats]
        file_move_or_delete(load_status, stats)

        count_pages = stats.map { |name, value| "#{name}: #{value}" }.join(', ')
        msg = "STATS - task_id: #{task_id}, name: #{file_name}, #{count_pages}"

        severity = :info
        if load_status == api.class::STATE_WARNING
          severity = :warn
        elsif load_status == api.class::STATE_ERROR
          severity = :error
        end

        logger.send(severity, '', operation: 'xml_send', region_id: region_id, msg: msg)

        log_pages_errors(info[:errors]) if info[:errors].present?

        false
      end

      private

      def service
        @service ||= Queues::XmlQueueService.new(region_id: region_id)
      end

      def api
        @api ||= ExternalApi::Client.new(region_id: region_id)
      end

      def file_path
        @file_path ||= File.join(config[:xml_storage], region_id.to_s, file_name)
      end

      def file_failures_path
        @file_failures_path ||= File.join(config[:xml_failures], region_id.to_s, file_name)
      end

      def file_move_to_failures
        FileUtils.mv(file_path, file_failures_path)

        msg = "FILE NOT SENDED - path: #{file_path}, move: #{file_failures_path}"
        logger.error('', operation: 'xml_file_move', region_id: region_id, msg: msg)
      end

      def file_move_or_delete(load_status, stats)
        return unless File.exist?(file_path)

        case load_status
        when api.class::STATE_OK
          File.delete(file_path)
        when api.class::STATE_WARNING
          file_move?(stats) ? file_move_to_failures : File.delete(file_path)
        when api.class::STATE_ERROR
          file_move_to_failures
        end
      end

      def file_move?(stats)
        if stats[:pages_count].zero?
          true
        else
          warning_count = stats[:warnings_count].zero? ? stats[:errors_count] : stats[:warnings_count]
          ((warning_count.to_f / stats[:pages_count]) * 100) >= MOVE_TO_FAILURES_PERCENT
        end
      end

      def log_pages_errors(errors)
        errors.each do |error|
          logger.error(
            '',
            operation: 'turbo_page',
            region_id: region_id,
            msg: "#{error[:error_code]}: #{error[:text]}"
          )
        end
      end
    end
  end
end
