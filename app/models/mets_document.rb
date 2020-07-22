# frozen_string_literal: true

class MetsDocument
  include MetsStructure
  attr_reader :source_file
  # Takes a path to the mets file
  def initialize(mets_file)
    @source_file = mets_file
    @mets = File.open(@source_file) { |f| Nokogiri::XML(f) }
  end

  # Takes a string of xml
  # def initialize(mets_string)
  #   @source_string = mets_string
  #   @mets = Nokogiri::XML(@source_string)
  # end

  def oid
    @mets.xpath("//goobi:metadata[@name='CatalogIDDigital']").first&.content.to_s
  end

  def valid_mets?
    return false unless @mets.xml?
    return false unless @mets.collect_namespaces.include?("xmlns:mets")
    return false unless @mets.xpath("//mets:file").count >= 1
    true
  end

  # def viewing_direction
  #   right_to_left ? "right-to-left" : "left-to-right"
  # end

  # def right_to_left
  #   @mets.xpath("/mets:mets/mets:structMap[@TYPE='logical']/mets:div/@TYPE") \
  #        .to_s.start_with? 'RTL'
  # end

  # def files
  #   @mets.xpath("/mets:mets/mets:fileSec/mets:fileGrp" \
  #               "/mets:file").map do |f|
  #     file_info(f)
  #   end
  # end

  # def file_info(file)
  #   {
  #     id: file.xpath('@ID').to_s,
  #     checksum: file.xpath('@CHECKSUM').to_s,
  #     mime_type: file.xpath('@MIMETYPE').to_s,
  #     url: file.xpath('mets:FLocat/@xlink:href').to_s.gsub(/file:\/\//, '')
  #   }
  # end

  # def file_opts(file)
  #   return {} if
  #     @mets.xpath("count(//mets:div/mets:fptr[@FILEID='#{file[:id]}'])") \
  #          .to_i.positive?
  #   { viewing_hint: 'non-paged' }
  # end
end
