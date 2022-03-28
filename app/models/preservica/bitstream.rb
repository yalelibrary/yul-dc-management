# frozen_string_literal: true

class Preservica::Bitstream
  include Preservica::PreservicaObject

  def initialize(preservica_client, content_id, generation_id, id)
    @preservica_client = preservica_client
    @id = id
    @content_id = content_id
    @generation_id = generation_id
  end

  def sha512_checksum
    xml.xpath('//Fixity').each do |node|
      return node.at("FixityValue").text.strip if node.at("FixityAlgorithmRef").text == "SHA512"
    end
    nil
  end

  def size
    xml.xpath('//FileSize/text()').text.strip.to_i
  end

  def bits
    preservica_client.get content_uri
  end

  def download_to_file(file_name)
    data_length = 0
    sha512 = Digest::SHA512. new
    File.open(file_name, 'wb') do |file|
      preservica_client.get(content_uri) do |chunk|
        data_length += chunk.length
        file.write(chunk)
        sha512 << chunk
      end
    end
    data_sha512 = sha512.hexdigest
    file_size = File.size?(file_name)
    raise StandardError, "Checksum mismatch (#{data_sha512} != #{sha512_checksum})" unless data_sha512 == sha512_checksum
    raise StandardError, "Data size did not match (#{data_length} != #{size})" unless data_length == size
    raise StandardError, "File sizes do not match (#{file_size} != #{size})" unless file_size == size
    # could also check: Digest::SHA512.file(file_name).hexdigest == sha512_checksum, but probably not necessary
  end

  def xml
    @xml ||= Nokogiri::XML(preservica_client.content_object_generation_bitstream(@content_id, @generation_id, @id)).remove_namespaces!
  end

  private

    def content_uri
      @content_uri ||= "/api/entity/content-objects/#{@content_id}/generations/#{@generation_id}/bitstreams/#{@id}/content"
    end
end
