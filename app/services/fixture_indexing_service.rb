# frozen_string_literal: true

class FixtureIndexingService
  def self.index_fixture_data
  end

  def self.ladybird_metadata_path
    Rails.root.join('spec','fixtures','ladybird').to_s
  end
end