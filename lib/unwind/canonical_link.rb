class Unwind::CanonicalLink
  def initialize(base_url, link)
    @base_url = base_url
    @link     = link
  end

  def resolve
    uri = Addressable::URI.parse(@link)
    return if uri.nil?

    if uri.relative?
      build_from_relative(uri)
    else
      uri
    end
  end

  private

  def build_from_relative(uri)
    base_uri = Addressable::URI.parse(@base_url)

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
end
