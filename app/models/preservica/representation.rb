# frozen_string_literal: true

class Preservica::Representation
  include Preservica::PreservicaObject

  attr_accessor :type

  def self.where(options)
    preservica_client = options[:preservica_client] || PreservicaClient.new(admin_set_key: options[:admin_set_key])
    information_object_id = options[:information_object_id]
    type = options[:type]
    Preservica::Representation.new(preservica_client, information_object_id, type)
  end

  def initialize(preservica_client, information_object_id, type)
    @preservica_client = preservica_client
    @id = information_object_id
    @type = type
  end

  def content_objects
    @content_objects ||= load_content_objects
  end

  def content_object_uri(index)
    xml.xpath('/RepresentationResponse/ContentObjects/ContentObject')[index].text.strip
  end

  def xml
    @xml ||= Nokogiri::XML(@preservica_client.information_object_representation(@id, @type)).remove_namespaces!
  end

  private

    def load_content_objects
      xml.xpath('/RepresentationResponse/ContentObjects/ContentObject').map do |content_object_node|
        content_object_id = content_object_node.xpath('@ref').text
        Preservica::ContentObject.new(@preservica_client, content_object_id)
      end
    end
end
