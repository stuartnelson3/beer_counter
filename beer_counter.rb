require 'shotgun'
require 'sinatra'
require 'dm-core'
require 'sinatra-authentication'
require 'data_mapper'
require 'rack-flash'
require 'sinatra/redirect_with_flash'
require 'dm-validations'

enable :sessions  
use Rack::Flash, :sweep => true

SITE_TITLE = "Beer Counter"
SITE_DESCRIPTION = "How much, where, and when"

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/beer_counter.db")

# class Night
#   include DataMapper::Resource
#   property :id, Serial
#   property :night, Text, :required => true
#   
#   has n, :beers
# end
 
class Beer  
  include DataMapper::Resource  
  property :id, Serial
  property :name, Text, :required => true
  validates_length_of :name, :max => 30
  property :type, Text, :required => true    
  property :price, Float, :required => true 
           validates_format_of :price, :with => /\$?\d{0,3}(\.{1}\d{2})?/
  property :quantity, Integer, :required => true, :format => /\d{1,3}/
  property :night, String, :required => true
  property :location, String, :required => true
  property :created_at, DateTime  
  property :updated_at, DateTime
  
  # belongs_to :nightout
end  

# n = Night.new
# n.night = "Friday"
# n.id = 1
# b = n.beers.new
# b.price = 3.50
# b.quantity = 5
# b.name = "Schlitz"
 
DataMapper.finalize.auto_upgrade!

helpers do  
  include Rack::Utils  
  alias_method :h, :escape_html
  def validation(v)
    l = "Errors are: "
    v.errors.each do |e|
      l += e.to_s
    end
    flash[:error] = "#{l}"
  end
end

get '/' do
  @title = "Home"
  @beer = Beer.all :order => :id.desc
  @total_spent = 0
  @total_drank = 0
  @beer.each do |beer|
    @total_spent += beer.price * beer.quantity
    @total_drank += beer.quantity
  end
  @quality_ratio = sprintf("%5.2f", @total_spent / @total_drank) unless @total_drank == 0
  #flash[:error] = 'No beers recorded. Add your first below.' if @beer.empty?
  erb :index
end

post '/' do
  b = Beer.new
  b.name = params[:name]
  b.type = params[:type]
  b.price = params[:price]
  b.quantity = params[:quantity]
  b.location = params[:location]
  b.night = params[:night]
  b.created_at = Time.now  
  b.updated_at = Time.now
  b.save ? flash[:notice] = 'Beer created successfully.' : validation(b)
  redirect '/'
end

get '/:id' do
  @title = "Edit your Night"
  @beer = Beer.get params[:id]
  if @beer
    erb :edit
  else
    redirect '/'
  end
end

put '/:id' do
  b = Beer.get params[:id]
  unless b
    redirect '/', :error => "That night doesn't seem to exist..."
  end
  b.name = params[:name]
  b.type = params[:type]
  b.price = params[:price]
  b.quantity = params[:quantity]
  b.night = params[:night]
  b.location = params[:location]
  b.updated_at = Time.now
  if b.save
    redirect '/', :notice => "Updated"
  else
    redirect '/', :notice => "Error updating"
  end
end

get '/:id/delete' do
  @title = "Pretend it never happened"
  @beer = Beer.get params[:id]
  unless @beer
    redirect '/', :error => "Can't find that beer."
  end
  erb :delete
end

delete '/:id' do
  @beer = Beer.get params[:id]
  if @beer.destroy
    redirect '/', :notice => "Like it never happened."
  else
    redirect '/', :error => "That shit won't scrub off."
  end
end