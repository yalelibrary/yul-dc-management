# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "metadata_samples/show", type: :view do
  before do
    @metadata_sample = assign(:metadata_sample, MetadataSample.create!(
                                                  metadata_source: "Metadata Source",
                                                  number_of_samples: 2,
                                                  seconds_elapsed: "9.99"
                                                ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Metadata Source/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/9.99/)
  end
end
