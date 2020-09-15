# frozen_string_literal: true

namespace :child_objects do
  desc "Save child oids to CSV"
  task save_child_oids_to_csv: :environment do
    all_child_oids = []
    ParentObject.all.map do |p|
      all_child_oids << p.child_objects.map(&:oid)
    end
    csv_child_oids = all_child_oids.flatten.to_csv
    File.write(File.join("data", "child_oids.csv"), csv_child_oids)
  end
end
