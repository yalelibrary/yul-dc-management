# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Geojson do

  describe "Initializing Geojson " do
    it "fails with null data in first point" do
      g = Geojson.new(nil, nil, 1, 2)
      expect(g.valid).to be_falsey
    end

    it "fails with string data in first point" do
      g = Geojson.new("foo", "bar", 1, 2)
      expect(g.valid).to be_falsey
    end

    it "fails with high latitude value in first point" do
      g = Geojson.new(91, 1, 1, 2)
      expect(g.valid).to be_falsey
    end

    it "fails with low latitude value in first point" do
      g = Geojson.new(-90.001, 1, 1, 2)
      expect(g.valid).to be_falsey
    end

    it "fails with high longitude value in first point" do
      g = Geojson.new(91, 1, 1, 2)
      expect(g.valid).to be_falsey
    end

    it "fails with low longitude value in first point" do
      g = Geojson.new(-90.001, 1, 1, 2)
      expect(g.valid).to be_falsey
    end

    it "returns type Point with null data in second point" do
      g = Geojson.new(1, 2, nil, nil)
      expect(g.valid).to be_truthy
      expect(g.type).to eq 'Point'
    end

    it "returns type Point with string representation of coordinates" do
      g = Geojson.new("N0550000", "E0260000", nil, nil)
      expect(g.valid).to be_truthy
      expect(g.type).to eq 'Point'
    end

    it "returns type Point with string data in second point" do
      g = Geojson.new( 1, 2, "foo", "bar")
      expect(g.valid).to be_truthy
      expect(g.type).to eq 'Point'
    end

    it "returns type Point when points match" do
      g = Geojson.new( 1.0, 2.0, 1.0, 2.0)
      expect(g.valid).to be_truthy
      expect(g.type).to eq 'Point'
    end

    it "returns type Polygon when points do not match" do
      g = Geojson.new( 1.0, 2.0, 5.0, 8.0)
      expect(g.valid).to be_truthy
      expect(g.type).to eq 'Polygon'
    end
  end

  describe "Geojson coordinates" do
    it "returns the correct coordinates for a Polygon" do
      expected_coords = [[[7.1915,49.4037],[6.2819,49.4037],[6.2819,49.0756],[7.1915,49.0756],[7.1915,49.4037]]]
      g = Geojson.new( 7.1915,49.4037, 6.2819, 49.0756)
      expect(g.valid).to be_truthy
      expect(g.type).to eq 'Polygon'
      expect(g.coords).to eq expected_coords
    end

    it "returns the correct coordinates for a Point" do
      expected_coords = [12.4663, 41.9031]
      g = Geojson.new(12.4663, 41.9031, nil, nil)
      expect(g.valid).to be_truthy
      expect(g.type).to eq 'Point'
      expect(g.coords).to eq expected_coords
    end

    it "returns correct coordinates with string representation of coordinates" do
      expected_coords = [55.0, 26.002]
      g = Geojson.new("N0550000", "E0260020", nil, nil)
      expect(g.valid).to be_truthy
      expect(g.type).to eq 'Point'
      expect(g.coords).to eq expected_coords
    end
  end

end