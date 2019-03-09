# Final Project: Adventure Game with Microservices
# Date: 26-Nov-2018
# Authors: A01377162 Guillermo Pérez Trueba
#          A01020507 Luis Ángel Lucatero Villanueva
#          A01375996 Alan Joseph Salazar Romero

require 'yaml'
require 'sinatra'
require 'json'

PORT = 8082
URL = "http://localhost:#{PORT}"
set :bind, "0.0.0.0"
set :port, PORT

ROOMS = YAML.load_file('rooms.yml')

# Method to set up the JSON
before do
  content_type :json
end


# Method for configuring error 
not_found do
    {'error' => "Resource not found:#{ request.path_info}\n"}.to_json
end


# Method convert to ints
def convert_to_int(str)
  begin
    Integer(str)
  rescue ArgumentError
    -1
  end
end


# Method for printing all ints
get '/rooms' do
  JSON.pretty_generate(rooms.map.with_index do |q, i|
    {
      'id' => i,
      'room' =>"#{URL}/rooms/#{i}" 
    }
    end)
end


# Method for the room we need
get '/rooms/:id' do
  id_str = params['id']
  id = convert_to_int(id_str)
  
  if id >= 0 and id < ROOMS.size
      JSON.pretty_generate(ROOMS[id])
  else
      [404, {'error' => "Room not found with ID = #{id_str}"}.to_json]
  end
  
  
end
