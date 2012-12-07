require 'dbox'
require 'yaml'


@config = YAML.load_file("settings.yaml")

# Get your app key and secret from the Dropbox developer website
#export DROPBOX_AUTH_KEY='d6mp26mv03a19h8'
#export DROPBOX_AUTH_SECRET='vd7cf0cupxh0zgy'
#export DROPBOX_ACCESS_TYPE='app_folder'

Dbox.push('./reports/Lanskey-2012-49.pdf')