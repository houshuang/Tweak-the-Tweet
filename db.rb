require 'rubygems'
require 'active_record'

module DB

  class Tweet < ActiveRecord::Base
  end 

  class Init
    def initialize
      already = File.exists?("database.db")
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
        end
      end
    end

  end
end