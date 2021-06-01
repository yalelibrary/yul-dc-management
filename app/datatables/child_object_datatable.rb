# frozen_string_literal: true

class ChildObjectDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegators :@view, :link_to, :child_object_path, :edit_child_object_path

  def initialize(params, opts = {})
    @view = opts[:view_context]
    @current_ability = opts[:current_ability]
    super
  end

  def view_columns
    # default values: 'searchable: true', 'orderable: true', 'cond: :like'
    # add those values here only for override purposes
    @view_columns ||= {
      oid: { source: 'ChildObject.oid' },
      label: { source: 'ChildObject.label' },
      caption: { source: 'ChildObject.caption' },
      width: { source: 'ChildObject.width' },
      height: { source: 'ChildObject.height' },
      order: { source: 'ChildObject.order' },
      parent_object: { source: 'ChildObject.parent_object_oid' },
      actions: { source: 'ChildObject.oid' }
    }
  end

  def data
    records.map do |child_object|
      {
        oid: link_to(child_object.oid, child_object_path(child_object)),
        label: child_object.label,
        caption: child_object.caption,
        width: child_object.width,
        height: child_object.height,
        order: child_object.order,
        parent_object: child_object.parent_object_oid,
        actions: actions(child_object).html_safe,
        DT_RowId: child_object.oid
      }
    end
  end

  def actions(child_object)
    actions = []
    actions << link_to('Edit', edit_child_object_path(child_object)) if @current_ability.can? :edit, child_object
    actions << link_to('Destroy', child_object_path(child_object), method: :delete, data: { confirm: 'Are you sure?' }) if @current_ability.can? :destroy, child_object
    actions.join(' | ')
  end

  def get_raw_records
    ChildObject.accessible_by(@current_ability, :read)
  end
end
