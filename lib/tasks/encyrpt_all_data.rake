namespace :db do
  task :encrypt_all_columns do
    require 'travis'
    Travis::Database.connect

    to_encrypt = {
      SslKey  => [:private_key],
      Token   => [:token],
      User    => [:github_oauth_token]
    }

    encrypted_column = Travis::Model::EncryptedColumn.new
    to_encrypt.each do |model, column_names|
      model.find_in_batches(batch_size: 500) do |records|
        ActiveRecord::Base.transaction do
          puts "Encrypted 500 of #{model} (last_id: #{records.last.id})"
          records.each do |record|
            column_names.each do |column|

              data = record.send(column)
              if encrypted_column.encrypt?(data)
                record.update_column(column, encrypted_column.encrypt(data))
              end
            end
          end
        end

        sleep 5
      end
    end
  end
end
