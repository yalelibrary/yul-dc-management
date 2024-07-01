# frozen_string_literal: true

module IntegrityCheckable
  extend ActiveSupport::Concern

  def integrity_check(child_objects)
    # check for file presence
    # check that file checksum matches what is saved in database
    # mark child object as complete / successful if both checks pass
  end

  # model / child object

  # def remote_ptiff_exists?
  #   remote_metadata
  # end

  # moved the code below to the job itself
  # lib/ activity stream reader

  # def batch_process
  #   @batch_process ||= BatchProcess.create!(batch_action: 'activity stream updates', user: User.system_user)
  # end
end
