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
    @access_representations ||= load_representation("Access")
  end

  def preservation_representations
    @preservation_representations ||= load_representation("Preservation")
  end

  # returns all representations with a name containing preservica_representation_type
  def fetch_by_representation_type(preservica_representation_type)
    @representation_hash[preservica_representation_type] ||= load_representation(preservica_representation_type)
  end

  def xml
    @xml ||= @preservica_client.information_object(@id)
  end

  private

    def load_representation(preservica_representation_type)
      representations.select { |representation| representation.type.include?(preservica_representation_type) }
    end

    def load_representations
      xml = Nokogiri::XML(@preservica_client.information_object_representations(@id)).remove_namespaces!
      xml.xpath('//Representation/@name').map(&:text).map do |name|
        Preservica::Representation.new(@preservica_client, @id, name)
      end
    end
end
