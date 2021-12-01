# frozen_string_literal: true
require 'rails_helper'

RSpec.describe JsonHelper, type: :helper do
  let(:admin_set) { FactoryBot.create(:admin_set) }
  let(:metadata_source) { FactoryBot.create(:metadata_source) }
  let(:parent_object_with_authoritative_json) do
    FactoryBot.create(
      :parent_object,
      oid: '16712419',
      authoritative_metadata_source: metadata_source,
      admin_set: admin_set,
      ladybird_json: JSON.parse(File.read(File.join(fixture_path, "ladybird", "16712419.json")))
    )
  end

  it 'formats json' do
    formatted = formatted_json(parent_object_with_authoritative_json.authoritative_json)
    expect(formatted).to include('<div class="CodeRay">')
  end
end
