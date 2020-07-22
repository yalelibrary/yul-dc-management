# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

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

[{
  email: "goobi@yale.edu",
  password: ENV["GOOBI_USER_PASSWORD"] || "testing123"
  },
{
  email: "admin@yale.edu",
  password: ENV["ADMIN_USER_PASSWORD"] || "testing123"
}].each do |obj|
  User.where(email: obj[:email]).first_or_create do |u|
    u.password = obj[:password]

    puts "User created #{u.email}"
  end
end
puts "Initial users verified"

if Rails.env.development?
  require 'csv'

  oid_path = Rails.root.join("db", "parent_oids.csv")
  fixture_ids_table = CSV.read(oid_path, headers: true)
  oids = fixture_ids_table.by_col[0]

  oids.each do |row|
    ParentObject.where(oid: row).first_or_create do |po|
      po.oid = row
      puts "Parent Object created #{po.oid}"
    end
  end
  puts "There are now #{ParentObject.count} rows in the parent object table"
end
