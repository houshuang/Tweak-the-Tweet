require 'rubygems'
require 'active_record'

module DB

  class Tweet < ActiveRecord::Base
  end 

  already = File.exists?("database.db")
  ActiveRecord::Base.allow_concurrency = true
  ActiveRecord::Base.establish_connection(
  :adapter  => 'sqlite3',
  :database => 'database.db'
  )

  unless already
    p 'creating database'
    ActiveRecord::Schema.define do
      create_table :tweets do |table|
        table.column :text, :string
        table.column :user, :string
      end
      create_table :howfar do |table|
        table.column :number, :number
      end
    end

  end
end