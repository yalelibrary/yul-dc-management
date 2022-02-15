class CsvRowParentService
  class BatchProcessingError < StandardError
    attr_reader :kind
    def initialize(msg, kind)
      @kind = kind
      super(msg)
    end
  end

  attr_accessor :row, :index
  
  def initialize(row, index)
    @row = row
    @index = index
  end

  def self.properties
    @@properties ||= []
  end

  def self.row_accessor(*names)
    names.each do |name|
      properties << name
      define_method(name) { row[name.to_s] }
    end
  end

  # FETCHES USERS ABILITIES
  def current_ability
    @current_ability ||= Ability.new(user)
  end

  row_accessor :aspace_uri, :bib, :holding, :item, :barcode, :oid, :admin_set, :preservica_uri, :visibility, :digital_object_source

  def parent_object
    @parent_object ||= ParentObject.create(properties_hash)
  end

  def properties_hash
    self.class.properties.inject({}) { |h, p| h[p] = send(p); h}
  end

  def oid
    @oid ||= OidMinterService.generate_oids(1)[0]
  end

  def parent_model
    row['parent_model'] || 'complex'
  end

  def bib
    if row['source'] == "ils" && !row['bib'].present?
      raise BatchProcessingError.new("Skipping row [#{index + 2}]. BIB must be present if 'ils' metadata source", 'Skipped Row')
    end
    row['bib']
  end

  def preservica_uri
    if !row['preservica_uri'].start_with?('/')
      raise BatchProcessingError.new("Skipping row [#{index + 2}]. Preservica URI must start with a '/'", 'Skipped Row')
    end
    row['preservica_uri']
  end

  def aspace_uri
    if row['source'] == "aspace" && !row['aspace_uri'].present?
      raise BatchProcessingError.new("Skipping row [#{index + 2}]. Aspace URI must be present if 'aspace' metadata source", 'Skipped Row')
    end
    row['aspace_uri']
  end

  def visibility
    visibilities = ['Private', 'Public', 'Redirect', 'Yale Community Only']
    if visibilities.include?(row['visibility'])
      row['visibility']
    else
      raise BatchProcessingError.new("Skipping row [#{index + 2}] with unknown visibility: #{row['visibility']}", 'Skipped Row')
    end
  end

  def digital_object_source
    if row['digital_object_source'] != "Preservica"
      raise BatchProcessingError.new("Skipping row [#{index + 2}]. Digital Object Source must be 'Preservica'", 'Skipped Row')
    end
    row['digital_object_source']
  end

  def admin_set
    admin_sets_hash = {}
    admin_set_key = row['admin_set']
    admin_sets_hash[admin_set_key] ||= AdminSet.find_by(key: admin_set_key)
    admin_set = admin_sets_hash[admin_set_key]
    if admin_set.blank?
      raise BatchProcessingError.new("Skipping row [#{index + 2}] with unknown admin set [#{admin_set_key}] for parent: #{oid}", 'Skipped Row')      
    # elsif !current_ability.can?(:add_member, admin_set)
    #   raise BatchProcessingError.new("Skipping row [#{index + 2}] because #{user.uid} does not have permission to create or update parent: #{oid}", 'Permission Denied')
    else
      admin_set
    end
  end

  def metadata_source
    ms = row['source']
    if ms != "ils" && ms != "aspace"
      raise BatchProcessingError.new("Skipping row [#{index + 2}] with unknown source [#{ms}]. Source must be 'ils' or 'aspace'", 'Skipped Row')
    end
    ms
  end

end