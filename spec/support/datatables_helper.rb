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
