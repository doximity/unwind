require 'minitest/autorun'
require './lib/unwind/canonical_link'

describe Unwind::CanonicalLink do
  describe ".resolve" do
    let(:base_url) { 'http://oncology.jamanetwork.com/article.aspx?articleid=2517400' }
    let(:resolved_url) { 'http://oncology.jamanetwork.com/article.aspx?articleid=251' }

    subject { Unwind::CanonicalLink.new(base_url, link).resolve }

    describe 'when canonical link is relative and invalid' do
      let(:link) { 'oncology.jamanetwork.com/article.aspx?articleid=251' }
      it "resolves to the correct url" do
        assert_equal(subject.to_s, resolved_url)
      end
    end

    describe "when canonical link is relative and valid" do
      let(:link) { '/article.aspx?articleid=251' }
      it "resolves to the correct url" do
        assert_equal(subject.to_s, resolved_url)
      end
    end

    describe "when canonical link is absolute" do
      let(:link) { resolved_url }
      it "resolves to the correct url" do
        assert_equal(subject.to_s, resolved_url)
      end
    end

    describe 'when canonical link is absolute without scheme' do
      let(:link) { '//oncology.jamanetwork.com/article.aspx?articleid=251' }
      it "resolves to the correct url" do
        assert_equal(subject.to_s, resolved_url)
      end
    end

    describe 'when canonical link contains spaces' do
      let(:link) { " #{resolved_url}"}
      it "resolves to the correct url" do
        assert_equal(subject.to_s, resolved_url)
      end
    end

    describe 'when canonical link contains leading invisible characters' do
      let(:link) { "\x01#{resolved_url}" }
      it "resolves to the correct url" do
        assert_equal(subject.to_s, resolved_url)
      end
    end

    describe 'when canonical link contains leading symbols' do
      let(:link) { "%01#{resolved_url}" }
      it "resolves to the correct url" do
        assert_equal(subject.to_s, resolved_url)
      end
    end

    describe 'when canonical link is empty' do
      let(:link) { "" }
      it "resolves to the last known url" do
        assert_equal(subject.to_s, base_url)
      end
    end

    describe 'when link is nil' do
      let(:link) { nil }
      it "resolves to the correct url" do
        assert_nil(subject)
      end
    end

    describe 'when link is completely unreadable' do
      let(:link) { ":::::"}
      it "resolves to the correct url" do
        assert_nil(subject)
      end
    end
  end
end
