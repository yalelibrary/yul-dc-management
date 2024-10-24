# frozen_string_literal: true

class Preservica::Bitstream
  include Preservica::PreservicaObject

  MAX_ATTEMPTS = 3

  attr_reader :filename

  def initialize(preservica_client, content_id, generation_id, id, filename)
    @preservica_client = preservica_client
    @id = id
    @content_id = content_id
    @generation_id = generation_id
    @filename = filename
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

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def download_to_file(file_name)
    Rails.logger.info "************ bitstream.rb # download_to_file +++ hits download to file method with file: #{file_name} *************"
    attempt ||= 1
    co_oid = file_name.scan(/\d+/).last
    data_length = 0
    sha512 = Digest::SHA512. new
    File.open(file_name, 'wb') do |file|
      Rails.logger.info "************ bitstream.rb # download_to_file +++ File.open succeeds in opening file *************"
      preservica_client.get(content_uri) do |chunk|
        data_length += chunk.length
        no_of_bites = file.write(chunk)
        redo if no_of_bites < 1 && (attempt += 1) <= MAX_ATTEMPTS
        Rails.logger.info "************ bitstream.rb # download_to_file +++ File.write wrote #{no_of_bites} bites to file *************"
        Rails.logger.info "************ bitstream.rb # download_to_file +++ file.write attempt #{attempt} of #{MAX_ATTEMPTS} *************"
        sha512 << chunk
      end
    end
    data_sha512 = sha512.hexdigest
    file_size = File.size?(file_name)
    Rails.logger.info "************ bitstream.rb # download_to_file +++ counts file size (data_length): #{data_length} *************"
    Rails.logger.info "************ bitstream.rb # download_to_file +++ grabs sha checksum (data_sha512): #{data_sha512} *************"
    unless data_sha512.casecmp?(sha512_checksum)
      raise StandardError,
"The checksum for this object is different than the checksum that DCS expected. Please ensure your image folder in Preservica has SHA-512 fixity checksums. Message from System: Checksum mismatch for Child Object: #{co_oid} - (#{data_sha512} != #{sha512_checksum})"
    end
    raise StandardError, "Data size did not match for Child Object: #{co_oid} - (#{data_length} != #{size})" unless data_length == size
    raise StandardError, "File sizes do not match for Child Object: #{co_oid} - (#{file_size} != #{size})" unless file_size == size
    # could also check: Digest::SHA512.file(file_name).hexdigest == sha512_checksum, but probably not necessary
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def xml
    @xml ||= Nokogiri::XML(preservica_client.content_object_generation_bitstream(@content_id, @generation_id, @id)).remove_namespaces!
  end

  def uri
    @bitstream_uri ||= xml.xpath('/BitstreamResponse/AdditionalInformation/Self').text.strip
  end

  private

  def content_uri
    @content_uri ||= "/api/entity/content-objects/#{@content_id}/generations/#{@generation_id}/bitstreams/#{@id}/content"
  end
end
