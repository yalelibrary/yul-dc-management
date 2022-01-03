# frozen_string_literal: true

# frozen_string_literal

class CsvExport
  def initialize(csv, batch_process)
    @csv = csv
    @batch_process = batch_process
  end

  def fetch
    S3Service.download(@batch_process.remote_csv_path)
  end

  def save
    S3Service.upload_if_changed(@batch_process.remote_csv_path, @csv)
  end
end
