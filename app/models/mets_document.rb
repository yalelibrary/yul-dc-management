# frozen_string_literal: true

class MetsDocument
  include MetsStructure
  attr_reader :source_xml
  # Takes a path to the mets file
  def initialize(mets_xml)
    @source_xml = mets_xml
    @mets = Nokogiri::XML(@source_xml)
  end

  def parsed_metadata_source_path
    @parsed_metadata_source_path ||= metadata_source_path.match(/\/(\w*)\/(\w*)\/(\d*)\W(\w*)\W(\w*)/)
  end

  def oid
    @mets.xpath("//mods:recordIdentifier[@source='gbv-ppn']").inner_text
  end

  def parent_uuid
    file_group = @mets.xpath("/mets:mets/mets:fileSec/mets:fileGrp")
    file_group.xpath("@ID").first.inner_text
  end

  def metadata_source_path
    @mets.xpath("//mods:identifier").inner_text
  end

  def full_metadata_cloud_url
    "https://#{MetadataSource.metadata_cloud_host}/metadatacloud/api/#{MetadataSource.metadata_cloud_version}#{metadata_source_path}"
  end

  def metadata_source
    parsed_metadata_source_path.captures.first
  end

  def bib
    parsed_metadata_source_path.captures.last if metadata_source == "ils"
  end

  def barcode
    parsed_metadata_source_path.captures.third if parsed_metadata_source_path.captures.include?("barcode")
  end

  def holding
    parsed_metadata_source_path.captures.third if parsed_metadata_source_path.captures.include?("holding")
  end

  def item
    parsed_metadata_source_path.captures.third if parsed_metadata_source_path.captures.include?("item")
  end

  def visibility
    @mets.xpath("//mods:accessCondition[@type='restriction on access']").inner_text
  end

  def rights_statement
    @mets.xpath("//mods:accessCondition[@type='use and reproduction']").inner_text
  end

  def viewing_direction
    @mets.xpath("//mods:extension/intranda:intranda/intranda:ViewingDirection").inner_text
  end

  def viewing_hint
    @mets.xpath("//mods:extension/intranda:intranda/intranda:ViewingHint").inner_text
  end

  def thumbnail_image
    child_img = combined.find do |child|
      child[:thumbnail_flag]
    end
    child_img&.[](:oid)&.to_i
  end

  def valid_mets?
    return false unless @mets.xml?
    return false unless @mets.collect_namespaces.include?("xmlns:mets")
    return false unless @mets.xpath("//mets:file").count >= 1
    return false if rights_statement.blank?
    return false unless valid_metadata_source_path?
    true
  end

  def valid_metadata_source_path?
    return false unless parsed_metadata_source_path
    if metadata_source == 'ils'
      return false unless valid_bib? && (valid_item? || valid_holding? || valid_barcode?)
    elsif metadata_source == 'aspace' && metadata_source_path !~ /\A\/aspace\/repositories\/\d+\/archival_objects\/\d+\z/
      return false
    end
    true
  end

  def valid_barcode?
    barcode && (barcode !~ /\D/)
  end

  def valid_bib?
    bib =~ /\A\d+b?\z/
  end

  def valid_item?
    item && (item !~ /\D/)
  end

  def valid_holding?
    holding && (holding !~ /\D/)
  end

  def all_images_present?
    files.all? { |file| File.exist?(file[:mets_access_master_path]) }
  end

  # Combines the physical info and file info for a given image
  def combined
    zipped = files.zip(physical_divs)
    zipped.map { |file, physical_div| file.merge(physical_div) }
  end

  def physical_divs
    @mets.xpath("/mets:mets/mets:structMap[@TYPE='PHYSICAL']/mets:div" \
                "/mets:div").map do |p|
      physical_info(p)
    end
  end

  def physical_info(physical_div)
    {
      oid: physical_div.xpath('@CONTENTIDS').inner_text, # oid for child object
      label: physical_div.xpath("@ORDERLABEL").inner_text,
      order: physical_div.xpath("@ORDER").inner_text,
      parent_object_oid: oid
    }
  end

  def files
    @mets.xpath("/mets:mets/mets:fileSec/mets:fileGrp[@USE='PRESENTATION']/mets:file").map do |f|
      file_info(f)
    end
  end

  def file_info(file)
    thumbnail_flag = file.xpath('@USE').inner_text == "banner" ? true : false
    {
      thumbnail_flag: thumbnail_flag,
      checksum: file.xpath('@CHECKSUM').inner_text,
      mets_access_master_path: file.xpath('mets:FLocat/@xlink:href').to_s.gsub(/file:\/\//, '')
    }
  end

  # def file_opts(file)
  #   return {} if
  #     @mets.xpath("count(//mets:div/mets:fptr[@FILEID='#{file[:id]}'])") \
  #          .to_i.positive?
  #   { viewing_hint: 'non-paged' }
  # end
end
