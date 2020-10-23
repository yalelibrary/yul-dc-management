# frozen_string_literal: true
require "rails_helper"
require "support/time_helpers"
require "English"

RSpec.describe Class do
  context "image conversion" do
    it "do not fail with this weird image" do
      Dir.mktmpdir do |d|
        expect(`app/lib/tiff_to_pyramid.bash #{d} spec/fixtures/images/bad_flag.tiff #{d}/output.tiff`).to match(/Pyramid width: 1490\nPyramid height: 1525/)
        expect($CHILD_STATUS).to eq 0
      end
    end

    it "do not fail with this other weird image" do
      Dir.mktmpdir do |d|
        expect(`app/lib/tiff_to_pyramid.bash #{d} spec/fixtures/images/bad_icc.tiff #{d}/output.tiff`).to match(/Pyramid width: 2014\nPyramid height: 3072/)
        expect($CHILD_STATUS).to eq 0
      end
    end
  end
end
