# frozen_string_literal: true

class Preservica::InformationObject
  include Preservica::PreservicaObject

  def self.where(options)
    preservica_client = options[:preservica_client] || PreservicaClient.new(admin_set_key: options[:admin_set_key])
    Preservica::InformationObject.new(preservica_client, options[:id])
  end

  def initialize(preservica_client, id)
    @preservica_client = preservica_client
    @id = id
  end

  def representations
    @representations ||= load_representations
  end

  def access_representations
    @access_representations ||= load_access_reps
  end

  def preservation_representations
    @preservation_representations ||= load_preservation_reps
  end

  def fetch_by_representation_name(preservica_representation_name)
    @representation ||= load_representation(preservica_representation_name)
  end

  private

    def load_representation(preservica_representation_name)
      xml = Nokogiri::XML(@preservica_client.information_object_representations(@id)).remove_namespaces!
      xml.xpath('//Representation/@name').map(&:text).select { |name| name.include?(preservica_representation_name) }.map do |name|
        Preservica::Representation.new(@preservica_client, @id, name)
      end
    end

    def load_representations
      xml = Nokogiri::XML(@preservica_client.information_object_representations(@id)).remove_namespaces!
      xml.xpath('//Representation/@name').map(&:text).map do |name|
        Preservica::Representation.new(@preservica_client, @id, name)
      end
    end

    def load_access_reps
      xml = Nokogiri::XML(@preservica_client.information_object_representations(@id)).remove_namespaces!
      xml.xpath('//Representation/@name').map(&:text).select { |name| name.include?("Access") }.map do |name|
        Preservica::Representation.new(@preservica_client, @id, name)
      end
    end

    def load_preservation_reps
      xml = Nokogiri::XML(@preservica_client.information_object_representations(@id)).remove_namespaces!
      xml.xpath('//Representation/@name').map(&:text).select { |name| name.include?("Preservation") }.map do |name|
        Preservica::Representation.new(@preservica_client, @id, name)
      end
    end
end
