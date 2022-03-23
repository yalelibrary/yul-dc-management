# frozen_string_literal: true

class PreservicaImageService
  class PreservicaImageServiceError < StandardError
    attr_reader :id
    def initialize(msg, id)
      @id = id
      super("#{msg} for #{id}")
    end
  end

  def initialize(uri, admin_set_key)
    @uri = uri
    if uri.include?('structural')
      @pattern = :pattern_one
    elsif uri.include?('information')
      @pattern = :pattern_two
    end
    @admin_set_key = admin_set_key
  end

  # rubocop:disable Metrics/MethodLength
  def image_list(representation_name)
    @images = []
    begin
      if @pattern == :pattern_one
        structural_object = Preservica::StructuralObject.where(admin_set_key: @admin_set_key, id: (@uri.split('/')[-1]).to_s)
        begin
          @information_objects = structural_object.information_objects
        rescue Net::OpenTimeout, Errno::ECONNREFUSED => e
          raise PreservicaImageServiceError.new(e.to_s, @uri.to_s)
        end
      elsif @pattern == :pattern_two
        @information_objects = [Preservica::InformationObject.where(admin_set_key: @admin_set_key, id: (@uri.split('/')[-1]).to_s)]
      end
    rescue StandardError
      raise PreservicaImageServiceError.new("Unable to log in to Preservica", @uri.to_s)
    end
    begin
      process_information_objects(representation_name)
    rescue StandardError => e
      raise PreservicaImageServiceError.new(e.to_s, @uri.to_s)
    end
    @images
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/LineLength
  # rubocop:disable Metrics/AbcSize
  def process_information_objects(representation_name)
    @information_objects.each do |information_object|
      representation = information_object.fetch_by_representation_name(representation_name)[0]
      raise PreservicaImageServiceError.new("No matching representation found in Preservica", @uri.to_s) if representation.nil?
      content_objects = representation.content_objects
      raise PreservicaImageServiceError.new("No matching content object found in Preservica", @uri.to_s) if content_objects.empty?
      content_objects.each do |content_object|
        raise PreservicaImageServiceError.new("No active generations found in Preservica", content_object.id.to_s) if content_object.active_generations.empty?
        raise PreservicaImageServiceError.new("No matching bitstreams found in Preservica", content_object.active_generations[0].id.to_s) if content_object.active_generations[0].bitstreams.empty?
        raise PreservicaImageServiceError.new("SHA mismatch found in Preservica", content_object.active_generations[0].bitstreams[0].id.to_s) if content_object.active_generations[0].bitstreams[0].sha512_checksum.nil?
        @images << { preservica_content_object_uri: content_object.content_object_uri,
                     preservica_generation_uri: content_object.active_generations[0].generation_uri,
                     preservica_bitstream_uri: content_object.active_generations[0].bitstream_uri,
                     sha512_checksum: content_object.active_generations[0].bitstreams[0].sha512_checksum,
                     bitstream: content_object.active_generations[0].bitstreams[0] }
      end
    end
  end
  # rubocop:enable Metrics/LineLength
  # rubocop:enable Metrics/AbcSize
end
