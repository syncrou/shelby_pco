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

def street(address)
  return if address.nil?
  if address.include?(',')
    address.gsub!(/,/,'') rescue address
  else
    address
  end
end

def city(city_str)
  return if city_str.nil?
  return city_str unless city_str.include?(' ')
  city_array = city_str.split(' ')
  city_array[0]
end

def state(state_str)
  return if state_str.nil?
  return state_str unless state_str.include?(' ')
  state_array = state_str.split(' ')
  state_array[1]
end

def zip(zip_str)
  return if zip_str.nil?
  return zip_str unless zip_str.include?(' ')
  zip_array = zip_str.split(' ')
  zip_array[2]
end

def build_area_code(phone_num)
  return "616-#{phone_num}"
  #CSV.foreach("area_codes_mi.csv") do |row|
  #end

end

def phone(phone_str)
  return phone_str if phone_str.nil?
  if phone_str.include?('.')
    phone_str.gsub!('.','-')
  end
  return phone_str if phone_str.size == 12
  build_area_code(phone_str)
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
    #       0    1   2    3       4       5     6             7                   8 Gender
    csv << ['', '', '', row[5], row[8], row[6], '', convert_dates(row[29]), manage_gender(row[28]),
            '', '', '', child?(row[35]), row[33], '', '', '', 'TRUE', 'TRUE', 'TRUE', street(row[11]),
           city(row[16]), state(row[17]), zip(row[18]), phone(row[25]) ] unless shelby_cnt == 0
    shelby_cnt +=1
  end

end
