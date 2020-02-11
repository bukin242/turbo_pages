module Apress
  module TurboPages
    class SendCheckJob
      include Resque::Integration

      queue :turbo_pages_send_check

      DELAY_INTERVAL = 10.minutes
      MAX_ITERATIONS = 10

      def self.perform(region_id, task_id, file_name, counter = 0)
        if counter < MAX_ITERATIONS && SendService.new(region_id: region_id, file_name: file_name).processing?(task_id)
          counter += 1
          Resque.enqueue_in(DELAY_INTERVAL, ::Apress::TurboPages::SendCheckJob, region_id, task_id, file_name, counter)
        end
      end
    end
  end
end
