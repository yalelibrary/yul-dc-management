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

  desc "Generate pagination labels"
  task generate_labels: :environment do
    # Grab all the child oids
    all_child_oids = []
    parent_table = CSV.parse(File.read(Rails.root.join('spec', 'fixtures', 'csv', 'full_text_staged.csv')), headers: true)
    parent_oids = parent_table.by_col[0]
    parent_oids.map do |p|
      po = ParentObject.find_by(oid: p)
      next if po.nil?
      all_child_oids << po.child_objects.map(&:oid)
    end
    # check if label is "", " ", or nil
    not_labeled_children = []
    all_child_oids.flatten.each do |o|
      co = ChildObject.find_by(oid: o)
      # put those missing labels into an array
      not_labeled_children << co unless co.label.present?
    end
    # map over them
    not_labeled_children.each do |c|
      # get child object order
      c.label = "page #{c.order}"
      # and save label to child object
      c.save!
    end
  end
end
