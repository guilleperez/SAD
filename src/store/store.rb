# Final Project: Adventure Game with Microservices
# Date: 26-Nov-2018
# Authors: A01377162 Guillermo Pérez Trueba
#          A01020507 Luis Ángel Lucatero Villanueva
#          A01375996 Alan Joseph Salazar Romero

require 'yaml'
require "json"
require "sinatra"

PORT = 8081
URL = "http://localhost:#{PORT}"
set :bind, "0.0.0.0"
set :port, PORT


ITEMS = YAML.load_file('store.yml')

# Method to set up the JSON
before do
    content_type :json
end

# Method for configuring error 
not_found do
    {'error' => "Resource not found:#{ request.path_info}\n"}.to_json
end

# Method for printing all ints
get '/store' do
    JSON.pretty_generate(ITEMS.map.with_index do |q, i|
        {
            'id' => i,
            'url' => "#{URL}/store/#{i}"
        }
        end)
end

# Method convert to ints
def convert_to_int(str)
    begin
        Integer(str)
    rescue ArgumentError
        -1
    end
end

# Method for the room we need
get '/store/:id' do
    id_str = params['id']
    id = convert_to_int(id_str)
    if id >= 0 and id < ITEMS.size
        JSON.pretty_generate(ITEMS[id])
    else
        [404, {'error' => "Question not found with ID = #{id_str}"}.to_json]
    end
end

puts ITEMS

#3010 REM INVENTORY/PROVISIONS
# 3020 PRINT "PROVISIONS & INVENTORY"
# 3030 GOSUB 3260
# 3040 IF WEALTH<.1 THEN Z=0:GOTO 3130
# INPUT "";Z
# 3130 IF Z=0 THEN CLS:RETURN
# 3140 IF Z=1 THEN LIGHT=1:WEALTH=WEALTH-15
# 3150 IF Z=2 THEN AXE=1:WEALTH=WEALTH-10
# 3160 IF Z=3 THEN SWORD=1:WEALTH=WEALTH-20
# 3170 IF Z=5 THEN AMULET=1:WEALTH=WEALTH-30
# 3180 IF Z=6 THEN SUIT=1:WEALTH=WEALTH-50
# 3190 IF WEALTH<0 THEN PRINT "YOU HAVE TRIED TO
# CHEAT ME!":WEALTH=0:SUIT=0:LIGHT=0:AXE=0:SWORD=0:
# AMULET=0:FOOD=INT(FOOD/4):GOSUB 3520
# 3200 IF Z<>4 THEN 3030
# 3210 INPUT "HOW MANY UNITS OF FOOD";Q:Q=INT(Q)
# 3220 IF 2*Q>WEALTH THEN PRINT "YOU HAVEN'T GOT
# ENOUGH MONEY":GOTO 3210
# 3230 FOOD=FOOD+Q
# 3240 WEALTH=WEALTH-2*Q
# 3250 GOTO 3030
# 3260 IF WEALTH>0 THEN PRINT:PRINT:PRINT "YOU HAVE
# $";WEALTH
# 3270 IF WEALTH=0 THEN PRINT "YOU HAVE NO
# MONEY":GOSUB 3520:RETURN
# 3280 FOR J=1 TO 4:PRINT:NEXT J
# 3290 RETURN