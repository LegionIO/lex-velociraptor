# frozen_string_literal: true

RSpec.describe Legion::Extensions::Velociraptor::Client do
  subject(:client) { described_class.new(api_config: '/tmp/api.config.yaml', binary: '/usr/local/bin/velociraptor', timeout: 10) }

  it 'stores configuration' do
    expect(client.opts[:api_config]).to eq('/tmp/api.config.yaml')
    expect(client.opts[:binary]).to eq('/usr/local/bin/velociraptor')
    expect(client.opts[:timeout]).to eq(10)
  end

  it 'uses environment defaults' do
    allow(ENV).to receive(:fetch).with('VELOCIRAPTOR_API_CONFIG', nil).and_return('/env/api.config.yaml')
    allow(ENV).to receive(:fetch).with('VELOCIRAPTOR_BIN', 'velociraptor').and_return('/env/velociraptor')

    env_client = described_class.new

    expect(env_client.opts[:api_config]).to eq('/env/api.config.yaml')
    expect(env_client.opts[:binary]).to eq('/env/velociraptor')
  end

  it 'returns settings options' do
    expect(client.settings[:options]).to include(api_config: '/tmp/api.config.yaml')
  end
end
