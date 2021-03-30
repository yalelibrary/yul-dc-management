# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# Do all background jobs inline during seeds
ActiveJob::Base.queue_adapter = :inline
sequence = OidMinterService.initialize_sequence!
current = ActiveRecord::Base.connection.execute("SELECT last_value from OID_SEQUENCE").first['last_value']
puts "Oid Minter Initialized, initialization was #{sequence}, current value is #{current}"

[
  {
    metadata_cloud_name: "ladybird",
    display_name: "Ladybird",
    file_prefix: ""
  },
  {
    metadata_cloud_name: "ils",
    display_name: "Voyager",
    file_prefix: "V-"
  },
  {
    metadata_cloud_name: "aspace",
    display_name: "ArchiveSpace",
    file_prefix: "AS-"
  }
].each do |obj|
  MetadataSource.where(metadata_cloud_name: obj[:metadata_cloud_name]).first_or_create do |ms|
    ms.display_name = obj[:display_name]
    ms.file_prefix = obj[:file_prefix]

    puts "MetadataSource created #{ms.metadata_cloud_name}"
  end
end
puts "MetadataSources verified"


[
    {
      key: "brbl",
      label: "Beinecke Library",
      summary: "Beinecke Library",
      homepage: "https://beinecke.library.yale.edu/"
    },
    {
      key: "sml",
      label: "Sterling Memorial Library",
      summary: "Sterling Memorial Library",
      homepage: "https://web.library.yale.edu/building/sterling-library"
    }
].each do |obj|
  admin_set = AdminSet.where(key: obj[:key]).first
  if admin_set.nil?
    AdminSet.create!(obj)
  end
end
puts "Verifying ParentObjects have AdminSets"
admin_set = AdminSet.find_by_key("brbl")
ParentObject.where(admin_set_id: nil).update_all(admin_set_id: admin_set.id)
puts "AdminSets verified"

if Rails.env.development?
  require 'csv'

  oid_path = Rails.root.join("db", "parent_oids_short.csv")
  fixture_ids_table = CSV.read(oid_path, headers: true)
  oids = fixture_ids_table.by_col[0]

  oids.each do |row|
    ParentObject.where(oid: row).first_or_create do |po|
      po.oid = row
      po.visibility = "Public"
      po.admin_set = AdminSet.find_by_key("brbl")
      puts "Parent Object created #{po.oid}"
    end
  end
  puts "There are now #{ParentObject.count} rows in the parent object table"
end

# create users and delete old ones based on file or S3
if File.exist? Rails.root.join("config", "cas_users.csv")
  user_csv = File.read(Rails.root.join("config", "cas_users.csv"))
else
  user_csv = S3Service.download("authorization/cas_users.csv")
end
authorized_uids = []
prior_uids = User.pluck(:uid)
CSV.parse(user_csv, headers: false) do |row|
  uid = row[0]
  @user = User.where(provider: "cas", uid: uid).first
  if @user.nil?
    @user = User.create(
        provider: "cas",
        uid: uid,
        email: "#{uid}@connect.yale.edu",
        first_name: "first_name",
        last_name:"last_name"
    )
  else
    @user.deactivated ||= false
    @user.email ||= "#{@user.uid}@connect.yale.edu"
    @user.first_name ||= "first_name"
    @user.last_name ||= "last_name"
    @user.save!
  end
  authorized_uids.push uid
end
