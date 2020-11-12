# frozen_string_literal: true

namespace :authorized_users do
  desc "Upload authorized users to S3"
  task upload: :environment do
    data = File.read(Rails.root.join("config", "cas_users.csv"))
    S3Service.upload("authorization/cas_users.csv", data)
    Rails.logger.info("Uploaded CSV\n#{data}")
  end
end
