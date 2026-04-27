# frozen_string_literal: true

RSpec.describe Legion::Extensions::Velociraptor do
  it 'has a version number' do
    expect(Legion::Extensions::Velociraptor::VERSION).not_to be_nil
  end

  it 'defines the Client class' do
    expect(Legion::Extensions::Velociraptor::Client).to be_a(Class)
  end
end
