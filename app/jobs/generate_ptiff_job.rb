# frozen_string_literal: true

class GeneratePtiffJob < ApplicationJob
  queue_as :default

  def perform(child_object)
    # Currently commented out because error handling is not yet robust enough
    # to fully background this work. Uncomment when the background job continues to the
    # next child_object & gives error reporting without halting the process when:
    # - It cannot find the original_access_master
    # - The ptiff conversion fails for any reason
    # - The remote ptiff already exists (info, not error)
    # PyramidalTiffFactory.generate_ptiff_from(child_object)
  end
end
