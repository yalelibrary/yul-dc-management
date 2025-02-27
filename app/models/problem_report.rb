# frozen_string_literal: true

class ProblemReport < ApplicationRecord
  def child_problem_headers
    ['admin_set', 'parent_oid', 'child_oid', 'last_modified']
  end

  def generate_child_problem_csv(send_email = false)
    start_generating
    csv_rows = problem_children_csv
    parent_oids = Set.new
    output_csv = CSV.generate do |csv|
      csv << child_problem_headers
      csv_rows.each do |row|
        csv << row
        parent_oids << row[1]
      end
    end
    total_child_cnt = ChildObject.select(:oid).where('height is NULL or height = 0 or width is NULL or width = 0').count
    save_results(parent_oids.count, total_child_cnt)
    report_complete(output_csv, send_email)
  rescue => e
    report_error("CSV generation failed due to #{e.message}")
  end

  def report_complete(output_csv, send_email)
    save_report_to_s3(output_csv)
    self.status = "Report Uploaded"
    save!
    send_report_email(output_csv) if send_email
  end

  def send_report_email(csv)
    email_address = ENV['INGEST_ERROR_EMAIL'].presence
    ProblemReportMailer.with(problem_report: self).problem_report_email(email_address, csv).deliver_later if email_address
  end

  def start_generating
    self.status = "Generating Report"
    self.child_count = ChildObject.count
    self.parent_count = ParentObject.count
    save!
  end

  def save_results(parent_cnt, child_cnt)
    self.problem_parent_count = parent_cnt
    self.problem_child_count = child_cnt
    self.status = "Report Generated"
    save!
  end

  def remote_csv_path
    @remote_csv_path ||= "report/#{id}/problem_report_#{id}.csv"
  end

  def s3_presigned_url
    S3Service.presigned_url(remote_csv_path, 24_000, ENV['SAMPLE_BUCKET']) if status == "Report Uploaded"
  end

  def problem_children_csv
    ChildObject.includes(:parent_object).where('height is NULL or height = 0 or width is NULL or width = 0').order("parent_objects.admin_set_id", :parent_object_oid, :oid).limit(1000).map do |co|
      [co.parent_object.admin_set.key, co.parent_object.oid, co.oid, co.updated_at]
    end
  end

  def save_report_to_s3(csv)
    S3Service.upload_csv(remote_csv_path, csv, "text/csv; charset=UTF-8; header=present")
  rescue => e
    report_error("CSV upload failed due to #{e.message}")
  end

  def report_error(msg)
    self.status = "Error: #{msg}"
    save!
  end
end
