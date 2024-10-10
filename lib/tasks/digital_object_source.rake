  # bin/rails update_digital_object_source
  desc "Update digital object source"
  task update_digital_object_source: :environment do
    # check count before
    before_count = ParentObject.where(digital_object_source: nil).count
    puts "nil object_source objects before: #{before_count}"
    ParentObject.where(digital_object_source: nil).in_batches.update_all(digital_object_source: "None")
    # check count after
    after_count = ParentObject.where(digital_object_source: nil).count
    puts "nil object_source objects after: #{after_count}"
  end