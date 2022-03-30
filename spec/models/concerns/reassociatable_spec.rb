# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reassociatable, type: :model do
  let(:reassociatable) { BatchProcess.new }
  let(:metadata_source) { FactoryBot.create(:metadata_source) }
  let(:parent_object) { FactoryBot.create(:parent_object, oid: '222', authoritative_metadata_source: metadata_source) }
  let(:child_object) { FactoryBot.create(:child_object, oid: "1", label: "original label", caption: "original caption", viewing_hint: "original viewing hint", order: 5, parent_object: parent_object) }

  it "blanks out fields which can be blanked" do
    values = { "label" => "_blank_", "caption" => "_blank_", "viewing_hint" => "_blank_" }
    allow(child_object).to receive(:save).and_return(true)
    reassociatable.update_child_values(values.keys, child_object, values, 0)
    expect(child_object.label).to be_nil
    expect(child_object.caption).to be_nil
    expect(child_object.viewing_hint).to be_nil
    expect(child_object.order).to be(5)
  end

  it "does not blank out order, which can not be blanked" do
    allow(child_object).to receive(:save).and_return(true)
    expect(reassociatable).to receive(:batch_processing_event).with("Skipping row [2] with invalid order [_blank_] (Parent: , Child: )", "Skipped Row")
    values = { "order" => "_blank_", "label" => "_blank_", "caption" => "_blank_", "viewing_hint" => "_blank_" }
    reassociatable.update_child_values(values.keys, child_object, values, 0)
    expect(child_object.order).to be(5)
  end
end
