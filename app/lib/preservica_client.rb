# frozen_string_literal: true

require 'net/http'
require 'openssl'
require 'json'
require 'byebug'
require 'nokogiri'
require 'digest'

# Client for archive space.
#
# Uses environment variables: PRESERVICA_HOST and PRESERVICA_CREDENTIALS
# Usage:
#     p = PreservicaClient.new(admin_set_key: 'brbl')
#     p.structural_object_children_bitstreams("7fe35e8c-c21a-444a-a2e2-e3c926b519c4") do |content_id, data|
#        puts "#{content_id} #{data.length}"
#     end
#
# rubocop:disable Metrics/ClassLength
class PreservicaClient
  def initialize(args)
    @host = args[:base_url] || "https://#{ENV['PRESERVICA_HOST']}"
    if args[:admin_set_key]
      credentials = JSON.parse(ENV['PRESERVICA_CREDENTIALS'])[args[:admin_set_key]]
      @username = credentials['username']
      @password = credentials['password']
    else
      @username = args[:username]
      @password = args[:password]
    end
    login
  end

  def login
    uri = URI(@host)
    Net::HTTP.start(uri.host, uri.port,
                    use_ssl: uri.scheme == 'https',
                    verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
      request = Net::HTTP::Post.new '/api/accesstoken/login'
      request.set_form_data('username' => @username, 'password' => @password)
      response = http.request request # Net::HTTPResponse object
      raise StandardError, 'Unable to login' unless response.is_a? Net::HTTPSuccess

      @login_info = JSON.parse(response.body)
    end
  end

  def refresh
    authenticated_post URI("#{@host}/api/accesstoken/refresh") do |http, request|
      request.set_form_data('refreshToken' => @login_info['refresh-token'])
      @login_info = http.request request
    end
  end

  def content_structural_object_details(id)
    get "/api/content/object-details?id=sdb%3ASO%7C#{id}"
  end

  def structural_object(id)
    get "/api/entity/structural-objects/#{id}"
  end

  def structural_object_children(id)
    get "/api/entity/structural-objects/#{id}/children"
  end

  def information_object(id)
    get "/api/entity/information-objects/#{id}"
  end

  def information_object_representations(id)
    get "/api/entity/information-objects/#{id}/representations"
  end

  def information_object_representation(id, representation)
    get "/api/entity/information-objects/#{id}/representations/#{representation}"
  end

  def content_object(id)
    get "/api/entity/content-objects/#{id}"
  end

  def content_object_generations(id)
    get "/api/entity/content-objects/#{id}/generations"
  end

  def content_object_generation(id, generation)
    get "/api/entity/content-objects/#{id}/generations/#{generation}"
  end

  def content_object_generation_bitstream(id, generation, bitstream)
    get "/api/entity/content-objects/#{id}/generations/#{generation}/bitstreams/#{bitstream}"
  end

  def content_object_generation_bitstream_content(id, generation, bitstream)
    get "/api/entity/content-objects/#{id}/generations/#{generation}/bitstreams/#{bitstream}/content"
  end

  def structural_object_children_bitstreams(id)
    structural_object_children = Nokogiri::XML(structural_object_children(id)).remove_namespaces!
    structural_object_children.xpath('/ChildrenResponse/Children/Child').each do |child_ref|
      information_object_id = child_ref.xpath('@ref').text
      bitstream_information_array = information_object_active_bitstream_information(information_object_id)
      bitstream_information_array.each do |bitstream_info|
        data = content_object_generation_bitstream_content(bitstream_info[:content_object_id], bitstream_info[:generation_id], bitstream_info[:bitstream_id])
        raise "Invalid bitstream data" unless data.length == bitstream_info[:file_size]
        downloaded_sha = Digest::SHA512.hexdigest data
        raise "Digest does not match" unless downloaded_sha == bitstream_info[:sha512]
        yield bitstream_info[:content_object_id], data if block_given?
      end
    end
  end

  def information_object_active_bitstream_information(information_object_id)
    information = []
    xml = Nokogiri::XML(information_object_representations(information_object_id)).remove_namespaces!
    representation_names = xml.xpath('//Representation/@name').map(&:text)

    representation_names.each do |representation|
      xml = Nokogiri::XML(information_object_representation(information_object_id, representation)).remove_namespaces!
      xml.xpath('/RepresentationResponse/ContentObjects/ContentObject').each do |content_object_node|
        content_object_id = content_object_node.xpath('@ref').text
        information = bitstream_info_from_content_id(content_object_id, information_object_id)
      end
    end
    information
  end

  def bitstream_info_from_content_id(content_object_id, information_object_id)
    information = []
    content_object = Nokogiri::XML(content_object_generations(content_object_id)).remove_namespaces!
    active_generation_id = content_object.xpath("//Generations/Generation[@active='true']").text.split('/').last
    active_generation = Nokogiri::XML(content_object_generation('90080577-e535-46fb-9efa-ddb94a1a5758', active_generation_id)).remove_namespaces!
    bitstream_ids = active_generation.xpath('/GenerationResponse/Bitstreams/Bitstream').map(&:content).map { |x| x.split('/').last }
    bitstream_ids.each do |bitstream_id|
      bitstream = Nokogiri::XML(content_object_generation_bitstream(content_object_id, active_generation_id, bitstream_id)).remove_namespaces!
      sha512 = bitstream.xpath('//FixityValue/text()').text
      file_size = bitstream.xpath('//FileSize/text()').text.to_i
      information << { information_object_id: information_object_id,
                       content_object_id: content_object_id,
                       generation_id: active_generation_id,
                       bitstream_id: bitstream_id,
                       sha512: sha512,
                       file_size: file_size }
    end
    information
  end

  def get(uri)
    authenticated_get URI("#{@host}#{uri}") do |http, request|
      response = http.request request
      raise StandardError, "Request error #{response.code} #{response.body}" unless response.is_a? Net::HTTPSuccess

      return response.body
    end
  end

  def authenticated_post(uri)
    Net::HTTP.start(uri.host, uri.port,
                    use_ssl: uri.scheme == 'https',
                    verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|

      request = Net::HTTP::Post.new uri.request_uri
      request['Preservica-Access-Token'] = @login_info['token']
      yield http, request
    end
  end

  def authenticated_get(uri)
    Net::HTTP.start(uri.host, uri.port,
                    use_ssl: uri.scheme == 'https',
                    verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
      request = Net::HTTP::Get.new uri.request_uri
      request['Preservica-Access-Token'] = @login_info['token']
      yield http, request
    end
  end
end
# rubocop:enable Metrics/ClassLength
