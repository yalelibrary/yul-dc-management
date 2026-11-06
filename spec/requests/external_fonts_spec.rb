# frozen_string_literal: true

require 'rails_helper'

# The system specs block static.library.yale.edu in Chrome (see spec/support/capybara.rb) so a slow
# font host can't time out unrelated specs. This spec is the one place that checks the fonts are
# still served, so a moved or removed font fails here by name.
RSpec.describe "External fonts" do
  font_host = "static.library.yale.edu"
  stylesheet = Rails.root.join("app", "assets", "stylesheets", "theme", "typography.scss")
  all_font_urls = File.read(stylesheet)
                      .scan(%r{url\((https://#{Regexp.escape(font_host)}/[^)?#]+)})
                      .flatten
                      .uniq
  # Only check the format Chrome actually downloads: woff2 when the font offers it, otherwise woff.
  # The eot/ttf/svg fallbacks are for older browsers and never requested.
  font_urls = all_font_urls.group_by { |url| url.sub(/\.\w+\z/, "") }.filter_map do |_font, urls|
    urls.find { |url| url.end_with?(".woff2") } || urls.find { |url| url.end_with?(".woff") }
  end

  before do
    WebMock.disable_net_connect!(allow: ["solr", "localhost", font_host])
  end

  after do
    WebMock.disable_net_connect!(allow: ["solr", "localhost"])
  end

  it "finds the font URLs in the stylesheet" do
    expect(font_urls).not_to be_empty
  end

  font_urls.each do |font_url|
    it "serves #{font_url}" do
      uri = URI(font_url)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 30, read_timeout: 30) do |http|
        http.request(Net::HTTP::Get.new(uri))
      end
      expect(response.code).to eq("200"), "expected 200 for #{font_url}, got #{response.code}"
    end
  end
end
