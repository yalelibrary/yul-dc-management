class TimeStampDefaultPreservicaIngest < ActiveRecord::Migration[6.0]
  def change
    change_column_default(:preservica_ingests, :created_at, from: nil, to: -> { 'CURRENT_TIMESTAMP' })
    change_column_default(:preservica_ingests, :updated_at, from: nil, to: -> { 'CURRENT_TIMESTAMP' })
  end
end
