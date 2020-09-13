require 'spec_helper'

describe ActionNetworkRest::People do
  let(:api_key) { 'secret_key' }

  subject { ActionNetworkRest.new(api_key: api_key) }

  describe '#get' do
    let(:person_id) { 'abc-def-123-456' }
    let(:status) { 200 }
    let(:response_body) do
      {
        identifiers: ["action_network:#{person_id}"],
        email_addresses: [
          {
            primary: true,
            address: 'jane@example.com',
            status: 'subscribed'
          }
        ]
      }.to_json
    end

    before :each do
      stub_actionnetwork_request("/people/#{person_id}", method: :get)
        .to_return(status: status, body: response_body)
    end

    it 'should retrieve person data' do
      person = subject.people.get(person_id)
      expect(person.email_addresses.first.address).to eq 'jane@example.com'
    end
  end

  describe '#list' do
    let(:response_body) do
      {
        _embedded: {
          'osdi:people' => [
            {
              identifiers: [ 'action_network:d91b4b2e-ae0e-4cd3-9ed7-d0ec501b0bc3' ],
              given_name: 'John',
              family_name: 'Smith',
              email_addresses: [
                {
                  primary: true,
                  address: 'johnsmith@mail.com',
                  status: 'subscribed'
                }
              ],
            },
            {
              identifiers: [ 'action_network:1efc3644-af25-4253-90b8-a0baf12dbd1e' ],
              given_name: 'Jane',
              family_name: 'Doe',
              email_addresses: [
                {
                  primary: true,
                  address: 'janedoe@mail.com',
                  status: 'unsubscribed'
                }
              ],
            },
          ]
        }
      }.to_json
    end

    context 'requesting first page' do
      before :each do
        stub_actionnetwork_request("/people/?page=1", method: :get)
          .to_return(status: 200, body: response_body)
      end

      it 'should retrieve the people data from first page when calling without an argument' do
        people = subject.people.list

        expect(people.count).to eq 2
        expect(people.first.action_network_id).to eq 'd91b4b2e-ae0e-4cd3-9ed7-d0ec501b0bc3'
        expect(people.first.given_name).to eq 'John'
        expect(people.first.family_name).to eq 'Smith'
        expect(people.first.email_addresses.first.address).to eq 'johnsmith@mail.com'
        expect(people.last.action_network_id).to eq '1efc3644-af25-4253-90b8-a0baf12dbd1e'
        expect(people.last.given_name).to eq 'Jane'
        expect(people.last.family_name).to eq 'Doe'
        expect(people.last.email_addresses.first.address).to eq 'janedoe@mail.com'
      end

      it 'should retrieve the people data from first page when calling with page argument' do
        people = subject.people.list(page: 1)

        expect(people.count).to eq 2
        expect(people.first.action_network_id).to eq 'd91b4b2e-ae0e-4cd3-9ed7-d0ec501b0bc3'
        expect(people.first.given_name).to eq 'John'
        expect(people.first.family_name).to eq 'Smith'
        expect(people.first.email_addresses.first.address).to eq 'johnsmith@mail.com'
        expect(people.last.action_network_id).to eq '1efc3644-af25-4253-90b8-a0baf12dbd1e'
        expect(people.last.given_name).to eq 'Jane'
        expect(people.last.family_name).to eq 'Doe'
        expect(people.last.email_addresses.first.address).to eq 'janedoe@mail.com'
      end
    end

    context 'requesting page 10' do
      before :each do
        stub_actionnetwork_request("/people/?page=10", method: :get)
          .to_return(status: 200, body: response_body)
      end

      it 'should retrieve the people data from requested page number' do
        people = subject.people.list(page: 10)

        expect(people.count).to eq 2
        expect(people.first.action_network_id).to eq 'd91b4b2e-ae0e-4cd3-9ed7-d0ec501b0bc3'
        expect(people.first.given_name).to eq 'John'
        expect(people.first.family_name).to eq 'Smith'
        expect(people.first.email_addresses.first.address).to eq 'johnsmith@mail.com'
        expect(people.last.action_network_id).to eq '1efc3644-af25-4253-90b8-a0baf12dbd1e'
        expect(people.last.given_name).to eq 'Jane'
        expect(people.last.family_name).to eq 'Doe'
        expect(people.last.email_addresses.first.address).to eq 'janedoe@mail.com'
      end
    end

    context 'requesting with creation_date gt filter' do
      let!(:list_stub) {
        stub_actionnetwork_request("/people/?filter=created_date%20gt%20'2020-09-13'&page=1", method: :get)
          .to_return(status: 200, body: response_body)
      }

      let(:filter_date) { Date.new(2020, 9, 13) }

      it 'should retrieve the people data with greater than filter' do
        filter = { field: :created_date, op: ActionNetworkRest::GREATER_THAN, value: filter_date }
        people = subject.people.list(filter: filter)

        expect(list_stub).to have_been_requested
        expect(people.count).to eq 2
      end
    end

    context 'requesting email_address eq filter' do
      let!(:list_stub) {
        stub_actionnetwork_request("/people/?filter=email_address%20eq%20'user@example.com'&page=1", method: :get)
          .to_return(status: 200, body: response_body)
      }

      it 'should retrieve the people data with equals filter' do
        filter = { field: :email_address, op: ActionNetworkRest::EQUALS, value: 'user@example.com' }
        people = subject.people.list(filter: filter)

        expect(list_stub).to have_been_requested
        expect(people.count).to eq 2
      end
    end
  end

  describe '#create' do
    let(:person_data) do
      {
        given_name: 'Alan',
        family_name: 'Turing',
        email_addresses: [{address: 'alan@example.com'}]
      }
    end
    let(:request_body) { { person: person_data } }
    let(:response_body) do
      {
        identifiers: ["action_network:123-456-789"],
      }.to_json
    end

    let!(:post_stub) do
      stub_actionnetwork_request('/people/', method: :post, body: request_body)
        .to_return(status: 200, body: response_body)
    end

    it 'should POST person data' do
      person = subject.people.create(person_data)

      expect(post_stub).to have_been_requested

      expect(person.identifiers).to contain_exactly('action_network:123-456-789')
      expect(person.action_network_id).to eq '123-456-789'
    end

    context 'with tags' do
      let(:request_body) do
        {
          add_tags: ['foo', 'bar'],
          person: person_data
        }
      end

      it 'should include tags in post' do
        person = subject.people.create(person_data, tags: ['foo', 'bar'])

        expect(post_stub).to have_been_requested

        expect(person.identifiers).to contain_exactly('action_network:123-456-789')
        expect(person.action_network_id).to eq '123-456-789'
      end
    end
  end

  describe '#unsubscribe' do
    let(:person_id) { 'abc-def-123-456' }
    let(:request_body) do
      {
        email_addresses: [
          { status: 'unsubscribed' }
        ]
      }
    end
    let(:response_body) do
      {
        identifiers: ["action_network:#{person_id}"],
        email_addresses: [
          {
            primary: true,
            address: 'jane@example.com',
            status: 'unsubscribed'
          }
        ]
      }.to_json
    end
    let!(:put_stub) do
      stub_actionnetwork_request("/people/#{person_id}", method: :put, body: request_body)
        .to_return(status: 200, body: response_body)
    end

    it 'should PUT the unsubscribe request' do
      updated_person = subject.people.unsubscribe(person_id)

      expect(put_stub).to have_been_requested

      expect(updated_person.action_network_id).to eq person_id
    end
  end

  describe '#find_by_email' do
    let(:person_email) { 'jane+123@example.com' }
    let(:person_id) { 'abc-def-123-456' }
    let(:response_body) do
      {
        _embedded: {
          'osdi:people': [
            identifiers: ["action_network:#{person_id}"]
          ]
        }
      }.to_json
    end
    let(:person_result) do
      {
        'action_network_id' => 'abc-def-123-456',
        'identifiers' => ['action_network:abc-def-123-456']
      }
    end
    let!(:get_stub) do
      url_encoded_filter_string = CGI.escape("email_address eq '#{person_email}'")
      stub_actionnetwork_request("/people/?filter=#{url_encoded_filter_string}", method: :get)
        .to_return(status: 200, body: response_body)
    end

    let(:other_email) { 'mary+456@example.com' }
    let(:other_response_body) do
      {
        _embedded: {
          'osdi:people': []
        }
      }.to_json
    end
    let!(:other_get_stub) do
      url_encoded_filter_string = CGI.escape("email_address eq '#{other_email}'")
      stub_actionnetwork_request("/people/?filter=#{url_encoded_filter_string}", method: :get)
        .to_return(status: 200, body: other_response_body)
    end

    it 'should GET /people with filter request and return person object' do
      result = subject.people.find_by_email(person_email)
      expect(result).to eq(person_result)
    end

    it 'should GET /people with filter request and return nil if no person' do
      result = subject.people.find_by_email(other_email)
      expect(result).to be_nil
    end
  end

  describe '#update' do
    let(:person_data) do
      {
        given_name: 'John',
        family_name: 'Smith',
        phone_number: [ { number: '12021234444' } ]
      }
    end
    let(:person_id) { SecureRandom.uuid }
    let(:response_body) { person_data.to_json }
    let!(:put_stub) do
      stub_actionnetwork_request("/people/#{person_id}", method: :put, body: person_data)
        .to_return(status: 200, body: response_body)
    end

    it 'should PUT people data' do
      updated_person = subject.people.update(person_id, person_data)

      expect(put_stub).to have_been_requested

      expect(updated_person.family_name).to eq(person_data[:family_name])
    end
  end
end
