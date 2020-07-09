# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

require 'csv'

oid_path = Rails.root.join("db", "parent_oids.csv")
fixture_ids_table = CSV.read(oid_path, headers: true)
oids = fixture_ids_table.by_col[0]

oids.each do |row|
  po = ParentObject.new
  po.oid = row
  po.save
  puts "#{po.oid} saved"
end

puts "There are now #{ParentObject.count} rows in the parent object table"

3.times do |user|
  User.create!(
    :email => "user#{user}@example.com",
    :password => 'testing123'
  )
end

puts "3 Users created"

