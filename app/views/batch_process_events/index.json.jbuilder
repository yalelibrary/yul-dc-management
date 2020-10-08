# frozen_string_literal: true

json.array! @batch_process_events, partial: "batch_process_events/batch_process_event", as: :batch_process_event
