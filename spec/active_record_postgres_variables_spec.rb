describe "ActiveRecordPostgresVariables" do
  let(:variables) {{ foo: 'bar' }}
  let(:database_options) { Travis.config.database.merge(variables: variables) }
  let(:base) { Class.new(ActiveRecord::Base) }

  after do
    base.remove_connection
    ActiveRecord::Base.establish_connection(Travis.config.database)
  end

  it "passes on variables to postgres connections" do
    base.establish_connection(database_options)
    expect { base.table_exists? }.to raise_error(ActiveRecord::StatementInvalid, /unrecognized configuration parameter "foo"/)
  end
end
