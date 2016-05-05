require 'minitest/autorun'
require './lib/unwind/canonical_link'

describe Unwind::CanonicalLink do
  describe ".resolve" do
    let(:resolved_url) { 'http://oncology.jamanetwork.com/article.aspx?articleid=251' }

    describe "when canonical link is relative and invalid" do
      let(:base_url) { 'http://oncology.jamanetwork.com/article.aspx?articleid=2517400' }
      let(:link) { 'oncology.jamanetwork.com/article.aspx?articleid=251' }
      subject { Unwind::CanonicalLink.new(base_url, link) }

      it "builds a valid url" do
        assert_equal subject.resolve.to_s, resolved_url
      end
    end

    describe "when canonical link is relative and valid" do
      let(:base_url) { 'http://oncology.jamanetwork.com/article.aspx?articleid=2517400' }
      let(:link) { '/article.aspx?articleid=251' }
      subject { Unwind::CanonicalLink.new(base_url, link) }

      it "builds a valid url" do
        assert_equal subject.resolve.to_s, resolved_url
      end
    end

    describe "when canonical link is absolute" do
      let(:base_url) { 'http://oncology.jamanetwork.com/article.aspx?articleid=2517400' }
      subject { Unwind::CanonicalLink.new(base_url, resolved_url) }

      it "returns the link" do
        assert_equal subject.resolve.to_s, resolved_url
      end
    end
  end
end
