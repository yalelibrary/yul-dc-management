# frozen_string_literal: true

module StubRequestHelper
  def stub_metadata_cloud(oid, source_name='ladybird')
    stub_request(:get, "https://yul-development-samples.s3.amazonaws.com/#{source_name}/#{oid}.json")
      .to_return(status: 200, body: File.open(File.join(fixture_path, source_name, "#{oid}.json")))
  end
end
