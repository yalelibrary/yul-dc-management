# frozen_string_literal: true

class Generation
  include PreservicaObject

  def initialize(preservica_client, content_id, generation_id)
    @preservica_client = preservica_client
    @id = generation_id
    @content_id = content_id
  end

  def bitstreams
    @bitstreams ||= load_bitstreams
  end

  private

    def load_bitstreams
      bitstream_ids = xml.xpath('/GenerationResponse/Bitstreams/Bitstream').map(&:content).map { |x| x.split('/').last }
      bitstream_ids.map do |bitstream_id|
        Bitstream.new(@preservica_client, @content_id, @id, bitstream_id.strip)
      end
    end

    def xml
      @xml ||= Nokogiri::XML(preservica_client.content_object_generation(@content_id, @id)).remove_namespaces!
    end
end
