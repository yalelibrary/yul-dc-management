# frozen_string_literal: true

class Representation
  include PreservicaObject

  def self.where(options)
    preservica_client = options[:preservica_client] || PreservicaClient.new(options[:admin_set_key])
    information_object_id = options[:information_object_id]
    name = options[:name]
    Representation.new(preservica_client, information_object_id, name)
  end

  def initialize(preservica_client, information_object_id, name)
    @preservica_client = preservica_client
    @id = information_object_id
    @name = name
  end

  def content_objects
    @content_objects ||= load_content_objects
  end

  def type
    xml.xpath('/RepresentationResponse/Representation/Type').text.strip
  end

  private

    def load_content_objects
      xml.xpath('/RepresentationResponse/ContentObjects/ContentObject').map do |content_object_node|
        content_object_id = content_object_node.xpath('@ref').text
        ContentObject.new(@preservica_client, content_object_id)
      end
    end

    def xml
      @xml ||= Nokogiri::XML(@preservica_client.information_object_representation(@id, @name)).remove_namespaces!
    end
end
