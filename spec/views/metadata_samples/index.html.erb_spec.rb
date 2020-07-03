# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "metadata_samples/index", type: :view do
  before do
    assign(:metadata_samples, [
             MetadataSample.create!(
               metadata_source: "Metadata Source",
               number_of_samples: 2,
               seconds_elapsed: "9.99"
             ),
             MetadataSample.create!(
               metadata_source: "Metadata Source",
               number_of_samples: 2,
               seconds_elapsed: "9.99"
             )
           ])
  end

  it "renders a list of metadata_samples" do
    render
    assert_select "tr>td", text: "Metadata Source".to_s, count: 2
    assert_select "tr>td", text: 2.to_s, count: 2
    assert_select "tr>td", text: "9.99".to_s, count: 2
  end
end
