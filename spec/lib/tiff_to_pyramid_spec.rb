# frozen_string_literal: true
require "rails_helper"
require "support/time_helpers"

RSpec.describe "PtiffScript" do

  context "image conversion" do
    it "should not fail with this weird image" do
      Dir.mktmpdir do |d|
        expect(`app/lib/tiff_to_pyramid.bash #{d} spec/fixtures/images/bad_flag.tiff #{d}/output.tiff`).to match /Pyramid width: 1490\nPyramid height: 1525/
        expect($?).to eq 0
      end
    end
  end
end
