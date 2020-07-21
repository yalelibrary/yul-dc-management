# frozen_string_literal: true

json.extract! goobi_xml_import, :id, :goobi_xml_import, :created_at, :updated_at
json.url goobi_xml_import_url(goobi_xml_import, format: :json)
