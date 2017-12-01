describe "ActiveRecordPostgresVariables" do
  let(:variables) {{ foo: 'bar' }}
  let(:database_options) { Travis.config.database.to_h.merge(variables: variables) }

  it "passes on variables to postgres connections" do
    ActiveRecord::Base.establish_connection(database_options)
    expect { ActiveRecord::Base.table_exists? }.to raise_error(ActiveRecord::StatementInvalid, /unrecognized configuration parameter "foo"/)
  end

  after do
    ActiveRecord::Base.remove_connection
    ActiveRecord::Base.establish_connection(Travis.config.database.to_h)
  end
end
