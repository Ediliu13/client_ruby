# encoding: UTF-8

require 'prometheus/client/push'

describe Prometheus::Client::Push do
  let(:registry) { Prometheus::Client.registry }
  let(:push) { Prometheus::Client::Push.new('test-job') }

  describe '.new' do
    it 'returns a new push instance' do
      expect(push).to be_a(Prometheus::Client::Push)
    end

    it 'uses localhost as default Pushgateway' do
      expect(push.gateway).to eql('http://localhost:9091')
    end

    it 'allows to specify a custom Pushgateway' do
      push = Prometheus::Client::Push.new('test-job', nil, 'http://pu.sh:1234')

      expect(push.gateway).to eql('http://pu.sh:1234')
    end

    it 'raises an ArgumentError if a given gateway URL can not be parsed' do
      expect do
        Prometheus::Client::Push.new('test-job', nil, 'inva.lid:1233')
      end.to raise_error ArgumentError
    end
  end

  describe '#path' do
    it 'uses the default metrics path if no instance value given' do
      push = Prometheus::Client::Push.new('test-job')

      expect(push.path).to eql('/metrics/jobs/test-job')
    end

    it 'uses the full metrics path if an instance value is given' do
      push = Prometheus::Client::Push.new('bar-job', 'foo')

      expect(push.path).to eql('/metrics/jobs/bar-job/instances/foo')
    end

    it 'escapes non-URL characters' do
      push = Prometheus::Client::Push.new('bar job', 'foo <my instance>')

      expected = '/metrics/jobs/bar%20job/instances/foo%20%3Cmy%20instance%3E'
      expect(push.path).to eql(expected)
    end
  end

  describe '#push' do
    it 'pushes a given registry to the configured Pushgateway' do
      http = double(:http)
      http.should_receive(:send_request).with(
        'PUT',
        '/metrics/jobs/foo/instances/bar',
        Prometheus::Client::Formats::Text.marshal(registry),
        'Content-Type' => Prometheus::Client::Formats::Text::CONTENT_TYPE,
      )
      Net::HTTP.should_receive(:new).with('push.er', 9091).and_return(http)

      described_class.new('foo', 'bar', 'http://push.er:9091').push(registry)
    end
  end
end
