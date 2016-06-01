require 'minitest/autorun'
require './lib/unwind/canonical_link'

describe Unwind::CanonicalLink do
  describe ".resolve" do
    let(:resolved_url) { 'http://oncology.jamanetwork.com/article.aspx?articleid=251' }
    let(:base_url) { 'http://oncology.jamanetwork.com/article.aspx?articleid=2517400' }

    describe "when canonical link is relative and invalid" do
      let(:link) { 'oncology.jamanetwork.com/article.aspx?articleid=251' }
      subject { Unwind::CanonicalLink.new(base_url, link) }

      it "builds a valid url" do
        assert_equal subject.resolve.to_s, resolved_url
      end
    end

    describe "when canonical link is relative and valid" do
      let(:link) { '/article.aspx?articleid=251' }
      subject { Unwind::CanonicalLink.new(base_url, link) }

      it "builds a valid url" do
        assert_equal subject.resolve.to_s, resolved_url
      end
    end

    describe "when canonical link is absolute" do
      subject { Unwind::CanonicalLink.new(base_url, resolved_url) }

      it "returns the link" do
        assert_equal subject.resolve.to_s, resolved_url
      end
    end

    describe 'when canonical link is absolute without scheme' do
      let(:link) { '//oncology.jamanetwork.com/article.aspx?articleid=251' }
      subject { Unwind::CanonicalLink.new(base_url, link) }

      it 'builds a valid url using base_url scheme' do
        assert_equal subject.resolve.to_s, resolved_url
      end
    end
  end
end
