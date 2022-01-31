# frozen_string_literal: true

class ChildObjectDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegators :@view, :link_to, :child_object_path, :edit_child_object_path, :content_tag

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
      original_oid: { source: 'ChildObject.original_oid' },
      preservica_content_object_uri: { source: 'ChildObject.preservica_content_object_uri' },
      preservica_generation_uri: { source: 'ChildObject.preservica_generation_uri' },
      preservica_bitstream_uri: { source: 'ChildObject.preservica_bitstream_uri' },
      actions: { source: 'ChildObject.oid' }
    }
  end

  # rubocop:disable Rails/OutputSafety
  def data
    records.map do |child_object|
      {
        oid: link_to(child_object.oid, child_object_path(child_object)) + (with_icon('fa fa-pencil-alt', edit_child_object_path(child_object)) if @current_ability.can? :edit, child_object),
        label: child_object.label,
        caption: child_object.caption,
        width: child_object.width,
        height: child_object.height,
        order: child_object.order,
        parent_object: child_object.parent_object_oid,
        original_oid: child_object.original_oid,
        preservica_content_object_uri: child_object.preservica_content_object_uri,
        preservica_generation_uri: child_object.preservica_generation_uri,
        preservica_bitstream_uri: child_object.preservica_bitstream_uri,
        actions: actions(child_object).html_safe,
        DT_RowId: child_object.oid
      }
    end
  end
  # rubocop:enable Rails/OutputSafety

  def actions(child_object)
    actions = []
    actions << with_icon('fa fa-trash', child_object_path(child_object), method: :delete, data: { confirm: 'Are you sure?' }) if @current_ability.can? :destroy, child_object
    actions.join(' | ')
  end

  def with_icon(class_name, path, options = {})
    link_to(path, options) do
      content_tag(:i, '', class: class_name)
    end
  end

  # rubocop:disable Naming/AccessorMethodName
  def get_raw_records
    ChildObject.accessible_by(@current_ability, :read)
  end
end
