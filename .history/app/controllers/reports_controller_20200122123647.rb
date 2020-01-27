class ReportsController < ApplicationController
  require 'csv'

  def index
  end

  def download_csv
    begin
      csv_data = Services::Report::InvoiceReport.new(params[:report][:from], params[:report][:to], params[:report][:type]).call
      flash.now[:success] = "Your report has been successfully generated! Click <a href='#{csv_file_path}'>here</a> to download".html_safe

    rescue => e
      puts "failed #{e}"
    end
    respond_to do |format|
      format.csv { send_data csv_data, filename: "#{params[:report][:type]}_#{params[:report][:from]}_#{params[:report][:to]}.csv" }
      
    end

  end

end
