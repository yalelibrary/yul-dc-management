
class MetadataSamplingService

  def self.ladybird_field_statistics(csv_path=Rails.root.join("spec", "fixtures", "public_oids_comma.csv"), number_of_oids=10)
    sample_oids = oids_for_measurement(csv_path, number_of_oids)
    retrieve_sample_ladybird_fields(sample_oids)
    summarize_findings
  end

  def self.oids_for_measurement(csv_path, number_of_oids)
    oids = FixtureParsingService.build_oid_array(csv_path)
    oids.sample(number_of_oids)
  end

  def self.retrieve_sample_ladybird_fields(sample_oids)
    sample_oids.each do |oid|
      metadata_cloud_url = MetadataCloudService.build_metadata_cloud_url(oid, "ladybird")
      full_response = MetadataCloudService.mc_get(metadata_cloud_url)
      fields = JSON.parse(full_response.body).keys
      collected_fields.push(fields)
    end
  end

  def self.summarize_findings
    cf = collected_fields.flatten
    total_field_count = cf.count
    unique_field_count = cf.uniq.count
  end

  def self.collected_fields
    @collected_fields ||= []
  end

end
