# frozen_string_literal: true

class InformationObject
  include PreservicaObject

  def self.where(options)
    preservica_client = options[:preservica_client] || PreservicaClient.new(options[:admin_set_key])
    InformationObject.new(preservica_client, options[:id])
  end

  def initialize(preservica_client, id)
    @preservica_client = preservica_client
    @id = id
  end

  def representations
    @representations ||= load_representations
  end

  private

    def load_representations
      xml = Nokogiri::XML(@preservica_client.information_object_representations(@id)).remove_namespaces!
      xml.xpath('//Representation/@name').map(&:text).map do |name|
        Representation.new(@preservica_client, @id, name)
      end
    end
end
