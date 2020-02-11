module Apress
  module TurboPages
    class SendJob
      include Resque::Integration

      queue :turbo_pages_send

      def self.perform(region_id, file_name)
        SendService.call(region_id: region_id, file_name: file_name)
      end
    end
  end
end
