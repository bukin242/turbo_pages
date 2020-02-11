module Apress
  module TurboPages
    class XmlGeneratorJob
      include Resque::Integration

      queue :turbo_pages_xml

      def self.perform(region_id)
        XmlGeneratorService.call(region_id: region_id)
      end
    end
  end
end
