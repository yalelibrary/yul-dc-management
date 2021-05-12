# frozen_string_literal: true

class MetsDocument
  include MetadataCloudUrlParsable
  attr_reader :source_xml
  # Takes a path to the mets file
  def initialize(mets_xml)
    @source_xml = mets_xml
    @mets = Nokogiri::XML(@source_xml)
  end

  def oid
    @mets.xpath("//mods:recordIdentifier[@source='gbv-ppn']").inner_text
  end

  def parent_uuid
    file_group = @mets.xpath("/mets:mets/mets:fileSec/mets:fileGrp")
    file_group.xpath("@ID").first&.inner_text
  end

  def metadata_source_path
    @mets.xpath("//mods:identifier").inner_text
  end

  def visibility
    @mets.xpath("//mods:accessCondition[@type='restriction on access']").inner_text
  end

  def rights_statement
    @mets.xpath("//mods:accessCondition[@type='use and reproduction']").inner_text
  end

  def viewing_direction
    return nil unless @mets.collect_namespaces.keys.include?("xmlns:intranda")
    @mets.xpath("//mods:extension/intranda:intranda/intranda:ViewingDirection").inner_text
  end

  def viewing_hint
    return nil unless @mets.collect_namespaces.include?("xmlns:intranda")
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
    return false if fixture_images_in_production?
    return false if admin_set.blank?
    true
  end

  # ensure we don't accidentally upload tiny fixture images in production
  def fixture_images_in_production?
    production_environment = ENV.fetch("RAILS_ENV") != "test" && ENV.fetch("RAILS_ENV") != "development"
    has_fixtures = files.any? { |file| file[:mets_access_master_path].include?("spec/fixtures") }
    production_environment && has_fixtures
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
      label: normalize_label(physical_div),
      order: physical_div.xpath("@ORDER").inner_text,
      parent_object_oid: oid,
      child_uuid: physical_div.xpath("mets:fptr/@FILEID").first.text # uuid for child object
    }
  end

  def admin_set_key
    @mets.xpath("//mods:note[@type='ownership' and @displayLabel='Yale Collection Owner']")&.inner_text
  end

  def admin_set
    @admin_set ||= AdminSet.find_by(key: admin_set_key)
  end

  def normalize_label(physical_div)
    return nil if physical_div.xpath("@ORDERLABEL").inner_text == " - "
    physical_div.xpath("@ORDERLABEL").inner_text
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
end
