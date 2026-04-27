# frozen_string_literal: true

RSpec.describe Legion::Extensions::Velociraptor::Helpers::Cli do
  subject(:client) { Legion::Extensions::Velociraptor::Client.new(api_config: '/tmp/api.yaml', binary: 'velo') }

  let(:success_status) { instance_double(Process::Status, success?: true, exitstatus: 0) }
  let(:failure_status) { instance_double(Process::Status, success?: false, exitstatus: 1) }

  describe '#velociraptor_query_command' do
    it 'builds the supported api-config query command' do
      command = client.velociraptor_query_command(vql: 'SELECT * FROM info()', env: { Foo: 'bar' })

      expect(command).to eq(['velo', '--api_config', '/tmp/api.yaml', 'query', 'SELECT * FROM info()', '--format', 'jsonl', '--env', 'Foo=bar'])
    end

    it 'rejects invalid environment variable names' do
      expect { client.velociraptor_query_command(vql: 'SELECT * FROM scope()', env: { 'bad-name' => 'x' }) }
        .to raise_error(ArgumentError, /invalid VQL env key/)
    end
  end

  describe '#run_vql' do
    it 'parses jsonl rows from stdout' do
      allow(Open3).to receive(:capture3)
        .and_return(["{\"Hostname\":\"host1\"}\n{\"Hostname\":\"host2\"}\n", '', success_status])

      result = client.run_vql(vql: 'SELECT * FROM info()')

      expect(result[:rows]).to eq([{ 'Hostname' => 'host1' }, { 'Hostname' => 'host2' }])
    end

    it 'raises a command error on non-zero exit' do
      allow(Open3).to receive(:capture3).and_return(['', 'permission denied', failure_status])

      expect { client.run_vql(vql: 'SELECT * FROM info()') }
        .to raise_error(Legion::Extensions::Velociraptor::Helpers::Cli::CommandError)
    end
  end
end
