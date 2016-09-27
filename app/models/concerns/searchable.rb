module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model

    settings index: { number_of_shards: 1 } do
      mappings dynamic: 'false' do
        indexes :name,   type: 'string',  index_options: 'docs'
        indexes :slug,   type: 'string',  index_options: 'docs'
        indexes :login,  type: 'string',  index_options: 'docs'
        indexes :id,     type: 'integer', index_options: 'docs'
        indexes :number, type: 'float',   index_options: 'docs'
      end
    end

    def self.search(query)
      __elasticsearch__.search(
        {
          query: {
            multi_match: {
              query: query,
              fields: ['login^10', 'name', 'slug', 'id', 'number']
            }
          }
        }
      )
    end
  end
end
