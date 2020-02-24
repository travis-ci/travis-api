describe Token do
  it 'generate_token sets the token to a 20 character value' do
    expect(Token.new.send(:generate_token).length).to eq(20)
  end

  it 'does not generate new token on save' do
    token = Token.create!

    expect {
      token.save
    }.to_not change { token.token }
  end
end
