# frozen_string_literal: true

class Preservica::Representation
  include Preservica::PreservicaObject

  attr_accessor :name

  def self.where(options)
    preservica_client = options[:preservica_client] || PreservicaClient.new(admin_set_key: options[:admin_set_key])
    information_object_id = options[:information_object_id]
    name = options[:name]
    Preservica::Representation.new(preservica_client, information_object_id, name)
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

  def content_object_uri
    xml.xpath('/RepresentationResponse/ContentObjects/ContentObject').text.strip
  end

  def xml
    @xml ||= Nokogiri::XML(@preservica_client.information_object_representation(@id, @name)).remove_namespaces!
  end

  private

    def load_content_objects
      xml.xpath('/RepresentationResponse/ContentObjects/ContentObject').map do |content_object_node|
        content_object_id = content_object_node.xpath('@ref').text
        Preservica::ContentObject.new(@preservica_client, content_object_id)
      end
    end
end
