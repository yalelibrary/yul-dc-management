# frozen_string_literal: true
#
# Client for archive space tied to an admin set
#
# Uses environment variables: PRESERVICA_HOST and PRESERVICA_CREDENTIALS
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
    return unless ENV["VPN"] == "true"
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
