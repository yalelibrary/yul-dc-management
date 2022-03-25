# frozen_string_literal: true

class Preservica::Generation
  include Preservica::PreservicaObject

  def initialize(preservica_client, content_id, generation_id)
    @preservica_client = preservica_client
    @id = generation_id
    @content_id = content_id
  end

  def bitstreams
    @bitstreams ||= load_bitstreams
  end

  def formats
    @formats ||= load_formats
  end

  def format_group
    @format_group ||= load_format_group
  end

  def generation_uri
    xml.xpath('/GenerationResponse/AdditionalInformation/Self').text.strip
  end

  def bitstream_uri
    xml.xpath('/GenerationResponse/Bitstreams/Bitstream').text.strip
  end

  def xml
    @xml ||= Nokogiri::XML(preservica_client.content_object_generation(@content_id, @id)).remove_namespaces!
  end

  private

    def load_bitstreams
      bitstream_ids = xml.xpath('/GenerationResponse/Bitstreams/Bitstream').map(&:content).map { |x| x.split('/').last }
      bitstream_ids.map do |bitstream_id|
        Preservica::Bitstream.new(@preservica_client, @content_id, @id, bitstream_id.strip)
      end
    end

    def load_formats
      xml.xpath('/GenerationResponse/Generation/Formats/Format/FormatName').map(&:content)
    end

    def load_format_group
      xml.xpath('/GenerationResponse/Generation/FormatGroup').map(&:content)
    end
end
