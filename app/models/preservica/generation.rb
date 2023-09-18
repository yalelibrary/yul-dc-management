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

    # rubocop:disable Metrics/AbcSize
    def load_bitstreams
      xml.xpath('/GenerationResponse/Bitstreams/Bitstream').map do |bitstream|
        last_section = bitstream['filename'].split('_').last
        if last_section.include?('.pdf')
          last_numbers = bitstream['filename'].split('_').last.tr('.pdf', '')
        elsif last_section.include?('.tif')
          last_numbers = bitstream['filename'].split('_').last.tr('.tif', '')
        elsif last_section.include?('.tiff')
          last_numbers = bitstream['filename'].split('_').last.tr('.tiff', '')
        end
        # if the last section is a single integer
        if last_numbers.to_i < 10
          first_section = bitstream['filename'].split('_')[0...-1]
          file_name = first_section.join('_') + '_' + last_section.prepend('0')
        else
          file_name = bitstream['filename']
        end
        Preservica::Bitstream.new(@preservica_client, @content_id, @id, bitstream.content.split('/').last.strip, file_name)
      end
    end
    # rubocop:enable Metrics/AbcSize

    def load_formats
      xml.xpath('/GenerationResponse/Generation/Formats/Format/FormatName').map(&:content)
    end

    def load_format_group
      xml.xpath('/GenerationResponse/Generation/FormatGroup').map(&:content)
    end
end
