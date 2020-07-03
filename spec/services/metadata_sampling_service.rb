# frozen_string_literal: true
require "rails_helper"

WebMock.allow_net_connect!

RSpec.describe MetadataSamplingService, vpn_only: true do
  # Note: Currently in order to get these tests to pass, you must be on the VPN and run them
  # one at a time. The call and response to the MetadataCloud is slow enough that more than that
  # breaks the test. My understanding is that this is more of an information-gathering portion of the code,
  # so it's not clear that mocking out the randomness & calls to the cloud are a good use of time.

  context "before an after running the task" do
    context "before running the task" do
      it "has no MetadataSample or SampleFields records prior to running the task" do
        expect(MetadataSample.count).to eq 0
        expect(SampleField.count).to eq 0
      end
    end

    context "after running the task" do
      before do
        described_class.field_statistics
      end

      it "has created one MetadataSample and several SampleField records" do
        expect(MetadataSample.count).to eq 1
        expect(SampleField.count).to be > 5
      end

      it "records the time elapsed" do
        expect(MetadataSample.last.seconds_elapsed).not_to be nil
      end
    end
  end


  xit "can retrieve from different metadata sources" do
    expect(MetadataSample.count).to eq 0
    described_class.field_statistics("ladybird", 12)
    expect(MetadataSample.count).to eq 1
    expect(MetadataSample.last.metadata_source).to eq "ladybird"
    expect(MetadataSample.last.number_of_samples).to eq 12
    described_class.field_statistics("ils", 4)
    expect(MetadataSample.last.metadata_source).to eq "ils"
    expect(MetadataSample.last.number_of_samples).to eq 4
  end

end
