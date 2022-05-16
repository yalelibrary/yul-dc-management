# frozen_string_literal: true

class Preservica::StructuralObject
  include Preservica::PreservicaObject

  def self.where(options)
    preservica_client = options[:preservica_client] || PreservicaClient.new(admin_set_key: options[:admin_set_key])
    Preservica::StructuralObject.new(preservica_client, options[:id])
  end

  def initialize(preservica_client, id)
    @preservica_client = preservica_client
    @id = id
  end

  def information_objects
    @information_objects ||= load_information_objects
  end

  def xml
    @xml ||= @preservica_client.structural_object(@id)
  end

  private

    def load_information_objects
      children = []
      structural_object_children = Nokogiri::XML(@preservica_client.structural_object_children(id)).remove_namespaces!
      total_results = structural_object_children.at("Paging")&.at("TotalResults")&.text.to_i
      loop do
        structural_object_children.xpath('/ChildrenResponse/Children/Child').each do |child_ref|
          information_object_id = child_ref.xpath('@ref').text
          children << Preservica::InformationObject.new(@preservica_client, information_object_id)
        end
        break if children.count >= total_results || !structural_object_children.xpath('/ChildrenResponse/Children/Child').count.positive?
        structural_object_children = Nokogiri::XML(@preservica_client.structural_object_children(id, children.count)).remove_namespaces!
      end
      children
    end
end
