# frozen_string_literal: true

class MetsRecord < MetsDocument
  # Source is a string containing xml
  def initialize(oid, source)
    @oid = oid
    @source = source
    @mets = Nokogiri::XML(source)
  end

  attr_reader :oid, :source

  # # local metadata
  # ATTRIBUTES = %w[
  #   identifier
  #   viewing_direction
  #   pagination
  # ].freeze
  #
  # def attributes
  #   ATTRIBUTES.map { |att| [att, send(att)] }.to_h.compact
  # end
  #
  # def identifier
  #   oid
  # end
  #
  # # ingest metadata
  #
  # def files
  #   add_file_attributes super
  # end
  #

  # private

  # def add_file_attributes(file_hash_array)
  #   file_hash_array.each do |f|
  #     f[:file_opts] = file_opts(f)
  #     f[:attributes] ||= {}
  #     f[:attributes][:title] = [file_label(f[:id])]
  #   end
  #   file_hash_array
  # end
end
