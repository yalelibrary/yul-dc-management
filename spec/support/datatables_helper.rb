# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength
def datatable_sample_params
  ActionController::Parameters.new(
    'draw' => '1',
    'columns' => {
      '0' => {
        'data' => 'oid', 'name' => 'oid', 'searchable' => 'true', 'orderable' => 'true',
        'search' => {
          'value' => '', 'regex' => 'false'
        }
      },
      '1' => {
        'data' => 'authoritative_source', 'name' => '', 'searchable' => 'true', 'orderable' => 'true',
        'search' => {
          'value' => '', 'regex' => 'false'
        }
      },
      '2' => {
        'data' => 'bib', 'name' => '', 'searchable' => 'true', 'orderable' => 'false',
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

def datatable_view_mock # rubocop:disable Metrics/AbcSize
  @datatable_view_mock ||= double
  allow(@datatable_view_mock).to receive(:parent_object_path).and_return("/parent_objects/1")
  allow(@datatable_view_mock).to receive(:edit_parent_object_path).and_return("/parent_objects/1/edit")
  allow(@datatable_view_mock).to receive(:update_metadata_parent_object_path).and_return("/parent_objects/1/update_metadata")
  allow(@datatable_view_mock).to receive(:link_to).with(anything, "/parent_objects/1")
                                                  .and_return("<a href='/parent_objects/1'>1</a>")
  allow(@datatable_view_mock).to receive(:link_to).with("Edit", "/parent_objects/1/edit")
                                                  .and_return('<a href="/management/parent_objects/2034601/edit">Edit</a>')
  allow(@datatable_view_mock).to receive(:link_to).with("Update Metadata", "/parent_objects/1/update_metadata", anything)
                                                  .and_return('<a data-method="post" href="/management/parent_objects/2034601/update_metadata">Update Metadata</a>')
  allow(@datatable_view_mock).to receive(:link_to).with("Destroy", "/parent_objects/1", anything)
                                                  .and_return('<a data-confirm="Are you sure?" rel="nofollow" data-method="delete" href="/management/parent_objects/2034601">Destroy</a>')
  @datatable_view_mock
end
