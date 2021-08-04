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

def parent_object_datatable_view_mock # rubocop:disable Metrics/AbcSize
  @datatable_view_mock ||= double
  allow(@datatable_view_mock).to receive(:parent_object_path).and_return('/parent_objects/2034600')
  allow(@datatable_view_mock).to receive(:edit_parent_object_path).and_return('/parent_objects/2034600/edit')
  # rubocop:disable RSpec/AnyInstance
  allow_any_instance_of(ParentObject).to receive(:child_object_count).and_return(4)
  # rubocop:enable RSpec/AnyInstance
  allow(@datatable_view_mock).to receive(:link_to).with(anything, '/parent_objects/2034600')
                                                  .and_return('<a href="/parent_objects/2034600">2034600</a>')
  allow(@datatable_view_mock).to receive(:link_to).with('/parent_objects/2034600/edit', {})
                                                  .and_return('<a href="/management/parent_objects/2034600/edit"><i class="fa fa-pencil-alt"></i></a>')
  allow(@datatable_view_mock).to receive(:link_to).with('http://localhost:3000/catalog/2034600', target: :_blank)
                                                  .and_return('<a target="_blank" href="http://localhost:3000/catalog/2034600">1</a>')
  @datatable_view_mock
end

def child_object_datatable_view_mock # rubocop:disable Metrics/AbcSize
  @datatable_view_mock ||= double
  allow(@datatable_view_mock).to receive(:child_object_path).and_return('/child_objects/1')
  allow(@datatable_view_mock).to receive(:edit_child_object_path).and_return('/child_objects/1/edit')
  allow(@datatable_view_mock).to receive(:link_to).with('/child_objects/1/edit', {})
  .and_return('<a href="/management/child_objects/10736292/edit"><i class="fa fa-pencil-alt"></i></a>')
  allow(@datatable_view_mock).to receive(:link_to).with('/child_objects/1', method: :delete, data: { confirm: 'Are you sure?' })
  .and_return('<a data-confirm="Are you sure?" rel="nofollow" data-method="delete" href="/management/child_objects/10736292"><i class="fa fa-trash"></i></a>')
  allow(@datatable_view_mock).to receive(:link_to).with(anything, '/child_objects/1')
                                                  .and_return('<a href="/child_objects/1">1</a>')
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
  allow(@datatable_view_mock).to receive(:link_to).with("/management/users/#{id}/edit", {}).and_return("<a href='/management/users/#{id}/edit'><i class=\"fa fa-pencil-alt\"></i></a>")
  @datatable_view_mock
end

def admin_set_datatable_view_mock(id, key, homepage) # rubocop:disable Metrics/AbcSize
  @datatable_view_mock ||= double
  allow(@datatable_view_mock).to receive(:admin_set_path).and_return("/admin_sets/#{id}")
  allow(@datatable_view_mock).to receive(:edit_admin_set_path).and_return("/admin_sets/#{id}/edit")
  allow(@datatable_view_mock).to receive(:link_to).with(anything, "/admin_sets/#{id}").and_return("<a href='/admin_sets/#{id}'>#{key}</a>")
  allow(@datatable_view_mock).to receive(:link_to).with(homepage.to_s, homepage.to_s).and_return("<a href=#{homepage}>#{homepage}</a>")
  allow(@datatable_view_mock).to receive(:link_to).with("/admin_sets/#{id}/edit", {}).and_return("<a href='/admin_sets/#{id}/edit'><i class=\"fa fa-pencil-alt></i>\"</a>")
  @datatable_view_mock
end
