# frozen_string_literal: true
# rubocop:disable Metrics/ClassLength
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

  def extent_of_dig
    eodig = @mets.xpath("//mods:part").first&.inner_text
    unless eodig.nil?
      return nil unless eodig.include?("digitized")
    end
    eodig
  end

  def dig_note
    dig_note = @mets.xpath("//mods:note[@type='admin']").inner_text
    return nil unless dig_note.present?
    dig_note
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

  # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
  def valid_mets?
    raise "no mets xml" unless @mets.xml?
    raise "no mets namespace in mets file" unless @mets.collect_namespaces.include?("xmlns:mets")
    raise "no mets file in the mets xml" unless @mets.xpath("//mets:file").count >= 1
    raise "no right statement found in the mets xml" if rights_statement.blank?
    raise "not valid metadata source" unless valid_metadata_source_path?
    raise "no image path" if fixture_images_in_production?
    raise "no admin set in mets xml" unless admin_set.present?
    all_images_have_checksum?
    true
  end
  # rubocop:enable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity

  # ensure we don't accidentally upload tiny fixture images in production
  def fixture_images_in_production?
    production_environment = ENV.fetch("RAILS_ENV") != "test" && ENV.fetch("RAILS_ENV") != "development"
    has_fixtures = files.any? { |file| file[:mets_access_master_path].include?("spec/fixtures") }
    production_environment && has_fixtures
  end

  def all_images_present?
    files.all? { |file| (File.exist?(file[:mets_access_master_path]) || File.exist?(file[:mets_access_master_path_capitalized])) }
  end

  def all_images_have_checksum?
    files.each_with_index do |file, index|
      raise "#{file[:checksum]}, index: #{index} invalid checksum, check the checksum in mets xml" unless file[:checksum] =~ /^([a-f0-9]{40})$/
    end
  end

  # Combines the physical info and file info for a given image
  def combined
    zipped = add_nil_caption.nil? ? files.zip(physical_divs) : files.zip(add_nil_caption)
    zipped.map { |file, physical_div| file.merge(physical_div) }
  end

  # merge into physical divs
  def add_nil_caption
    if combined_logical_link_hash.nil? == true
      nil
    else
      combined_logical_link_physical_hash.each do |i|
        i[:caption] = i[:caption].nil? ? nil : i[:caption]
      end
    end
  end

  def combined_logical_link_physical_hash
    index = combined_logical_link_hash.group_by { |entry| entry[:physical_id] } unless combined_logical_link_hash.nil?
    physical_divs.map { |entry| (index[entry[:physical_id]] || []).reduce(entry, :merge) } unless combined_logical_link_hash.nil?
  end

  # combine logic_link with logic divs
  def combined_logical_link_hash
    index = logical_divs.group_by { |entry| entry[:logical_id] } unless logical_divs.empty?
    link_value_hash.map { |entry| (index[entry[:logical_id]] || []).reduce(entry, :merge) } unless logical_divs.empty?
  end

  def physical_divs
    @mets.xpath("/mets:mets/mets:structMap[@TYPE='PHYSICAL']/mets:div" \
                "/mets:div").map do |p|
      physical_info(p)
    end
  end

  def logical_divs
    @mets.xpath("/mets:mets/mets:structMap[@TYPE='LOGICAL']/mets:div" \
                "/mets:div").map do |l|
      logical_info(l)
    end
  end

  def physical_info(physical_div)
    {
      oid: physical_div.xpath('@CONTENTIDS').inner_text, # oid for child object
      label: normalize_label(physical_div),
      order: physical_div.xpath("@ORDER").inner_text,
      parent_object_oid: oid,
      child_uuid: physical_div.xpath("mets:fptr/@FILEID").first&.text, # uuid for child object
      physical_id: physical_div.xpath("@ID").inner_text

    }
  end

  def logical_info(logical_div)
    {
      caption: caption_info(logical_div), # caption for child object
      logical_id: caption_logical_id(logical_div)
    }
  end

  def caption_info(logical_div)
    return nil if logical_div.xpath("@TYPE").inner_text != "caption"
    logical_div.xpath("@LABEL").inner_text
  end

  def caption_logical_id(logical_div)
    return nil if logical_div.xpath("@TYPE").inner_text != "caption"
    logical_div.xpath("@ID").inner_text
  end

  def parent_logical_id
    parent_logical = @mets.xpath("/mets:mets/mets:structMap[@TYPE='LOGICAL']/mets:div")
    parent_logical.xpath("@ID").inner_text
  end

  def link_value_hash
    link_array = []
    link_value = @mets.xpath("/mets:mets/mets:structLink/mets:smLink")

    link_value.each do |pl|
      link_array.push pl.values unless pl.values[1] == parent_logical_id
    end
    link_array
      .map { |(physical_id, logical_id)| { physical_id: physical_id, logical_id: logical_id } }
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
    mets_image_name = file.xpath('mets:FLocat/@xlink:href').to_s.gsub(/file:\/\//, '')
    {
      thumbnail_flag: thumbnail_flag,
      checksum: file.xpath('@CHECKSUM').inner_text,
      mets_access_master_path: mets_image_name,
      mets_access_master_path_capitalized: mets_image_name.gsub('.tif', '.TIF').gsub('.jpg', '.JPG')
    }
  end
  # rubocop:enable Metrics/ClassLength
end
