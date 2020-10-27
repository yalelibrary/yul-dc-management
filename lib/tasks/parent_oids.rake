# frozen_string_literal: true

namespace :parent_oids do
  desc "Create list of random selection of parent oids"
  task :random, [:samples] do |t, args|
    oid_path = Rails.root.join("spec", "fixtures", "public_oids_comma.csv")
    fixture_ids_table = CSV.read(oid_path, headers: true)
    oids = fixture_ids_table.by_col[0]
    random_parent_oids = oids.sample(args[:samples].to_i)
    CSV.open(File.join("data", "random_parent_oids.csv"), "wb") do |csv|
      csv << ["oid"]
      random_parent_oids.map { |oid| csv << [oid]  }
    end
  end
end
