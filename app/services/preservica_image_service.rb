# frozen_string_literal: true

class PreservicaImageService
  class PreservicaImageServiceError < StandardError
    attr_reader :id
    # rubocop:disable Layout/LineLength
    def initialize(msg, id)
      @id = id
      super("#{msg} for #{id}")
    end
    # rubocop:enable Layout/LineLength
  end

  class PreservicaImageServiceNetworkError < PreservicaImageServiceError
    def initialize(msg, id)
      super(msg, id)
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

  # True once image_list has run if the object has a real folder architecture, i.e. at least one
  # information object groups more than one image. Flat objects (each information object holding a
  # single image) are not considered folders and get no IIIF structure.
  def folder_architecture?
    @folder_architecture == true
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def image_list(representation_type)
    @images = []
    @folder_architecture = false
    begin
      if @pattern == :pattern_one
        structural_object = Preservica::StructuralObject.where(admin_set_key: @admin_set_key, id: (@uri.split('/')[-1]).to_s)
        begin
          @information_objects = structural_object.information_objects.sort_by { |io| io.title.to_s }
        rescue Net::OpenTimeout, Errno::ECONNREFUSED => e
          raise PreservicaImageServiceNetworkError.new(e.to_s, @uri.to_s)
        end
      elsif @pattern == :pattern_two
        begin
          @information_objects = [Preservica::InformationObject.where(admin_set_key: @admin_set_key, id: (@uri.split('/')[-1]).to_s)]
        rescue Net::HTTPFatalError, Net::HTTPNotFound, Net::ReadTimeout => e
          raise PreservicaImageServiceNetworkError.new(e.to_s, @uri.to_s)
        end
      end
    rescue StandardError => e
      # raise PreservicaImageServiceError.new("Unable to log in to Preservica", @uri.to_s)
      raise PreservicaImageServiceError.new(e.to_s, @uri.to_s)
    end
    check_for_non_information_object_children if @pattern == :pattern_one
    begin
      process_information_objects(representation_type)
    rescue StandardError => e
      error = e.to_s
      cleaned_error = error.split(' for /').first
      raise PreservicaImageServiceError.new(cleaned_error, @uri.to_s) if error.include?(@uri.to_s)
      raise PreservicaImageServiceError.new(e.to_s, @uri.to_s)
    end
    @images
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  # rubocop:disable Layout/LineLength
  def check_for_non_information_object_children
    non_information_objects = @information_objects.reject do |information_object|
      information_object.structural_object_child_type.blank? || information_object.structural_object_child_type == 'IO'
    end
    return if non_information_objects.empty?
    raise PreservicaImageServiceError.new("Structural object contains children that are not information objects (nested folders); this object shape is not supported", @uri.to_s)
  end
  # rubocop:enable Layout/LineLength

  # rubocop:disable Layout/LineLength
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def process_information_objects(representation_type)
    @information_objects.each_with_index do |information_object, information_object_index|
      representation = information_object.fetch_by_representation_type(representation_type)[0]
      raise PreservicaImageServiceError.new("No matching representation found in Preservica", @uri.to_s) if representation.nil?
      content_objects = representation.content_objects
      raise PreservicaImageServiceError.new("No matching content object found in Preservica", @uri.to_s) if content_objects.empty?
      information_object_images = []
      content_objects.each_with_index do |content_object, index|
        raise PreservicaImageServiceError.new("No active generations found in Preservica", "content object: #{content_object.id}") if content_object.active_generations.empty?
        raise PreservicaImageServiceError.new("No matching bitstreams found in Preservica", content_object.active_generations[0].id.to_s) if content_object.active_generations[0].bitstreams.empty?
        next unless content_object.active_generations[0].formats.include? "Tagged Image File Format"
        tif_bitstream = content_object.active_generations[0].bitstreams.find do |bitstream|
          bitstream.filename.ends_with?("tif", "TIF", "tiff")
        end
        next unless tif_bitstream.present?
        raise PreservicaImageServiceError.new("SHA mismatch found in Preservica", "bitstream: #{content_object.active_generations[0].bitstreams[0].id}") if tif_bitstream.sha512_checksum.nil?
        information_object_images << { preservica_content_object_uri: representation.content_object_uri(index),
                                       preservica_generation_uri: content_object.active_generations[0].generation_uri,
                                       preservica_bitstream_uri: tif_bitstream.uri,
                                       sha512_checksum: tif_bitstream.sha512_checksum,
                                       bitstream: tif_bitstream,
                                       caption: tif_bitstream.filename,
                                       preservica_information_object_id: information_object.id,
                                       preservica_folder_label: information_object.title.to_s,
                                       preservica_folder_index: information_object_index,
                                       preservica_content_object_index: index }
      end
      @folder_architecture = true if information_object_images.size > 1
      @images.concat(information_object_images.sort_by { |image| image[:caption].to_s })
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Layout/LineLength
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
end
