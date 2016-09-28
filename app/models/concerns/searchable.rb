module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    settings index: { number_of_shards: 1 } do
      mappings dynamic: 'false' do
        indexes :name,   type: 'string',  index_options: 'docs'
        indexes :slug,   type: 'string',  index_options: 'docs'
        indexes :login,  type: 'string',  index_options: 'docs'
        indexes :email,  type: 'string',  index_options: 'docs'
        indexes :id,     type: 'integer', index_options: 'docs'
        indexes :number, type: 'string',   index_options: 'docs'
        indexes :emails, type: 'nested' do
          indexes :email
        end
      end
    end
  end
end
