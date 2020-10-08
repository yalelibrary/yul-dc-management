# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BatchProcessEvent, type: :model, prep_metadata_sources: true do
  let(:bpe) { FactoryBot.create(:batch_process_event) }
  it "can be instantiated" do
    bpe
  end
end
