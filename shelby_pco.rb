#! /usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'csv'

Bundler.require

puts "Importing from Shelby to PCO csv file"

puts "Building PCO Headers"
pco_headers = []
pco_cnt = 0
shelby_cnt = 0

def convert_dates(str)
  return str unless str
  date_array = str.split('/')
  return str if date_array[2].match(/\d{4}/)

  if date_array[2].to_i >= 16
    date_array[2] = "19#{date_array[2]}"
  else
    date_array[2] = "20#{date_array[2]}"
  end
  date_array.join('/')
end

def manage_gender(str)
  return '' if str == 'Unknown'
  str
end

def child?(str)
  str == 'Child' ? 'TRUE' : 'FALSE'
end

CSV.foreach("PCOImport.csv") do |row|
  break if pco_cnt == 1
  pco_headers = row
  pco_cnt +=1
end

puts "Building PCO Output from Shelby Input csv"
CSV.open("pco_output.csv", "wb") do |csv|
  csv << pco_headers

  CSV.foreach("ShelbyExport.csv") do |row|
    #       0    1   2    3       4       5     6             7                   8 Gender          9   10  11     12 Child        13     14  15  16    17     18       19
    csv << ['', '', '', row[5], row[8], row[6], '', convert_dates(row[29]), manage_gender(row[28]), '', '', '', child?(row[35]), row[33], '', '', '', 'TRUE', 'TRUE', 'TRUE' ] unless shelby_cnt == 0
    shelby_cnt +=1
  end

end
