# frozen_string_literal: true

module StubRequestHelper
  def stub_metadata_cloud(oid, source_name = 'ladybird')
    vpn = ENV["VPN"]
    allowed_sites = ["solr", MetadataSource.metadata_cloud_host, "localhost"]
    if vpn == "true"
      WebMock.disable_net_connect!(allow: allowed_sites)
      stub_request(:put, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/#{source_name}/#{oid}.json").to_return(status: 200)
    else
      stub_request(:get, "https://#{ENV['SAMPLE_BUCKET']}.s3.amazonaws.com/#{source_name}/#{oid}.json")
        .to_return(status: 200, body: File.open(File.join(fixture_path, source_name, "#{oid}.json")))
    end
  end

  def stub_ptiffs_and_manifests
    stub_ptiffs
    stub_manifests
    stub_pdfs
  end

  # rubocop:disable RSpec/AnyInstance
  def stub_ptiffs
    allow_any_instance_of(PyramidalTiff).to receive(:generate_ptiff).and_return(width: 2591, height: 4056)
    allow_any_instance_of(PyramidalTiff).to receive(:valid?).and_return(true)
    allow_any_instance_of(PyramidalTiff).to receive(:conversion_information).and_return(width: 2591, height: 4056)
    allow_any_instance_of(ChildObject).to receive(:remote_ptiff_exists?).and_return(true)
    allow_any_instance_of(ChildObject).to receive(:remote_metadata).and_return(width: 2591, height: 4056)
  end

  def stub_manifests
    allow_any_instance_of(IiifPresentationV3).to receive(:save).and_return(true)
    allow_any_instance_of(IiifPresentationV3).to receive(:save).and_return(true)
    allow_any_instance_of(ParentObject).to receive(:manifest_completed?).and_return(true)
  end

  def stub_pdfs
    allow_any_instance_of(PdfRepresentable).to receive(:generate_pdf).and_return(true)
  end
  # rubocop:enable RSpec/AnyInstance

  def stub_full_text(oid)
    pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
    stub_request(:get, "https://#{ENV['OCR_DOWNLOAD_BUCKET']}.s3.amazonaws.com/fulltext/#{pairtree_path}/#{oid}.txt")
        .to_return(status: 200, body: File.exist?(File.join(fixture_path, "full_text", "#{oid}.txt")) ? File.open(File.join(fixture_path, "full_text", "#{oid}.txt")) : "#{oid} full text")
    stub_request(:head, "https://#{ENV['OCR_DOWNLOAD_BUCKET']}.s3.amazonaws.com/fulltext/#{pairtree_path}/#{oid}.txt")
        .to_return(status: 200, headers: { 'Content-Type' => 'text/plain' })
  end

  def stub_full_text_not_found(oid)
    pairtree_path = Partridge::Pairtree.oid_to_pairtree(oid)
    stub_request(:head, "https://#{ENV['OCR_DOWNLOAD_BUCKET']}.s3.amazonaws.com/fulltext/#{pairtree_path}/#{oid}.txt")
        .to_return(status: 403)
    stub_request(:get, "https://#{ENV['OCR_DOWNLOAD_BUCKET']}.s3.amazonaws.com/fulltext/#{pairtree_path}/#{oid}.txt")
        .to_return(status: 404)
  end

  def stub_preservica_aspace_single
    stub_metadata_cloud("AS-200000000", "aspace")
  end

  def stub_preservica_login
    stub_request(:post, "https://testpreservica/api/accesstoken/login").to_return(status: 200, body: '{"token":"test", "validFor":15}')
    stub_request(:post, "https://testpreservica/api/accesstoken/refresh").to_return(status: 200, body: '{"token":"test", "validFor":15}')
  end

  # rubocop:disable Metrics/MethodLength
  def stub_preservica_fixtures_set_of_three_changing_generation
    fixtures = %w[preservica/api/entity/structural-objects/7fe35e8c-c21a-444a-a2e2-e3c926b519c5/children
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3r/representations
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3r/representations/Access
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3r/representations/Preservation
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/2
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1/bitstreams/1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/2/bitstreams/1
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3d/representations
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3d/representations/Access
                  preservica/api/entity/information-objects/1e42a2bb-8953-41b6-bcc3-1a19c86a5e3d/representations/Preservation
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations/1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations/1/bitstreams/1
                  preservica/api/entity/information-objects/f44ba97e-af2b-498e-b118-ed1247822f44/representations
                  preservica/api/entity/information-objects/f44ba97e-af2b-498e-b118-ed1247822f44/representations/Access
                  preservica/api/entity/information-objects/f44ba97e-af2b-498e-b118-ed1247822f44/representations/Preservation
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations/1
                  preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations/1/bitstreams/1]

    fixtures.each do |fixture|
      stub_request(:get, "https://test#{fixture}").to_return(
        status: 200, body: File.open(File.join(fixture_path, "#{fixture}.xml"))
      )
    end

    # changing fixtures
    stub_request(:get, "https://testpreservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations").to_return(
      status: 200, body: File.open(File.join(fixture_path, "preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations.xml"))
    ).times(2).then.to_return(
      status: 200, body: File.open(File.join(fixture_path, "preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations_2.xml"))
    )
  end
  # rubocop:enable Metrics/MethodLength

  def stub_preservica_tifs_set_of_three
    stub_request(:get, "https://testpreservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations/1/bitstreams/1/content").to_return(
      status: 200, body: File.open(File.join(fixture_path, "preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b487/generations/1/bitstreams/1/content.tif"), 'rb')
    )
    stub_request(:get, "https://testpreservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1/bitstreams/1/content").to_return(
      status: 200, body: File.open(File.join(fixture_path, "preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b486/generations/1/bitstreams/1/content.tif"), 'rb')
    )
    stub_request(:get, "https://testpreservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations/1/bitstreams/1/content").to_return(
      status: 200, body: File.open(File.join(fixture_path, "preservica/api/entity/content-objects/ae328d84-e429-4d46-a865-9ee11157b489/generations/1/bitstreams/1/content.tif"), 'rb')
    )
  end
end
