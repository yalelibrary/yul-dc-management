# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class CsvRowParentService
  class BatchProcessingError < StandardError
    attr_reader :kind
    def initialize(msg, kind)
      @kind = kind
      super(msg)
    end
  end

  attr_accessor :row, :index, :current_ability, :user

  def initialize(row, index, current_ability, user)
    @row = row
    @index = index
    @current_ability = current_ability
    @user = user
  end

  # rubocop:disable Style/ClassVars
  def self.properties
    @@properties ||= []
  end
  # rubocop:enable Style/ClassVars

  def self.row_accessor(*names)
    names.each do |name|
      properties << name
      define_method(name) { row[name.to_s] }
    end
  end

  row_accessor :aspace_uri, :bib, :holding, :item, :barcode, :oid, :admin_set,
               :preservica_uri, :visibility, :digital_object_source,
               :authoritative_metadata_source_id, :preservica_representation_type

  def parent_object
    PreservicaImageService.new(preservica_uri, admin_set.key).image_list(preservica_representation_type)
    @parent_object ||= ParentObject.new(properties_hash)
  end

  def properties_hash
    self.class.properties.each_with_object({}) { |p, h| h[p] = send(p); }
  end

  def oid
    @oid ||= OidMinterService.generate_oids(1)[0]
  end

  def parent_model
    row['parent_model'] || 'complex'
  end

  def bib
    raise BatchProcessingError.new("Skipping row [#{index + 2}]. BIB must be present if 'ils' metadata source", 'Skipped Row') if row['source'] == "ils" && !row['bib'].present?
    row['bib']
  end

  def preservica_representation_type
    raise BatchProcessingError.new("Skipping row [#{index + 2}]. Preservica Representation Type must be present", 'Skipped Row') if row['preservica_representation_type'].blank?
    row['preservica_representation_type']
  end

  def preservica_uri
    raise BatchProcessingError.new("Skipping row [#{index + 2}]. Preservica URI must start with a '/'", 'Skipped Row') unless row['preservica_uri'].start_with?('/')
    row['preservica_uri']
  end

  def aspace_uri
    raise BatchProcessingError.new("Skipping row [#{index + 2}]. Aspace URI must be present if 'aspace' metadata source", 'Skipped Row') if row['source'] == "aspace" && !row['aspace_uri'].present?
    row['aspace_uri']
  end

  def visibility
    visibilities = ['Private', 'Public', 'Redirect', 'Yale Community Only']

    return row['visibility'] if visibilities.include?(row['visibility'])

    raise BatchProcessingError.new("Skipping row [#{index + 2}] with unknown visibility: #{row['visibility']}", 'Skipped Row')
  end

  def digital_object_source
    raise BatchProcessingError.new("Skipping row [#{index + 2}]. Digital Object Source must be 'Preservica'", 'Skipped Row') if row['digital_object_source'] != "Preservica"
    row['digital_object_source']
  end

  # rubocop:disable Metrics/LineLength
  def admin_set
    admin_sets_hash = {}
    admin_set_key = row['admin_set']
    admin_sets_hash[admin_set_key] ||= AdminSet.find_by(key: admin_set_key)
    admin_set = admin_sets_hash[admin_set_key]

    raise BatchProcessingError.new("Skipping row [#{index + 2}] with unknown admin set [#{admin_set_key}] for parent: #{oid}", 'Skipped Row') if admin_set.blank?

    raise BatchProcessingError.new("Skipping row [#{index + 2}] with admin set [#{admin_set_key}] for parent: #{oid}. Preservica credentials not set for #{admin_set_key}.", 'Skipped Row') unless admin_set.preservica_credentials_verified

    unless current_ability.can?(:add_member, admin_set)
      raise BatchProcessingError.new("Skipping row [#{index + 2}] because #{user.uid} does not have permission to create or update parent: #{oid}",
                                     'Permission Denied')
    end

    admin_set
  end
  # rubocop:enable Metrics/LineLength

  def authoritative_metadata_source_id
    ms = row['source']
    raise BatchProcessingError.new("Skipping row [#{index + 2}] with unknown source [#{ms}]. Source must be 'ils' or 'aspace'", 'Skipped Row') if ms != "ils" && ms != "aspace"
    if ms == "ils"
      ms = 2
    elsif ms == "aspace"
      ms = 3
    elsif ms == "sierra"
      ms = 4
    end
    ms
  end
end
# rubocop:enable Metrics/ClassLength
