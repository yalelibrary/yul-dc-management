# frozen_string_literal: true

class PermissionRequestDatatable < ApplicationDatatable
  extend Forwardable

  def_delegators :@view, :link_to, :permission_request_path, :permission_set_path, :content_tag

  def initialize(params, opts = {})
    @view = opts[:view_context]
    @current_ability = opts[:current_ability]
    @set_labels = OpenWithPermission::PermissionSet.order(:label).distinct.pluck(:label)
    super
  end

  def view_columns
    # Declare strings in this format: ModelName.column_name
    # or in aliased_join_table.column_name format
    @view_columns ||= {
      id: { source: "OpenWithPermission::PermissionRequest.id", cond: :start_with, searchable: true, orderable: true },
      permission_set: { source: "OpenWithPermission::PermissionSet.label", cond: :string_eq, searchable: true, options: @set_labels, orderable: true },
      request_date: { source: "OpenWithPermission::PermissionRequest.created_at", searchable: true, orderable: true },
      oid: { source: "ParentObject.oid", cond: :start_with, searchable: true, orderable: true },
      user_name: { source: "OpenWithPermission::PermissionRequest.permission_request_user_name", cond: :start_with, searchable: true, orderable: true },
      sub: { source: "OpenWithPermission::PermissionRequestUser.sub", cond: :start_with, searchable: true, orderable: true },
      net_id: { source: "OpenWithPermission::PermissionRequestUser.netid", cond: :start_with, searchable: true, orderable: true },
      request_status: { source: "OpenWithPermission::PermissionRequest.request_status", cond: :start_with, searchable: true, orderable: true },
      approver_note: { source: "OpenWithPermission::PermissionRequest.approver_note", cond: :start_with, searchable: true, orderable: true },
      approved_or_denied_at: { source: "OpenWithPermission::PermissionRequest.approved_or_denied_at", cond: :start_with, searchable: true, orderable: true },
      access_until: { source: "OpenWithPermission::PermissionRequest.access_until", cond: :start_with, searchable: true, orderable: true },
      approver: { source: "OpenWithPermission::PermissionRequest.approver", cond: :start_with, searchable: true, orderable: true }
    }
  end

  # rubocop:disable Rails/OutputSafety
  def data
    records.map do |permission_request|
      {
        DT_RowId: permission_request.id,
        id: id_column(permission_request).html_safe,
        permission_set: link_to(permission_request.permission_set.label, permission_set_path(permission_request.permission_set)),
        request_date: permission_request.created_at,
        oid: permission_request.parent_object.oid,
        user_name: permission_request.permission_request_user_name,
        sub: permission_request.permission_request_user.sub,
        net_id: permission_request.permission_request_user.netid,
        request_status: permission_request.request_status,
        approver_note: permission_request.approver_note,
        approved_or_denied_at: permission_request.approved_or_denied_at,
        access_until: permission_request.access_until,
        approver: permission_request.approver
      }
    end
  end
  # rubocop:enable Rails/OutputSafety

  def id_column(permission_request)
    link_to(permission_request.id, permission_request_path(permission_request))
  end

  def with_icon(class_name, path, options = {})
    link_to(path, options) do
      content_tag(:i, '', class: class_name)
    end
  end

  def get_raw_records # rubocop:disable Naming/AccessorMethodName
    OpenWithPermission::PermissionRequest.accessible_by(@current_ability, :read).joins(:permission_set, :parent_object, :permission_request_user)
  end
end
