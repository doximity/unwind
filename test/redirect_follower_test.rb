require 'minitest/autorun'
require 'webmock'
require 'webmock/minitest'
require 'vcr'
require './lib/unwind'

VCR.configure do |c|
  c.hook_into :webmock
  c.cassette_library_dir = 'vcr_cassettes'
  c.allow_http_connections_when_no_cassette = true
end

describe Unwind::RedirectFollower do

  # needs to be regenerated to properly test...need to stop that :(
  it 'should handle url with cookie requirement' do
    VCR.use_cassette('with cookie') do
      follower = Unwind::RedirectFollower.resolve('http://ow.ly/1hf37P')
      assert_equal 200,  follower.response.status
      assert follower.redirected?
    end
  end

  it 'should resolve the url' do
    VCR.use_cassette('xZVND1') do
      follower = Unwind::RedirectFollower.resolve('http://j.mp/xZVND1')
      assert_equal 'http://ow.ly/i/s1O0', follower.final_url
      assert_equal 'http://j.mp/xZVND1', follower.original_url
      assert_equal 2, follower.redirects.count
      assert follower.redirected?
    end
  end

  it 'should handle relative redirects' do
    VCR.use_cassette('relative stackoverflow') do
      follower = Unwind::RedirectFollower.resolve('http://stackoverflow.com/q/9277007/871617?stw=1')
      assert follower.redirected?
      assert_equal 'http://stackoverflow.com/questions/9277007/gitlabhq-w-denied-for-rails', follower.final_url
    end
  end

  it 'should still handine relative redirects' do
    # http://bit.ly/A4H3a2
    VCR.use_cassette('relative stackoverflow 2') do
      follower = Unwind::RedirectFollower.resolve('http://bit.ly/A4H3a2')
      assert follower.redirected?
    end
  end

  it 'should handle redirects to pdfs' do
    VCR.use_cassette('pdf') do
      follower = Unwind::RedirectFollower.resolve('http://binged.it/wVSFs5')
      assert follower.redirected?
      assert_equal 'https://microsoft.promo.eprize.com/bingtwitter/public/fulfillment/rules.pdf', follower.final_url
    end
  end

  it 'should handle the lame amazon spaces' do
    VCR.use_cassette('amazon') do
      follower = Unwind::RedirectFollower.resolve('http://amzn.to/xrHQWS')
      assert follower.redirected?
    end
  end

  #http://amzn.to/xrHQWS

  it 'should handle a https redirect' do
    VCR.use_cassette('ssl tpope') do
      follower = Unwind::RedirectFollower.resolve('http://github.com/tpope/vim-rails')
      assert follower.redirected?
      assert_equal 'https://github.com/tpope/vim-rails', follower.final_url
    end
  end

  it 'should not be redirected' do
    VCR.use_cassette('no redirect') do
      follower  = Unwind::RedirectFollower.resolve('http://www.scottw.com')
      assert !follower.redirected?
    end
  end

  it 'should set the final url as being the canonical url and treat it as s redirect' do
    VCR.use_cassette('canonical url', :preserve_exact_body_bytes => true) do
      follower  = Unwind::RedirectFollower.resolve('http://www.scottw.com?test=abc')
      assert  follower.redirected?
      assert_equal 'http://www.scottw.com', follower.final_url
      assert_equal 'http://www.scottw.com?test=abc', follower.redirects[0]
    end
  end

  it 'should handle relative canonical urls' do
    stub_request(:get, 'http://foo.com/').to_return(status: 200, body: """
      <body><link rel='canonical' href='/index.html'></body>
    """)

    follower = Unwind::RedirectFollower.resolve('http://foo.com/')

    assert follower.final_url, "http://foo.com/index.html"
  end

  it 'should handle surrounding whitespace in canonical url' do
    stub_request(:get, 'http://foo.com/').to_return(status: 200, body: """
      <body><link rel='canonical' href=' https://foo.com/home '></body>
    """)

    follower  = Unwind::RedirectFollower.resolve('http://foo.com/')

    assert_equal 'https://foo.com/home', follower.final_url
  end

  it 'should raise TooManyRedirects' do
    VCR.use_cassette('xZVND1') do
      follower = Unwind::RedirectFollower.new('http://j.mp/xZVND1', 1)
      too_many_redirects = lambda {follower.resolve}
      too_many_redirects.must_raise Unwind::TooManyRedirects
    end
  end

  it 'should raise MissingRedirectLocation' do
    VCR.use_cassette('missing redirect') do
      follower = Unwind::RedirectFollower.new('http://tinyurl.com/6oqzkff')
      missing_redirect_location = lambda{follower.resolve}
      missing_redirect_location.must_raise Unwind::MissingRedirectLocation
    end
  end

  it 'should handle a meta-refresh' do
    VCR.use_cassette('meta refresh') do
      follower = Unwind::RedirectFollower.resolve('http://www.nullrefer.com/?www.google.com')
      assert follower.redirected?
      assert_equal 'http://www.google.com/', follower.final_url
    end
  end

  it 'should handle a meta-refresh without spacing between time and url' do
    body = "<meta http-equiv=\"refresh\" content=\"0;url=http://www.example.com/\">"
    stub_request(:get, 'http://foo.com').to_return(status: 200, body: body)
    follower = Unwind::RedirectFollower.resolve('http://foo.com')
    assert follower.redirected?
    assert_equal "http://www.example.com/", follower.final_url
  end

  it 'should handle a meta-refresh with url wrapped in single quotes' do
    body = "<meta http-equiv=\"refresh\" content=\"0;url='http://www.example.com/'\">"
    stub_request(:get, 'http://foo.com').to_return(status: 200, body: body)
    follower = Unwind::RedirectFollower.resolve('http://foo.com')
    assert follower.redirected?
    assert_equal "http://www.example.com/", follower.final_url
  end

  it 'should handle a meta-refresh with relative url' do
    body = '<meta http-equiv="refresh" content="0; url=/relative">'
    stub_request(:get, 'http://foo.com').to_return(status: 200, body: body)
    stub_request(:get, 'http://foo.com/relative').to_return(status: 200, body: 'ok')

    follower = Unwind::RedirectFollower.resolve('http://foo.com')
    assert follower.redirected?
    assert_equal "http://foo.com/relative", follower.final_url
  end

  it 'should handle URLs with spaces' do
    body = '<meta http-equiv="refresh" content="0; url=/relative with spaces">'
    stub_request(:get, 'http://foo.com/path%20with%20spaces').to_return(status: 200, body: body)
    stub_request(:get, 'http://foo.com/relative%20with%20spaces').to_return(status: 200, body: 'ok')

    follower = Unwind::RedirectFollower.resolve('http://foo.com/path with spaces')
    assert follower.redirected?
    assert_equal "http://foo.com/relative%20with%20spaces", follower.final_url
  end

  describe 'handling 404s' do
    it "should set not_found?" do
      stub_request(:get, 'http://nope.com').to_return(status: 404)
      follower = Unwind::RedirectFollower.resolve('http://nope.com/')
      assert follower.not_found?
    end
  end
  
  # unseemly hack to emulate Fakeweb's "last_request" functionality.
  last_request = nil
  WebMock.after_request do |req, response|
    request = {
      uri: req.uri.to_s,
      method: req.method.to_s.upcase,
      headers: req.headers,
      body: req.body,
      request: req
    }
    last_request = request
  end

  describe 'preserving cookies' do
    it "should preserve cookies to redirected domains" do
      stub_request(:get, 'http://foo.com').to_return(status: 302, headers: {
        "set-cookie" => "sid=3EBE6B02-E226-017F-541D-B1D03209F38B; Path=/; Domain=.foo.com",
        "location" => "http://bar.com" })

      stub_request(:get, 'http://bar.com').to_return(status: 302,
        headers: {"location" => "http://foo.com/content"})

      stub_request(:get, 'http://foo.com/content').to_return(status: 200)

      follower = Unwind::RedirectFollower.resolve('http://foo.com/')

      assert_equal(last_request[:headers]["Cookie"], "sid=3EBE6B02-E226-017F-541D-B1D03209F38B")
    end
  end

  it "should raise exception on timeout" do
    stub_request(:get, "http://slow.com").to_return(:exception => Timeout::Error)
    lambda { Unwind::RedirectFollower.resolve('http://slow.com/') }.must_raise Unwind::TimeoutError
  end

end
