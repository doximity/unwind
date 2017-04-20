require_relative 'unwind/version'
require_relative 'unwind/canonical_link'
require 'addressable/uri'
require 'nokogiri'
require 'faraday'
require 'faraday-cookie_jar'

module Unwind

  class TooManyRedirects < StandardError; end
  class MissingRedirectLocation < StandardError; end
  class TimeoutError < StandardError; end

  class RedirectFollower

    attr_reader :final_url,  :original_url, :redirect_limit, :response, :redirects

    def initialize(original_url, limit=5)
     @original_url, @redirect_limit = original_url, limit
     @redirects = []
    end

    def redirected?
      !(self.final_url == self.original_url)
    end

    def not_found?
      @response.status == 404
    end

    def resolve(current_url=nil, options={}, &block)
      ok_to_continue?

      current_url ||= self.original_url

      #adding this header because we really only care about resolving the url
      headers = (options || {}).merge({"accept-encoding" => "none"})

      current_url = current_url.to_s.gsub(' ', '%20')

      begin
        response = conn.get(current_url, nil, headers)
        yield response if block_given?
      rescue Faraday::Error::TimeoutError => e
        raise Unwind::TimeoutError, $!
      end

      if is_response_redirect?(response)
        resolve(*handle_redirect(redirect_url(response), current_url, response, headers), &block)
      elsif meta_uri = meta_refresh?(response)
        resolve(*handle_redirect(meta_uri, current_url, response, headers), &block)
      else
        handle_final_response(current_url, response)
      end

      self
    end

    def self.resolve(original_url, limit=5, &block)
      new(original_url, limit).resolve(&block)
    end

  private

    def conn
      @conn ||= Faraday.new do |builder|
        builder.use :cookie_jar
        builder.adapter Faraday.default_adapter
      end
    end

    def record_redirect(url)
      @redirects << url.to_s
      @redirect_limit -= 1
    end

    def is_response_redirect?(response)
      [301, 302, 303].include?(response.status)
    end

    def handle_redirect(uri_to_redirect, url, response, headers)
      record_redirect url
      return uri_to_redirect.normalize, headers
    end

    def handle_final_response(current_url, response)
      current_url = current_url.dup.to_s
      if response.status == 200 && (canonical = canonical_link(response))
        @redirects << current_url
        @final_url = canonical.to_s
      else
        @final_url = current_url
      end
      @response = response
    end

    def ok_to_continue?
      raise TooManyRedirects if redirect_limit < 0
    end

    def redirect_url(response)
      if response['location'].nil?
        body_match = response.body.match(/<a href=\"([^>]+)\">/i)
        raise MissingRedirectLocation unless body_match
        Addressable::URI.parse(body_match[0])
      else
        redirect_uri = Addressable::URI.parse(response['location'])
        redirect_uri.relative? ? Addressable::URI.join(response.env[:url].to_s, response['location']) : redirect_uri
      end
    end

    def meta_refresh?(response)
      if response.status == 200
        body_match = response.body.match(/<meta http-equiv=\"refresh\" content=\"0;\s*url='?(.*[^'$])'?\">/i)
        Unwind::CanonicalLink.new(response.env[:url].to_s, body_match[1]).resolve if body_match
      end
    end

    def canonical_link(response)
      doc = Nokogiri::HTML(response.body)

      if (raw_canonical = doc.at('link[rel=canonical]'))
        Unwind::CanonicalLink.new(response.env[:url].to_s, raw_canonical["href"]).resolve
      else
        nil
      end
    end
  end
end
