# frozen_string_literal: true
# Inspired by https://gist.github.com/ascendbruce/7070951 on 8/5/2020

require 'rails_helper'

RSpec.describe JsonValidator do
  it "can evaluate json objects as valid" do
    expect(described_class.valid?(%({"a": "b", "c": 1, "d": true}))).to eq true
    expect(described_class.valid?("{}")).to eq true
    expect(described_class.valid?("[1, 2, 3]")).to eq true
  end

  it "can evaluate a valid json string as not a valid json object" do
    expect(described_class.valid?("")).to eq false
    expect(described_class.valid?("123")).to eq false
  end

  it "can evaluate other types as not a valid json object" do
    expect(described_class.valid?(nil)).to eq false
    expect(described_class.valid?(true)).to eq false
    expect(described_class.valid?(123)).to eq false
  end
end
