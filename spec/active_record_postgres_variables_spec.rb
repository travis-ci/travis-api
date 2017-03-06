describe "ActiveRecordPostgresVariables" do
  let(:variables) {{ foo: 'bar' }}
  let(:database_options) { Travis.config.database.to_h.merge(variables: variables) }
  let(:base) { Class.new(ActiveRecord::Base) }

  it "passes on variables to postgres connections" do
    base.establish_connection(database_options)
    expect { base.table_exists? }.to raise_error(ActiveRecord::StatementInvalid, /unrecognized configuration parameter "foo"/)
  end
end
