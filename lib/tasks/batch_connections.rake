# frozen_string_literal: true

namespace :batch_connections do
  desc "Create list of random selection of parent oids"
  task update_status: :environment do
    BatchConnection.all.map(&:update_status!)
  end
end
