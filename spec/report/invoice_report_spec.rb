require 'rails_helper'
require 'csv'

RSpec.describe Services::Report::InvoiceReport do
  let!(:billing_url) { 'https://billing-fake.travis-ci.com' }
  let!(:billing_auth_key) { 'fake_auth_key' }

  before do
    set_variable_invoice
  end

  describe '#call' do
    context 'reports' do
      let(:invoice_report_service) { Services::Report::InvoiceReport.new(@from, @to, @type)}

      context 'invoice' do

        before do
          stub_billing_request(:get, "#{billing_url}/report?from=#{@from}&to=#{@to}", auth_key: billing_auth_key)
              .to_return(status: 200,
                         body: "Invoice Date,Product Type,Invoice Number,Status,Plan Name\n"+"2020-01-01,Hosted Monthly,4F92070-0035,paid,travis-ci-two-builds")

        end
        it 'generates cvs file' do
          CSV.generate(headers: true) do |csv|
            invoice_report_service.csv_data.each do |itesm|
              csv << itesm
            end
          end
        end
        it 'outputs the a invoice report' do
          expect(invoice_report_service.csv_data.size).to eq(2)
          expect(invoice_report_service.csv_data.first[0]).to eq('Invoice Date')
        end
      end

      context 'refunds' do
        before do
          @type = 'refund'
        end
        it 'outputs the a refund report' do
          stub_billing_request(:get, "#{billing_url}/report?from=#{@from}&to=#{@to}&type=refunds", auth_key: billing_auth_key)
          .to_return(status: 200,
                         body: "Refund Date, Refund Number, Credit Note Id, Credit Note Number, Product Type\n"+"2020-01-01, re_1G1mJb247BizCpGIaemu46ah, cn_1G1mJf247BizCpGIHiWJiNUd, LTD7V-0003-CN-01, Hosted Monthly")


          expect(invoice_report_service.csv_data.size).to eq(2)
          expect(invoice_report_service.csv_data.first[0]).to eq('Refund Date')
        end
      end

    end
  end

  def set_variable_invoice
    @from = '2019-12-01'
    @to = '2019-12-05'
    @type = 'invoice'
  end

  def stub_billing_request(method, path, auth_key:)
    WebMock.stub_request(method, path).with(headers: { Authorization: 'Token token=' << auth_key , "User-Agent"=>"Faraday v0.9.2"})
  end

end