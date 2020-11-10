# frozen_string_literal: true

module PdfRepresentable
  extend ActiveSupport::Concern

  def generate_pdf
    raise "No authoritative_json to create PDF for #{oid}" unless authoritative_json
    temp_json_file = Tempfile.new("#{oid}_pdf_json")
    temp_json_file.write(pdf_generator_json)
    temp_json_file.close
    temp_pdf_file = "#{temp_json_file.path}.pdf"
    cmd = "java -jar jpegs2pdf-1.0.jar #{temp_json_file.path} #{temp_pdf_file}"
    _, stderr, status = Open3.capture3(cmd)
    success = status.exitstatus.zero?
    temp_json_file.delete
    if success
      raise "Java app did not create PDF file for #{oid}" unless File.exist? temp_pdf_file
      S3Service.upload_image(temp_pdf_file.to_s, remote_pdf_path, "application/pdf", nil)
      File.delete temp_pdf_file
    else
      File.delete temp_pdf_file if File.exist?(temp_pdf_file)
      raise "PDF Java app returned non zero response code for #{oid}: #{stderr}"
    end
  end

  def remote_pdf_path
    "pdfs/#{Partridge::Pairtree.oid_to_pairtree(oid)}/#{oid}.pdf"
  end

  def pdf_generator_json
    generated = Time.now.utc.to_s
    title = extract_flat_field_value(authoritative_json, "title", "No Title")
    properties = pdf_properties title, generated
    children = child_pages
    json_hash = {
      "displayCoverPage" => true,
      "title" => title,
      "header" => "Yale University Library Digital Collections",
      "properties" => properties,
      "pages" => children
    }
    json_hash.to_json
  end

  private

    def child_pages
      pages = []
      child_objects = ChildObject.where(parent_object: self).order(:order)
      child_objects.map do |child|
        pages << {
          "caption" => child['label'] || "",
          "file" => S3Service.presigned_url(child.remote_ptiff_path, 24_000)
        }
      end
      pages
    end

    def pdf_properties(title, generated)
      properties = {
        "Title" => title
      }
      add_field_if_present(authoritative_json, "identifierShelfMark", "Call Number", properties)
      add_field_if_present(authoritative_json, "creator", "Creator", properties)
      add_field_if_present(authoritative_json, "date", "Date", properties)
      add_field_if_present(authoritative_json, "rights", "Rights", properties)
      container_information = extract_container_information(authoritative_json)
      properties["Container information"] = container_information if container_information
      properties["Generated"] = generated
      properties["Terms of Use"] = "https://guides.library.yale.edu/about/policies/access"
      properties["View in DL"] = "https://collections.library.yale.edu/catalog/#{oid}"
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

    def extract_flat_field_value(json, field_name, default)
      return default unless json && json[field_name].present?
      Array(json[field_name]).join(", ")
    end

    def add_field_if_present(json, field_name, hash_field, hash)
      value = extract_flat_field_value(json, field_name, nil)
      hash[hash_field] = value if value
    end
end
