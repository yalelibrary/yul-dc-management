# frozen_string_literal: true

# To deliver this notification:
#
# IngestNotification.with(post: @post).deliver_later(current_user)
# IngestNotification.with(post: @post).deliver(current_user)

class IngestNotification < Noticed::Base
  # Add your delivery methods

  deliver_by :database, format: :to_database
  # deliver_by :email, mailer: "UserMailer"
  # deliver_by :slack
  # deliver_by :custom, class: "MyDeliveryMethod"

  def to_database
    {
      type: self.class.name,
      params: params
    }
  end

  # Add required params
  # param :batch_process_id
  param :parent_object_id
  param :reason
  param :status

  # Define helper methods to make rendering easier.

  def deliver_all
    User.find_each do |user|
      deliver(user)
    end
  end

  def batch_process
    BatchProcess.find_by_id(params[:batch_process_id]) if params[:batch_process_id]
  end

  def parent_object
    ParentObject.find_by_oid(params[:parent_object_id]) if params[:parent_object_id]
  end

  def message
    t(".message", oid: params[:parent_object_id], status: params[:status], reason: params[:reason], batch_process: batch_process)
  end
end
