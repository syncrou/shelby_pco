#! /usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'csv'

Bundler.require

puts 'Importing from Shelby to PCO csv file'

puts 'Building PCO Headers'
pco_headers = []
pco_cnt = 0
shelby_cnt = 0

@city = nil

def household_ids(str_id, *strs)
  strs.compact!
  strs.each { return str_id + '000' } unless strs.empty?
  return str_id + '000' unless str_id.nil?
end

def convert_dates(str)
  return str unless str
  dates = str.split('/')
  return str if dates[2].match(/\d{4}/)

  dates[2] = dates[2].to_i >= 16 ? "19#{dates[2]}" : "20#{dates[2]}"
  dates.join('/')
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
    address.delete!(/,/, '') rescue address
  else
    address
  end
end

def city(city_str)
  return if city_str.nil?
  return city_str unless city_str.include?(' ')
  city_array = city_str.split(' ')
  @city = city_array[0]
  @city
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
  CSV.foreach('area_codes_mi.csv') do |row|
    if @city == row[0]
      "#{row[0]}-#{phone_num}"
    else
      "000-#{phone_num}"
    end
  end

end

def phone(phone_str)
  return phone_str if phone_str.nil?
  phone_str.include?('.') && phone_str.tr!('.', '-')
  return phone_str if phone_str.size == 12
  build_area_code(phone_str)
end

def primary(str)
  return '' if str.nil?
  return 'TRUE' if str == 'Head of House'
  'FALSE'
end


CSV.foreach('PCOImport.csv') do |row|
  break if pco_cnt == 1
  pco_headers = row
  pco_cnt += 1
end

puts 'Building PCO Output from Shelby Input csv'
CSV.open('pco_output.csv', 'wb') do |csv|
  csv << pco_headers

  CSV.foreach('ShelbyExport.csv') do |row|
    #       0    1   2    3       4       5     6             7                   8 Gender
    csv << [household_ids(row[90], row[103], row[116], row[129], row[142], row[155], row[168], row[181], row[194], row[207]), '', '', row[5], row[8], row[6], '', convert_dates(row[29]), manage_gender(row[28]),
            '', '', '', child?(row[36]), row[33], '', '', '', 'TRUE', 'TRUE', 'TRUE', street(row[11]),
           city(row[16]), state(row[17]), zip(row[18]), phone(row[25]), '', '', row[31], row[34], row[35],
           row[38], row[39], '', '', '', '', '', primary(row[35]), 'Yes'] unless shelby_cnt == 0
    shelby_cnt += 1
  end

end
