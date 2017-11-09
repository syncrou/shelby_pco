#! /usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'csv'
require 'readline'

Bundler.require

def household_ids(str_id, *strs)
  strs.compact!
  strs.each { return str_id + '000' } unless strs.empty? || str_id.nil?
  str_id.nil? ? '' : str_id + '000'
end

def convert_dates(str)
  return str unless str != ''
  dates = str.split('/')
  return pad_dates(dates) if dates[2] =~ /\d{4}/

  dates[2] = dates[2].to_i >= 16 ? "19#{dates[2]}" : "20#{dates[2]}"
  pad_dates(dates)
end

def pad_dates(dates)
  dates[1] = sprintf('%02d', dates[1])
  dates[0] = sprintf('%02d', dates[0])
  dates.join('/')
end

def manage_gender(str)
  return '' if str == 'Unknown'
  str
end

def child?(str)
  str == 'Child' ? 'TRUE' : 'FALSE'
end

def mail_status(str)
  return '' unless str =~ /[yYNn]/
  if str == 'Y'
    'YES'
  elsif str == 'N'
    'NO'
  end
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

def mobile_phone(phone_str)
  return phone_str if phone_str.nil?
  phone_str.include?('.') && phone_str.tr!('.', '-')
  return phone_str if phone_str.size == 8
  build_area_code(phone_str)
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

def spinner(fps = 10)
  spinny_chars = %w(| / - \\)
  delay = 1.0 / fps
  iter = 0
  spinner = Thread.new do
    while iter do
      print spinny_chars[(iter += 1) % spinny_chars.length]
      sleep delay
      print "\b"
    end
  end
  yield.tap {
    iter = false
    spinner.join
  }
end

def file_stupid_checks
  print 'Cannot find any CSVs here.' if Dir.glob('*.{csv}').empty?

  Readline.completer_word_break_characters = '.csv'
  line = Readline.readline('Enter start of filename: ', true)
  filename = line.strip
  print "Importing #{filename} from Shelby to PCO csv file... \n"
  spinner { sleep rand(4) + 1 }
  puts 'Building PCO Headers...'
  csv_io(filename)
end

def force_next(str)
  return '-' if str.nil?
  str
end

def csv_io(filename)
  headers = CSV.open(filename, 'r', &:first)

  pco_headers = []
  pco_cnt = 0
  shelby_cnt = 0
  @city = nil

  CSV.foreach('PCOImport.csv') do |row|
    break if pco_cnt == 1
    pco_headers = row
    pco_cnt += 1
  end

  puts 'Building PCO Output from Shelby Input csv...'
  puts "Done! \n"
  CSV.open('pco_output.csv', 'wb') do |csv|
    csv << pco_headers

    CSV.foreach(filename, :encoding => 'ISO-8859-1') do |row|
      #       1   2    3       4       5     6             7                   8 Gender
      csv << [household_ids(row[headers.index("FamilyMember1NameID")], row[103], row[116], row[129], row[142], row[155], row[168], row[181], row[194], row[207]),
              '', '', force_next(row[headers.index("FirstName")]), row[headers.index("Salutation/Greeting")], row[headers.index("LastName")], '', convert_dates(row[headers.index("BirthDate")]),
              manage_gender(row[headers.index("Gender")]), '', '', '', child?(row[headers.index("FamilyPosition")]), row[headers.index("MaritalStatus")], row[headers.index("NextYearEnvelope#")], '', '', 'TRUE', 'TRUE', 'TRUE', street(row[headers.index("AddressLine1")]),
              city(row[headers.index("City")]), state(row[headers.index("State")]), zip(row[headers.index("PostalCode")]), phone(row[headers.index("Phone#")]), phone(row[headers.index("Phone#6")]),row[headers.index("Envelope#")], mail_status(row[headers.index("Envelope#")]), row[headers.index("FamilyPosition")],
              row[headers.index("EmailAddress")], row[headers.index("WebAddress")], '', '', '', '', '', primary(row[headers.index("MailStatus")]), 'Yes'] unless shelby_cnt == 0
      shelby_cnt += 1
    end
  end
end

file_stupid_checks
