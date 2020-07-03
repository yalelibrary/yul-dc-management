# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "metadata_samples/new", type: :view do
  before do
    assign(:metadata_sample, MetadataSample.new(
                               metadata_source: "MyString",
                               number_of_samples: 1,
                               seconds_elapsed: "9.99"
                             ))
  end

  it "renders new metadata_sample form" do
    render

    assert_select "form[action=?][method=?]", metadata_samples_path, "post" do
      assert_select "input[name=?]", "metadata_sample[metadata_source]"

      assert_select "input[name=?]", "metadata_sample[number_of_samples]"

      assert_select "input[name=?]", "metadata_sample[seconds_elapsed]"
    end
  end
end
