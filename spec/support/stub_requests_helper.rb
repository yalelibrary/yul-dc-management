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

  # rubocop:enable RSpec/AnyInstance
end
