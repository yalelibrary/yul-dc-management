
class MetadataSamplingService

  def self.field_statistics(metadata_source="ladybird", number_of_records=2)
    start_time
    csv_path = Rails.root.join("spec", "fixtures", "public_oids_comma.csv")
    sample_oids = oids_for_measurement(csv_path, number_of_records)
    retrieve_sample_fields(sample_oids, metadata_source)
    create_metadata_sample(metadata_source, number_of_records)
    record_initial_findings
    record_time_elapsed
  end

  def self.create_metadata_sample(metadata_source, number_of_records)
    metadata_sample.update(
      metadata_source: metadata_source,
      number_of_samples: number_of_records
    )
    metadata_sample.save!
  end

  def self.metadata_sample
    @metadata_sample ||= MetadataSample.new
  end

  def self.record_time_elapsed
    elapsed_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time
    metadata_sample.update(
      seconds_elapsed: elapsed_time
    )
    metadata_sample.save!
  end

  def self.oids_for_measurement(csv_path, number_of_records)
    oids = FixtureParsingService.build_oid_array(csv_path)
    oids.sample(number_of_records)
  end

  def self.retrieve_sample_fields(sample_oids, metadata_source)
    sample_oids.each do |oid|
      metadata_cloud_url = MetadataCloudService.build_metadata_cloud_url(oid, metadata_source)
      full_response = MetadataCloudService.mc_get(metadata_cloud_url)
      fields = JSON.parse(full_response.body).keys
      collected_fields.push(fields)
    end
  end

  def self.record_initial_findings
    cf = collected_fields.flatten
    grouped_fields = cf.group_by(&:itself).transform_values(&:count)
    total_fields_found = grouped_fields.values.sum
    grouped_fields.each do |field|
      field_over_total = field[1].to_f / grouped_fields.values.sum
      percent = field_over_total * 100
      sf = SampleField.new
      sf.update(
        field_name: field[0],
        field_count: field[1],
        field_percent_of_total: percent.round(4),
        metadata_sample_id: metadata_sample.id
      )
    end
  end

  def self.collected_fields
    @collected_fields ||= []
  end

  def self.start_time
    @start_time ||= Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

end
