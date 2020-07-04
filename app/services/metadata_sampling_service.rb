# frozen_string_literal: true

class MetadataSamplingService
  def self.get_field_statistics(metadata_sample)
    start_time
    csv_path = Rails.root.join("spec", "fixtures", "public_oids_comma.csv")
    sample_oids = oids_for_measurement(csv_path, metadata_sample.number_of_samples)
    retrieve_sample_fields(sample_oids, metadata_sample.metadata_source)
    record_initial_findings(metadata_sample)
    record_time_elapsed(metadata_sample)
  end

  def self.record_time_elapsed(metadata_sample)
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

  def self.record_initial_findings(metadata_sample)
    cf = collected_fields.flatten
    grouped_fields = cf.group_by(&:itself).transform_values(&:count)
    grouped_fields.each do |key, value|
      field_over_total = value.to_f / grouped_fields.values.sum
      percent = field_over_total * 100
      sf = SampleField.new
      sf.update(
        field_name: key,
        field_count: value,
        field_percent_of_total: percent.round(2),
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
