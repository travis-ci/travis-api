# encoding: utf-8
describe Repository::Settings::SshKey do
  let(:private_key) {
"-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAuHVhiw/2qaGmIiRbKjO5bZmQI0UEQ1vQVVxujL5SFAUsEB3w
YvcsdK+EDrmFfhrvVde1PnWzuwdq4seftZvTni+5KIjpNJ6/YKfYVUEOQ5ORvuqb
zrYPWzJShXnqvrFpbF82unHs4ceb+XzV/2Tciy/p5Yv535yweLRJKtcwK+ANLz8O
wF+IZf20StugF7tZaXMCXD1ieGg6fv5eV7lohfxYCeRTVJsMUxnwcrLxeqi8IgAa
q44IsIayTn5jcBZMwir8W+PrlXq44WHyLWnErXCH0Pds1UrbL6HFz5+uU0xoMO0N
vG1T0er1KIOooQ2dnbcH8UoDnrYSsn5mWFq1fwIDAQABAoIBABB5Qz3lLhVWP30b
HB03w167cTkFJ+1QHNoSyDi/oprxH09NLTPZeVnudu/Nt9NcWnWjLyel4WhZsD0S
sPvKL+sXvgSVvaYaa2MZemOazMhSPJj9YO7kKZjudJpBGirvs0efdUbPd+VuK0rr
0Dzf6CZyIASFLMrAtq4BA+vUjhPM5tmQqwhuZVkrr+GstCvJa2W2K4hbpZ+1XyhX
++XX4QnvQ1HXjVxo4LSXV05oJ9OBbiCh+OEkME3X3vPuy62E0WngFyH67NlryR1O
AyqrDPALf0Fl/1IXwGOZNsjHUQr8j+lbAE3uxwS7KNwlvEmJ8Hc2LdRwmlvTim9f
xWRGaWkCgYEA6GJ/FBgSykBs0FvYqvAs8O2Y1Rh1YJrInwSI/nG4yXEUDvmM+rFB
7Cb2AhTamw4VlHbu2dvUuVh4I2u1GVESrIy2+SV2xfzieoEG6+HWvRAm5owqKq2u
HSM3GFN2VGZzYl1J1260J9wlWHoPZV8vpgzD/VulN7x/TAXXwv/u0FMCgYEAyzQU
rIlbqsomx3G4Nzi4Nr9nLaKkRiAmSITzEVojItRWJRAKZtrMPV57JlGfNIqzAzAS
MWkcZr4XLvn6gxks37rrl7NtgRTTyq9MLTx5opMqQalYUIpp8PHMJ0vevdqVGgmS
FOP17SEyO2Tnc0UYAezyS8VuQ30u2ReJx/PJ0KUCgYBI3vIok+/4ekFlCRglalE9
b9Q4JoZQN9lnfB2VZIXkrU/z7i9WQZWBfyovtuhiLQV5W95EdNn9ERADU3gjqzem
4i1SbXwUU9uVPLa160jSWqlILHXgkjwCKRPSzgFSMBpIoyZPpwhZY4BWgVgomrOv
Z1tiLIXft31XkpF5NZZmvwKBgGsBJu3geywJvbgDE13I+YCi9CNc5SKkZWSE1jbJ
/3yk0iQ8OS4Gg8zBRxpbmvmhHDlOhBYO4szbxvuO2bNVe4LpPIyrCLwTip/OBdBA
a1EILBVdpsrqyHT/72C2HDpfs2p9pbZogKV5eKk8LoFN3iGNc94gvjq93gCl24E2
yIydAoGBALrYhMbK+ljTaqn4IsC0CwG5S6dLA/uXLn4QosDGtCqi1iXWKb8ixRho
x9giBf4WDeH3Gb2TBF1QnB8sbhHJAzTW/CO3vOjRiFSSF7EjxjCFier/LfuDU1Kr
tFns8eTxHpZOYOftxpX91vS3tzKCKgkdPhnYBDrvFFWnGgRLXFpb
-----END RSA PRIVATE KEY-----
"
  }

  let (:private_key_eddsa) { 
"-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACBQXfKTsmUKEONVc2i974UqTzI+Jci36WMfk/BnsWbU1gAAAJgPwlTaD8JU
2gAAAAtzc2gtZWQyNTUxOQAAACBQXfKTsmUKEONVc2i974UqTzI+Jci36WMfk/BnsWbU1g
AAAEBKnjD7h7IMc9yK5y+8yddm7Lze3vvP7+4OIbsYJ83raFBd8pOyZQoQ41VzaL3vhSpP
Mj4lyLfpYx+T8GexZtTWAAAAEmJnQExBUFRPUC1ISTQ5Q0hOTgECAw==
-----END OPENSSH PRIVATE KEY-----"
  }

  it 'validates correctness of private key' do
    ssh_key = described_class.new(value: private_key)
    expect(ssh_key).to be_valid

    ssh_key.value = 'foo'
    expect(ssh_key).not_to be_valid
    expect(ssh_key.errors.details[:value].map{|k| k[:error]}).to eq([:not_a_private_key])
  end

  it 'validates correctness of eddsa private key' do
    ssh_key = described_class.new(value: private_key_eddsa)
    expect(ssh_key).to be_valid

    ssh_key.value = 'foo'
    expect(ssh_key).not_to be_valid
    expect(ssh_key.errors.details[:value].map{|k| k[:error]}).to eq([:not_a_private_key])
  end

  it 'allows only private key' do
    public_key =  OpenSSL::PKey::RSA.new(private_key).public_key.to_s
    ssh_key = described_class.new(value: public_key)

    expect(ssh_key).not_to be_valid
    expect(ssh_key.errors.details[:value].map{|k| k[:error]}).to eq([:not_a_private_key])
  end

  it 'does not check key if a value is nil' do
    ssh_key = described_class.new({})

    expect(ssh_key).not_to be_valid
    expect(ssh_key.errors.details[:value].map{|k| k[:error]}).to eq([:blank])
  end

  describe 'with a passphrase' do
    let(:private_key) {
      "-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: AES-128-CBC,A2EDFC4C1196A9F3A58F327650CA6A1A

hfJtbnTxMhnqNLbRi1KGKE1rX3ypef5tIQPC+2OyUH4MQDTpaz5INoMqk1AjOz+O
LfmPZcy+5g3w9HJCHkGFU2kNmseHWCyoPQ3t9BKzaVWun4IxoMn7K2hZaebsyPQx
sq7vyDKAflgUKlkZgHWIimJ1lJH0CJB/3mplc16NeNqv1AaICFJagYHwPGHfVxa/
CQLPd2nw4LGmxEvmfuVq4qiSsYTqUkBA4wqgEX4bWGbkDZF2mKJvL/5AM5Cei+cy
ZhB4zm0mORoNQnGHbolYstHfm6h7RjlYDV60WC7iBnRRNuWmktzA+oOjH8RqQ29Z
LDcjyg4Rl0BsRwjkppOSScO6QAt4h740ZYHv7I/m3UAIl33xHjlz7PJb8aOzYqgC
QDFNJOr+AJx3tamY0Hg7v2l77oWQX8hHeJEbIySbftzIX+UrpSWFlcTNm4xpffI0
yO0Id2wY1mMOSs3yzNQ0AlGJR9Ns3P+2RjbyAJnuKI2ZctcBdlZSEiz/aavNW3ql
mv5FAzP4tSkTaWCnJaf8RAL0CSr5ppycWYGnZYbem6Bh9Cwe4f7PmQL5RJ/Y2rMc
V5ir+CFiVPFZP7by0OVz1Hg8XjynyCXej6J21el2hUyTI7oLxh/CxHW2lmqgUwYA
SNGGqMrYVQKxs+yp6i62OhKTl93jmW+8mE9VX6jIKBQJ7GBf44YLALwgxLyO6lCP
yY3dXI2QTb1StBHZhyQHazoghs3/6vEAEC8kj2U2NLBxlk8+caSEIrNoWRNCOAo+
1p75ZHrPDuTirDsyascOJ0Yff+O+uzCiqf9aPxxVJllhC2l6LGCwU1dsZ+O2RuaI
anH8OvFpSUhQY97vEnRDuPei/jz/C2/oZJzIdXCUmPvVn7Ut23m9A/1x6Mq3FA1X
iN09gB3XzsJZpxQ3TEMg+pp6bV64O5yZghAAWmKzJOmZ2j2BxCbuX3H399EAW3hc
sB/TxCh6kjiMOltbHtKsclsNZ9YQmk5+x4LwX4BSCV6YnytS+I49eMx1ikLX5nJR
tVAVsF5oE31pgg8lUgIWRJdK7EjjX/cDfkJYf9NWSwFCYxUKB+2adX/ix0eI1NGH
oJ+AD9tUrMAnNDTgFM4n5rtYDwf0fuA1C9RjJP8NcPm7oNlpyP2VQbtr3rSwmx+c
xYQuIZxqYbO+iwlJDuAst1n7dDIzPtnea/KUEQy4u7jmONKQ1VdA9dyGvqy4y8ie
bVDfnAzAvO17Zbvmqk0zQRmYXRsLuIN6QyWsfi8e2O7FctcpRVgc4e5xmBTfztBL
Q5feJ50wqE+JNfL5dQp8N0NtWFA6d4RLMN1T8zLhYASO/NOOzQtR7X+NlMrtm0wQ
aNDoTrIrg7xpuQOlMOe9UCwfcHu+DoPxUzZrqzhPlCGYSbecBW6G4+S4FPL5LpsW
NrYx30C8A87A0eEUNzLxO3CoPv7XhN/b0xf7W2CA79gbZnhgPtF12/11VmRo8ckl
zkrhrvtsjexdwYje7xjngPXrZ9USh13CoYNlduTlWB72m+wN8W7zyCLn1Zl/grTI
76Z2FZiqBEuPEcoDRrNUmX6MeNcMRo8Zq1FRi8imYnKYC0YsJMU0N+kIsiuGQsOI
-----END RSA PRIVATE KEY-----
"
    }

    it 'returns key_with_a_passphrase validation error' do
      ssh_key = described_class.new(value: private_key)

      expect(ssh_key).not_to be_valid

      expect(ssh_key.errors.details[:value].map{|k| k[:error]}).to eq([:key_with_a_passphrase])
    end
  end
end
