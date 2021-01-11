# frozen_string_literal: true

# TODO: this is a onetime thing for a data migration
# it can be removed after 3/1/2021
class AddRightsToParentObjectsJob < ApplicationJob
  queue_as :default

  def default_priority
    -100
  end

  def perform(*_args)
    ParentObject.where(rights_statement: nil).find_each do |parent|
      parent.rights_statement = parent.ladybird_json&.[]("rights")&.first
      parent.save!
    end
  end
end
