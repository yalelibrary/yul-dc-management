# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module PdfRepresentable
  extend ActiveSupport::Concern
  # rubocop:enable Metrics/ModuleLength

  NORMALIZED_COVER_FIELDS = %w[
    callNumber
    creator
    date
    sourceTitle
    rights
    extentOfDigitization
  ].freeze

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def generate_pdf
    raise "No authoritative_json to create PDF for #{oid}" unless authoritative_json
    changed_pdf_checksum = new_pdf_checksum # new_pdf_checksum will be false if there were no changes
    return false unless changed_pdf_checksum
    Dir.mktmpdir do |pdf_tmpdir|
      temp_json_file = File.new("#{pdf_tmpdir}/#{oid}_pdf_json", "w")
      temp_json_file.write(pdf_generator_json)
      temp_json_file.close
      temp_pdf_file = "#{temp_json_file.path}.pdf"
      cmd = "java -Djava.io.tmpdir=#{pdf_tmpdir} -jar jpegs2pdf-1.3.jar #{temp_json_file.path} #{temp_pdf_file}"
      stdout, stderr, status = Open3.capture3({ "MAGICK_TMPDIR" => pdf_tmpdir }, cmd)
      success = status.success?
      if success
        raise "Java app did not create PDF file for #{oid}" unless File.exist? temp_pdf_file
        S3Service.upload_image(temp_pdf_file.to_s, remote_pdf_path, "application/pdf", 'pdfchecksum': changed_pdf_checksum)
        File.delete temp_pdf_file
      else
        File.delete temp_pdf_file if File.exist?(temp_pdf_file)
        raise "PDF Java app returned non zero response code for #{oid}: #{PdfRepresentable.clean_up_error(stderr)} #{PdfRepresentable.clean_up_error(stdout)}"
      end
    end
    true
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def self.clean_up_error(msg)
    msg.gsub(/(X-Amz-[^=]*)[^&)]*/, '\1=redacted')
  end

  def new_pdf_checksum
    metadata = S3Service.remote_metadata(remote_pdf_path)
    checksum = pdf_json_checksum
    return checksum if !metadata || metadata[:pdfchecksum] != checksum
  end

  def pdf_deletion
    S3Service.delete(remote_pdf_path)
  end

  def remote_pdf_path
    "pdfs/#{Partridge::Pairtree.oid_to_pairtree(oid)}/#{oid}.pdf"
  end

  def pdf_json_checksum
    Digest::MD5.hexdigest(pdf_json("same", :child_modification))
  end

  def pdf_generator_json
    pdf_json(Time.now.utc.to_s, :s3_presigned_url)
  end

  def pdf_json(generated, child_page_file = :s3_presigned_url)
    title = extract_flat_field_value(authoritative_json, "title", "No Title")
    properties = pdf_properties title, generated
    children = child_pages(child_page_file)
    json_hash = {
      "displayCoverPage" => true,
      "title" => title,
      "header" => "Yale University Library Digital Collections",
      "properties" => properties,
      "pages" => children,
      "imageProcessingCommand" => "convert -resize 2000x2000 %s[0] %s"
    }
    # only add color space with :s3_presigned_url so it does not affect the checksum:
    json_hash["imageProcessingCommand"] = "convert -resize 2000x2000 %s[0] -colorspace sRGB %s" if child_page_file == :s3_presigned_url
    json_hash.to_json
  end

  private

    def child_pages(child_page_file)
      pages = []
      child_objects = ChildObject.where(parent_object: self).order(:order)
      child_objects.map do |child|
        page = {
          "caption" => child['label'] || "",
          "file" => send(child_page_file, child)
        }
        properties = []
        properties << { 'name' => 'Caption:', 'value' => child.caption } if child.caption.present?
        properties << { 'name' => 'Image ID:', 'value' => child.oid.to_s }
        page['properties'] = properties if properties.present?
        pages << page
      end
      pages
    end

    def s3_presigned_url(child)
      S3Service.presigned_url(child.remote_ptiff_path, 24_000)
    end

    def child_modification(child)
      child.updated_at.to_s
    end

    def pdf_properties(title, generated)
      properties = {
        "Title" => title
      }
      properties = cover_page(properties, generated)
      reshape_properties properties
    end

    def reshape_properties(properties)
      properties.keys.map do |key|
        value = properties[key]
        {
          "name" => key,
          "value" => value
        }
      end
    end

    def cover_page(properties, generated)
      # for normalized fields
      NORMALIZED_COVER_FIELDS.each do |field|
        hash = METADATA_FIELDS[field.to_sym]
        properties = add_field_if_present(authoritative_json, field, hash[:label], properties)
      end

      container_information = extract_container_information(authoritative_json)
      properties["Container information"] = container_information if container_information.present?
      properties["Digitization Note"] = digitization_note if digitization_note.present?
      properties["Generated"] = generated
      properties["Terms of Use"] = "https://guides.library.yale.edu/about/policies/access"
      properties["View in DL"] = "https://collections.library.yale.edu/catalog/#{oid}"

      properties
    end

    def add_field_if_present(json, field_name, hash_field, hash)
      value = extract_flat_field_value(json, field_name, nil)
      hash[hash_field] = value if value

      hash
    end

    def extract_flat_field_value(json, field_name, default)
      return default unless json && json[field_name].present?
      Array(json[field_name]).join(", ")
    end
end
