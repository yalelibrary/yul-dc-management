# frozen_string_literal: true

class MetsDocument
  include MetsStructure
  attr_reader :source_xml
  # Takes a path to the mets file
  def initialize(mets_xml)
    @source_xml = mets_xml
    @mets = Nokogiri::XML(@source_xml)
  end

  def oid
    @mets.xpath("//goobi:metadata[@name='CatalogIDDigital']").first&.content&.to_s
  end

  def valid_mets?
    return false unless @mets.xml?
    return false unless @mets.collect_namespaces.include?("xmlns:mets")
    return false unless @mets.xpath("//mets:file").count >= 1
    true
  end

  def includes_goobi?
    return false unless @mets.collect_namespaces.include?("xmlns:goobi")
    true
  end

  def all_images_present?
    files.all? { |file| File.exist?(Rails.root.join(file[:url])) }
  end

  # def viewing_direction
  #   right_to_left ? "right-to-left" : "left-to-right"
  # end

  # def right_to_left
  #   @mets.xpath("/mets:mets/mets:structMap[@TYPE='logical']/mets:div/@TYPE") \
  #        .to_s.start_with? 'RTL'
  # end

  def files
    @mets.xpath("/mets:mets/mets:fileSec/mets:fileGrp" \
                "/mets:file").map do |f|
      file_info(f)
    end
  end

  def file_info(file)
    {
      id: file.xpath('@ID').to_s,
      checksum: file.xpath('@CHECKSUM').to_s,
      mime_type: file.xpath('@MIMETYPE').to_s,
      url: file.xpath('mets:FLocat/@xlink:href').to_s.gsub(/file:\/\//, '')
    }
  end

  # def file_opts(file)
  #   return {} if
  #     @mets.xpath("count(//mets:div/mets:fptr[@FILEID='#{file[:id]}'])") \
  #          .to_i.positive?
  #   { viewing_hint: 'non-paged' }
  # end
end
