require 'addressable/uri'

module Unwind
  class CanonicalLink
    def initialize(base_url, link)
      @base_url = base_url
      @link     = link
    end

    def resolve
      begin
        cleaned_link = @link.
          strip.
          gsub(/\p{C}/u, "").
          sub(/^(%[A-Fa-f0-9]{2})+/, "").
          strip
        uri = Addressable::URI.parse(cleaned_link)
        return if uri.nil?

        if uri.relative?
          build_from_relative(uri)
        else
          uri
        end
      rescue Addressable::URI::InvalidURIError, NoMethodError
        nil
      end
    end

    private

    def build_from_relative(uri)
      base_uri = Addressable::URI.parse(@base_url)

      if missing_scheme?(uri, base_uri.host)
        return Addressable::URI.parse("#{base_uri.scheme}:#{uri.to_s}")
      end

      if invalid_relative_uri?(uri, base_uri.host)
        path = uri.to_s.gsub(base_uri.host, '')
      else
        path = uri.to_s
      end

      Addressable::URI.join(base_uri, path)
    end

    def invalid_relative_uri?(uri, host)
      uri.to_s.match(host)
    end

    def missing_scheme?(uri, host)
      !uri.host.nil?
    end
  end
end
