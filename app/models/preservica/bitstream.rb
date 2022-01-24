# frozen_string_literal: true

class Bitstream
  include PreservicaObject

  def initialize(preservica_client, content_id, generation_id, id)
    @preservica_client = preservica_client
    @id = id
    @content_id = content_id
    @generation_id = generation_id
  end

  def checksum
    xml.xpath('//FixityValue/text()').text
  end

  def size
    xml.xpath('//FileSize/text()').text.to_i
  end

  def bits
    preservica_client.get "/api/entity/content-objects/#{@content_id}/generations/#{@generation_id}/bitstreams/#{@id}/content"
  end

  private

    def xml
      @xml ||= Nokogiri::XML(preservica_client.content_object_generation_bitstream(@content_id, @generation_id, @id)).remove_namespaces!
    end
end
