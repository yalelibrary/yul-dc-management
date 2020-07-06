# frozen_string_literal: true
require "rails_helper"

WebMock.allow_net_connect!

RSpec.describe MetadataSamplingService, vpn_only: true do
  context "before an after running the task" do
    context "before running the task" do
      it "has no MetadataSample or SampleFields records prior to running the task" do
        expect(MetadataSample.count).to eq 0
        expect(SampleField.count).to eq 0
      end
    end

    context "after running the task" do
      before do
        described_class.get_field_statistics(metadata_sample)
      end
      let(:metadata_sample) do
        FactoryBot.create(
          :metadata_sample,
          metadata_source: "ladybird",
          number_of_samples: 3
        )
      end
      let(:sample_fields) { SampleField.where(metadata_sample_id: MetadataSample.last.id) }

      it "has created one MetadataSample and several SampleField records" do
        expect(MetadataSample.count).to eq 1
        expect(SampleField.count).to be > 5
        expect(MetadataSample.last.seconds_elapsed).not_to be nil
        expect(sample_fields.where("field_count > 3")).to be_empty
      end
    end
  end

  xit "can retrieve from different metadata sources" do
    expect(MetadataSample.count).to eq 0
    described_class.get_field_statistics("ladybird", 12)
    expect(MetadataSample.count).to eq 1
    expect(MetadataSample.last.metadata_source).to eq "ladybird"
    expect(MetadataSample.last.number_of_samples).to eq 12
    described_class.get_field_statistics("ils", 4)
    expect(MetadataSample.last.metadata_source).to eq "ils"
    expect(MetadataSample.last.number_of_samples).to eq 4
  end
end
