# frozen_string_literal: true

class Preservica::ContentObject
  include Preservica::PreservicaObject

  def self.where(options)
    preservica_client = options[:preservica_client] || PreservicaClient.new(admin_set_key: options[:admin_set_key])
    Preservica::ContentObject.new(preservica_client, options[:id])
  end

  def initialize(preservica_client, id)
    @preservica_client = preservica_client
    @id = id
  end

  def active_generations
    @generations ||= load_generations
  end

  def content_object_uri
    content_uri = xml.xpath('/GenerationsResponse/AdditionalInformation/Self').text.strip
    content_uri.chomp('/generations')
  end
  
  def xml
    @xml ||= @preservica_client.content_object(@id)
  end

  private

    def load_generations
      xml.xpath("//Generations/Generation[@active='true']").map do |generation_node|
        generation_id = generation_node.text.split('/').last
        Preservica::Generation.new(@preservica_client, @id, generation_id.strip)
      end
    end

    def xml
      @xml ||= Nokogiri::XML(@preservica_client.content_object_generations(@id)).remove_namespaces!
    end
end
