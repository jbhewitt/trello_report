
require 'trello'
require 'pry'
require 'rubygems'
require 'thinreports'
require 'chronic'
require "date"
require "google_drive"
require 'yaml'

#get settings 
@config = YAML.load_file("settings.yaml")

#assumes today date...
START_DATE =  Chronic.parse('last sunday').strftime('%Y-%m-%d')
END_DATE =  Chronic.parse('next sunday').strftime('%Y-%m-%d')
TARGET_DATE = Date.today - 3
WEEK_NUMBER = TARGET_DATE.cweek.to_s
YEAR_NUMBER = TARGET_DATE.year.to_s 
SHEETNAME = "#{YEAR_NUMBER}-#{WEEK_NUMBER}"
REPORT_FILENAME = "./reports/#{@config['settings']['report_name']}-#{SHEETNAME}.pdf"
THIN_LAYOUT = @config['settings']['thin_layout']


include Trello
include Trello::Authorization

Trello::Authorization.const_set :AuthPolicy, OAuthPolicy
OAuthPolicy.consumer_credential = OAuthCredential.new @config['trello']['public_key'], @config['trello']['secret_key']
OAuthPolicy.token = OAuthCredential.new @config['trello']['access_token_key'], nil

board = Board.find(@config['trello']['board'])
#board.pry

list = List.find(@config['trello']['list'])
cards = list.cards

#cards.pry 
# GoogleDrive.login_with_oauth for details.
session = GoogleDrive.login(@config['googledocs']['google_username'], @config['googledocs']['google_password'])
spreadsheet = session.spreadsheet_by_key(@config['googledocs']['spreadsheet'])

#check if worksheet already exists, if not create a new one
ws = spreadsheet.worksheet_by_title(SHEETNAME)
if ws.nil?
  ws = spreadsheet.add_worksheet(SHEETNAME)
end


ThinReports::Report.generate_file( REPORT_FILENAME ) do
  puts "GENERATING #{REPORT_FILENAME}"

  use_layout( THIN_LAYOUT )

  start_new_page
  page.values :txt_period => "Year #{YEAR_NUMBER} - Week #{WEEK_NUMBER}",
          :txt_period_weekly => "Between #{START_DATE} to #{END_DATE}",
          :txt_header => "STC Report for Lanskey"

  ws[1,1] = 'card name!'
  row_no = 2

  cards.each do |card|
  	#write to thin
    page.list(:work_report_list).add_row :detail => "#{card.name.to_s}"
  	#write to gdoc
    ws[row_no, 1] = card.name.to_s
  	row_no = row_no + 1

    #is there checklists? if so add them!
    checkitems = card.checklists
    if !checkitems.empty? 
      checkitems[0].check_items.each do |item|
        page.list(:work_report_list).add_row :detail => "  - #{item['name'].to_s}"
        ws[row_no, 1] = "    - #{item['name'].to_s}"
        row_no = row_no + 1
      end        
    end

  #archive card
    #card.closed = true
    #card.save
  end

  ws.save()
  # Reloads the worksheet to get changes by other clients.
  ws.reload()
end


