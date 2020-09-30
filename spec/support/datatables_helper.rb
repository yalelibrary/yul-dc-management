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

def datatable_view_mock
  @datatable_view_mock ||= double
  allow(@datatable_view_mock).to receive(:parent_object_path).and_return("/parent_objects/1")
  allow(@datatable_view_mock).to receive(:link_to).and_return("<a href='/parent_objects/1'>1</a>")
  @datatable_view_mock
end
