# frozen_string_literal: true

json.extract! mets_xml_import, :id, :mets_xml_import, :created_at, :updated_at
json.url mets_xml_import_url(mets_xml_import, format: :json)
