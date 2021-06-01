# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength
def datatable_sample_params(columns)
  ActionController::Parameters.new(
    'draw' => '1',
    'columns' => {
      '0' => {
        'data' => columns[0], 'name' => columns[0], 'searchable' => 'true', 'orderable' => 'true',
        'search' => {
          'value' => '', 'regex' => 'false'
        }
      },
      '1' => {
        'data' => columns[1], 'name' => '', 'searchable' => 'true', 'orderable' => 'true',
        'search' => {
          'value' => '', 'regex' => 'false'
        }
      },
      '2' => {
        'data' => columns[2], 'name' => '', 'searchable' => 'true', 'orderable' => 'false',
        'search' => {
          'value' => '', 'regex' => 'false'
        }
      }
    },
    'order' => {
      '0' => { 'column' => '0', 'dir' => 'asc' }
    },
    'start' => '0', 'length' => '10', 'search' => {
      'value' => '', 'regex' => 'false'
    },
    '_' => '1423364387185'
  )
end

def batch_parent_datatable_sample_params(columns, oid)
  ActionController::Parameters.new(
    'oid' => oid,
    'draw' => '1',
    'columns' => {
      '0' => {
        'data' => columns[0], 'name' => columns[0], 'searchable' => 'true', 'orderable' => 'true',
        'search' => {
          'value' => '', 'regex' => 'false'
        }
      },
      '1' => {
        'data' => columns[1], 'name' => '', 'searchable' => 'true', 'orderable' => 'true',
        'search' => {
          'value' => '', 'regex' => 'false'
        }
      },
      '2' => {
        'data' => columns[2], 'name' => '', 'searchable' => 'true', 'orderable' => 'false',
        'search' => {
          'value' => '', 'regex' => 'false'
        }
      }
    },
    'order' => {
      '0' => { 'column' => '0', 'dir' => 'asc' }
    },
    'start' => '0', 'length' => '10', 'search' => {
      'value' => '', 'regex' => 'false'
    },
    '_' => '1423364387185'
  )
end
# rubocop:enable Metrics/MethodLength

def parent_object_datatable_view_mock # rubocop:disable Metrics/AbcSize
  @datatable_view_mock ||= double
  allow(@datatable_view_mock).to receive(:parent_object_path).and_return("/parent_objects/1")
  allow(@datatable_view_mock).to receive(:edit_parent_object_path).and_return("/parent_objects/1/edit")
  # rubocop:disable RSpec/AnyInstance
  allow_any_instance_of(ParentObject).to receive(:child_object_count).and_return(4)
  # rubocop:enable RSpec/AnyInstance
  allow(@datatable_view_mock).to receive(:update_metadata_parent_object_path).and_return("/parent_objects/1/update_metadata")
  allow(@datatable_view_mock).to receive(:link_to).with(anything, "/parent_objects/1")
                                                  .and_return("<a href='/parent_objects/1'>1</a>")
  allow(@datatable_view_mock).to receive(:link_to).with("Edit", "/parent_objects/1/edit")
                                                  .and_return('<a href="/management/parent_objects/2034601/edit">Edit</a>')
  allow(@datatable_view_mock).to receive(:link_to).with("View", "/parent_objects/1", method: :get)
                                                  .and_return('<a href="/management/parent_objects/2034601">View</a>')
  allow(@datatable_view_mock).to receive(:link_to).with("Update Metadata", "/parent_objects/1/update_metadata", anything)
                                                  .and_return('<a data-method="post" href="/management/parent_objects/2034601/update_metadata">Update Metadata</a>')
  allow(@datatable_view_mock).to receive(:link_to).with("Destroy", "/parent_objects/1", anything)
                                                  .and_return('<a data-confirm="Are you sure?" rel="nofollow" data-method="delete" href="/management/parent_objects/2034601">Destroy</a>')
  @datatable_view_mock
end

def child_object_datatable_view_mock # rubocop:disable Metrics/AbcSize
  @datatable_view_mock ||= double
  allow(@datatable_view_mock).to receive(:child_object_path).and_return('/child_objects/1')
  allow(@datatable_view_mock).to receive(:edit_child_object_path).and_return('/child_objects/1/edit')
  allow(@datatable_view_mock).to receive(:link_to).with(anything, '/child_objects/1')
                                                  .and_return('<a href="/child_objects/1">1</a>')
  allow(@datatable_view_mock).to receive(:link_to).with('Edit', '/child_objects/1/edit')
                                                  .and_return('<a href="/management/child_objects/10736292/edit">Edit</a>')
  allow(@datatable_view_mock).to receive(:link_to).with('Destroy', '/child_objects/1', anything)
  .and_return('<a data-confirm="Are you sure?" rel="nofollow" data-method="delete" href="/management/child_objects/10736292">Destroy</a>')
  @datatable_view_mock
end

def batch_process_datatable_view_mock(id) # rubocop:disable Metrics/AbcSize
  @datatable_view_mock ||= double
  allow(@datatable_view_mock).to receive(:batch_process_path).and_return("/batch_processes/#{id}")
  allow(@datatable_view_mock).to receive(:link_to).with(anything, "/batch_processes/#{id}")
                                                  .and_return("<a href='/batch_processes/#{id}'>#{id}</a>")
  allow(@datatable_view_mock).to receive(:link_to).with('View', "/batch_processes/#{id}")
                                                  .and_return("<a href='/batch_processes/#{id}'>View</a>")
  @datatable_view_mock
end

def batch_process_parent_datatable_view_mock(id, parent_oid, child_oid) # rubocop:disable Metrics/AbcSize
  @datatable_view_mock ||= double
  allow(@datatable_view_mock).to receive(:show_parent_batch_process_path).and_return("/batch_processes/#{id}/parent_objects/#{parent_oid}")
  allow(@datatable_view_mock).to receive(:show_child_batch_process_path).and_return("/batch_processes/#{id}/parent_objects/#{parent_oid}/child_objects/#{child_oid}")
  allow(@datatable_view_mock).to receive(:link_to).with(anything, "/batch_processes/#{id}/parent_objects/#{parent_oid}/child_objects/#{child_oid}")
                                                  .and_return("<a href='/batch_processes/#{id}/parent_objects/#{parent_oid}/child_objects/#{child_oid}'>#{child_oid}</a>")
  @datatable_view_mock
end

def user_datatable_view_mock(id, uid) # rubocop:disable Metrics/AbcSize
  @datatable_view_mock ||= double
  allow(@datatable_view_mock).to receive(:user_path).and_return("/management/users/#{id}")
  allow(@datatable_view_mock).to receive(:edit_user_path).and_return("/management/users/#{id}/edit")
  allow(@datatable_view_mock).to receive(:link_to).with(anything, "/management/users/#{id}").and_return("<a href='/management/users/#{id}'>#{uid}</a>")
  allow(@datatable_view_mock).to receive(:link_to).with("Edit", "/management/users/#{id}/edit").and_return("<a href='/management/users/#{id}/edit'>Edit</a>")
  @datatable_view_mock
end
