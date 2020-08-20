# frozen_string_literal: true

module StubRequestHelper
  def stub_metadata_cloud(oid, source_name = 'ladybird')
    vpn = ENV["VPN"]
    allowed_sites = ["solr", MetadataCloudService.metadata_cloud_host, "localhost"]
    if vpn == "true"
      WebMock.disable_net_connect!(allow: allowed_sites)
      stub_request(:put, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/#{source_name}/#{oid}.json").to_return(status: 200)
    else
      stub_request(:get, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/#{source_name}/#{oid}.json")
        .to_return(status: 200, body: File.open(File.join(fixture_path, source_name, "#{oid}.json")))
    end
  end
end
