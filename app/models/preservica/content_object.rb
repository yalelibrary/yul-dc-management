# frozen_string_literal: true

class ContentObject
  include PreservicaObject

  def self.where(options)
    preservica_client = options[:preservica_client] || PreservicaClient.new(admin_set_key: options[:admin_set_key])
    ContentObject.new(preservica_client, options[:id])
  end

  def initialize(preservica_client, id)
    @preservica_client = preservica_client
    @id = id
  end

  def active_generations
    @generations ||= load_generations
  end

  private

    def load_generations
      xml = Nokogiri::XML(@preservica_client.content_object_generations(@id)).remove_namespaces!
      xml.xpath("//Generations/Generation[@active='true']").map do |generation_node|
        generation_id = generation_node.text.split('/').last
        Generation.new(@preservica_client, @id, generation_id.strip)
      end
    end
end
