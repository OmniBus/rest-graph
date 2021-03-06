
if respond_to?(:require_relative, true)
  require_relative 'common'
else
  require File.dirname(__FILE__) + '/common'
end

describe RestGraph do
  after do
    reset_webmock
    RR.verify
  end

  it 'would do fql query with/without access_token' do
    fql = 'SELECT name FROM likes where id="123"'
    query = "format=json&query=#{CGI.escape(fql)}"
    stub_request(:get, "https://api.facebook.com/method/fql.query?#{query}").
      to_return(:body => '[]')

    RestGraph.new.fql(fql).should == []

    token = 'token'.reverse
    stub_request(:get, "https://api.facebook.com/method/fql.query?#{query}" \
      "&access_token=#{token}").
      to_return(:body => '[]')

    RestGraph.new(:access_token => token).fql(fql).should == []
  end

  it 'would do fql.mutilquery correctly' do
    f0 = 'SELECT display_name FROM application WHERE app_id="233082465238"'
    f1 = 'SELECT display_name FROM application WHERE app_id="110225210740"'
    f0q, f1q = "\"#{f0.gsub('"', '\\"')}\"", "\"#{f1.gsub('"', '\\"')}\""
    q = "format=json&queries=#{CGI.escape("{\"f0\":#{f0q},\"f1\":#{f1q}}")}"
    p = "format=json&queries=#{CGI.escape("{\"f1\":#{f1q},\"f0\":#{f0q}}")}"

    stub_multi = lambda{
      stub_request(:get,
        "https://api.facebook.com/method/fql.multiquery?#{q}").
        to_return(:body => '[]')

      stub_request(:get,
        "https://api.facebook.com/method/fql.multiquery?#{p}").
        to_return(:body => '[]')
    }

    stub_multi.call
    RestGraph.new.fql_multi(:f0 => f0, :f1 => f1).should == []
  end

  it 'would do facebook old rest api' do
    body = 'hate facebook inconsistent'
    stub_request(:get,
      'https://api.facebook.com/method/notes.create?format=json').
      to_return(:body => body)

    RestGraph.new.old_rest('notes.create', {}, :suppress_decode => true).
      should == body
  end

  it 'would exchange sessions for access token' do
    stub_request(:post,
      'https://graph.facebook.com/oauth/exchange_sessions?'     \
              'type=client_cred&client_id=id&client_secret=di&' \
              'sessions=bad%20bed').
      to_return(:body => '[{"access_token":"bogus"}]')

    RestGraph.new(:app_id => 'id',
                  :secret => 'di').
      exchange_sessions(:sessions => 'bad bed').
      first['access_token'].should == 'bogus'
  end
end
