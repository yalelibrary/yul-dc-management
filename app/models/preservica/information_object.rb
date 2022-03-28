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
    @representation_hash = {}
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

  # returns all representations with a name containing preservica_representation_name
  def fetch_by_representation_name(preservica_representation_name)
    @representation_hash[preservica_representation_name] ||= load_representation(preservica_representation_name)
  end

  def xml
    @xml ||= @preservica_client.information_object(@id)
  end

  private

    def load_representation(preservica_representation_name)
      load_representations.select { |representation| representation.name.include?(preservica_representation_name) }
    end

    def load_representations
      xml = Nokogiri::XML(@preservica_client.information_object_representations(@id)).remove_namespaces!
      xml.xpath('//Representation/@name').map(&:text).map do |name|
        Preservica::Representation.new(@preservica_client, @id, name)
      end
    end

    def load_access_reps
      load_representation("Access")
    end

    def load_preservation_reps
      load_representation("Preservation")
    end
end
