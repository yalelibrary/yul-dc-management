# frozen_string_literal: true

module ParentChildObjectHelper
  # Saving a parent object runs the full metadata update inline when the spec wraps it in
  # perform_enqueued_jobs (manifest, PDF, Solr index with a hard commit), which can take longer than
  # Capybara's default wait in CI.
  PARENT_OBJECT_SAVE_WAIT = 30

  # Clicks "Save Parent Object And Update Metadata" and waits for the save to finish.
  # Not for specs that expect the save to fail or that answer a confirm dialog first.
  def save_parent_object
    click_on("Save Parent Object And Update Metadata")
    expect(page).to have_content("Parent object was successfully saved", wait: PARENT_OBJECT_SAVE_WAIT)
  end

  def recreate_children(parent_object)
    parent_object.child_object_count ||= 0
    ladybird_json = {}
    ladybird_json["children"] = []

    ChildObject.where(parent_object_oid: parent_object.oid).each do |child|
      parent_object.child_objects.push(child) unless parent_object.child_objects.include?(child)
      ladybird_json["children"] << child
      parent_object.child_object_count += 1
    end
    parent_object.ladybird_json = ladybird_json if parent_object.ladybird_json.blank?

    ChildObject.delete_by(parent_object_oid: parent_object.oid)
    parent_object.create_child_records
    parent_object # return new parent if the parent and child aren't actually linked due to test shenanigans
  end
end
