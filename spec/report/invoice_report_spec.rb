require 'rails_helper'
require 'csv'

RSpec.describe Services::Report::InvoiceReport do
  let(:access_token)  { 'fake_auth_key' }

  before do
    set_variable_invoice
    host
  end

  describe '#call' do
    context 'reports' do
      let(:invoice_report_service) { Services::Report::InvoiceReport.new(@from, @to, @type)}

      context 'invoice' do

        before do
          WebMock.stub_request(:get, host + "/report?from=#{@from}&to=#{@to}").
              with(headers: {'Authorization' => 'Token token=' + access_token, 'Content-Type'=>'application/x-www-form-urlencoded'}).
              to_return(status: 200,
                        body: "Invoice Date,Product Type,Invoice Number,Status,Plan Name\n"+"2020-01-01,Hosted Monthly,4F92070-0035,paid,travis-ci-two-builds")

        end
        it 'generate cvs file' do
          CSV.generate(headers: true) do |csv|
            invoice_report_service.http_request.each do |itesm|
              csv << itesm
            end
          end
        end
        it 'outputs the a invoice report' do
          expect(invoice_report_service.http_request.size).to eq(2)
          expect(invoice_report_service.http_request.first[0]).to eq('Invoice Date')
        end
      end
      context 'refunds' do
        before do
          @type = 'refund'
        end
        it 'outputs the a refund report' do
          WebMock.stub_request(:get, host + "/report?from=#{@from}&to=#{@to}&type=refunds").
              with(headers: {'Authorization' => 'Token token=' + access_token, 'Content-Type'=>'application/x-www-form-urlencoded'}).
              to_return(status: 200,
                        body: "Refund Date, Refund Number, Credit Note Id, Credit Note Number, Product Type\n"+"2020-01-01, re_1G1mJb247BizCpGIaemu46ah, cn_1G1mJf247BizCpGIHiWJiNUd, LTD7V-0003-CN-01, Hosted Monthly")

          expect(invoice_report_service.http_request.size).to eq(2)
          expect(invoice_report_service.http_request.first[0]).to eq('Refund Date')
        end
      end
    end
  end

  def host
    'http://api-billing-v2.travis-ci.com'
  end

  def set_variable_invoice
    @from = '2019-12-01'
    @to = '2019-12-05'
    @type = 'invoice'
  end

end
