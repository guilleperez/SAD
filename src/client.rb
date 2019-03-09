# Final Project: Adventure Game with Microservices
# Date: 26-Nov-2018
# Authors: A01377162 Guillermo Pérez Trueba
#          A01020507 Luis Ángel Lucatero Villanueva
#          A01375996 Alan Joseph Salazar Romero

require 'net/http'
require 'json'

#==========================================================
# URL to the microservice running in the same computer as
# the client.
#
#Store Microservice URL
URL_MICROSERVICE_ITEMS = 'http://localhost:8081/store'
#Rooms Microservice URL
URL_MICROSERVICE_ROOMS = 'http://localhost:8082/rooms'
#Map Microservice URL
URL_MICROSERVICE_MAP = 'https://kfjasudkr3.execute-api.us-west-2.amazonaws.com/default/maps'

#==========================================================
# Simple RESTful operations.
#
# Adapted from “Code example of using REST in Ruby on Rails” by LEEjava
# https://leejava.wordpress.com/2009/04/10/code-example-to-use-rest-in-ruby-on-rails/

# Constant Messages
#Failed to buy something message
FAIL_MESSAGE = "YOU HAVEN'T GOT ENOUGH MONEY"
#Success to buy message
BOUGHT_MESSAGE = "YOU HAVE BOUGHT "
#Failed to eat message
NOT_ENOUGH_FOOD = "YOU DON'T HAVE ENOUGH UNITS OF FOOD"
#Position to set in the map
POSITION = 6

#Module to manage the HTTP requests
module RESTful
  
  #GET Method
  def self.get(url)
    uri = URI.parse(url)
    use_ssl = (uri.scheme == 'https')
    http = Net::HTTP.start(uri.host, uri.port, use_ssl: use_ssl)
    resp = http.send_request('GET', uri.request_uri)
    resp.body
  end

  #POST Method
  def self.post(url, data, content_type)
    uri = URI.parse(url)
    use_ssl = (uri.scheme == 'https')
    http = Net::HTTP.start(uri.host, uri.port, use_ssl: use_ssl)
    http.send_request('POST', uri.request_uri, data, 'Content-Type' => content_type)
  end
  
  #PUT Method
  def self.put(url, data, content_type)
    uri = URI.parse(url)
    use_ssl = (uri.scheme == 'https')
    http = Net::HTTP.start(uri.host, uri.port, use_ssl: use_ssl)
    http.send_request('PUT', uri.request_uri, data, 'Content-Type' => content_type)
  end

  #DELETE Method
  def self.delete(url)
    uri = URI.parse(url)
    use_ssl = (uri.scheme == 'https')
    http = Net::HTTP.start(uri.host, uri.port, use_ssl: use_ssl)
    http.send_request('DELETE', uri.request_uri)
  end
end

#==========================================================

# Class that handles the whole game
class Game
  
  #Getters and Setters
  attr_accessor :strenght, :wealth, :name, :tally, :monsters_killed, :inventory, :room, :monster, :winner
  
  #Initialize Game method 
  def initialize
    @strenght = 100
    @wealth = 75
    @tally = 0
    @monsters_killed = 0
    @inventory = {'light' => 0, 'axe' => 0, 'sword' => 0, 'amulet' => 0, 'suit' => 0, 'food' => 0}
    @name = ''
    @room = 6
    @monster = ''
    @winner = false
  end

  # REM SET UP CASTLE
# Function that sets up the rooms in the castle
  def set_to_room(room, new_one)
    # JSON.parse(RESTful.post("#{ URL_MICROSERVICE_MAP }/setmaps/#{@room}/#{POSITION}/#{item}"))
    RESTful.post(URL_MICROSERVICE_MAP,
      {'type' => 'UPDATE', 'id' => room, 'pos' => POSITION, 'new_one' => new_one}.to_json,
      'application/json')
      #"body": "{\"type\": \"UPDATE\", \"id\": 1, \"pos\": 1, \"new_one\": 3}"
  end
  
# Function that sets up the treasuers in the castle
  def allot_treasures
    prng = Random.new
    (0...4).each do
     room = prng.rand(1...20)
     while room == 6 or room == 11
       room = prng.rand(1...20)
     end 
     new_one = prng.rand(5...101)
     set_to_room(room, new_one)
    end
  end
  
# Function that sets up the monsters in the castle
  def allot_monsters
    prng = Random.new
    (0...4).each do
      room = prng.rand(1...20)
      while room == 6 or room == 11
        room = prng.rand(1...20)
      end
     new_one = prng.rand(1...5)
     set_to_room(room, new_one)
    end
  end

# Function for setting up the castle prior to setting up the castle
  def zero_out
    RESTful.post(URL_MICROSERVICE_MAP,
     {"type": "RESET"}.to_json,
     'application/json')
  end

# Function that sets up the castle
  def setup_castle
    zero_out
    allot_treasures
    allot_monsters
    room_description
    sleep(1)
  end
  
  #Print Helpers
  #==========================================================
# Function that prints up the info of the player
  def print_info
    puts "#{@name}, YOUR STRENGHT IS #{@strenght}\nYOU HAVE $#{@wealth}\n"
  end

# Function that prints the inventory of the player
  def print_inventory
    items = get_store
    items.drop(1).each do |i|
      item = get_store_item(i['id'])
      value = item['item']
      key = item['key']
      
      if has_item?(@inventory[key])
        if key == 'light'
          describe_room(@room)
        elsif 
          puts "- #{@inventory[key]} #{value}"
        end
      elsif key == 'light'
        describe_room(-1)
      end
    end
    puts "**************************"
  end

# Function that displays the store of the game
  def display_store
    items = get_store
    puts "YOU CAN BUY: "
    items.each do |i|
       item = get_store_item(i['id'])
       puts item['option']
    end
  end

# Function that prints the help guide for the buttons
  def print_help
    puts "\n-----------------------------------"
    puts "INSTRUCTIONS"
    puts "PRESS 'N' TO MOVE NORTH"
    puts "PRESS 'S' TO MOVE SOUTH"
    puts "PRESS 'E' TO MOVE EAST"
    puts "PRESS 'W' TO MOVE WEST"
    puts "PRESS 'U' TO MOVE UP"
    puts "PRESS 'D' TO MOVE DOWN"
    puts "PRESS 'F' TO FIGT"
    puts "PRESS 'I' TO OPEN INVENTORY"
    puts "PRESS 'C' TO EAT FOOD"
    puts "PRESS 'A' TO USE YOUR MAGICAL AMULET"
    puts "PRESS 'P' TO PICK TREASURE"
    puts "PRESS 'Q' TO QUIT"
    puts "PRESS 'M' TO MOVE INTO THE OTHER ROOM"
    sleep(2)
  end

# Function that prints up the final score
  def print_score
    score = (3*@tally) + (5*@strenght) + (2*@wealth) + @inventory['food'] + (30*@monsters_killed)
    puts "#{@name}, YOUR SCORE IS #{score}";
  end

# Function that shows the player's inventory
  def show_inventory
    puts "\n-----------------------------------"
    puts "PROVISIONS & INVENTORY"
    puts print_wealth
  
    option = -1
    while option != 0
      display_store
      
      #Get item selected from the store
      puts "ENTER NO. OF ITEM REQUIRED"
      option = Integer(gets.chomp)
      
      valid_option =  (option >= 0 and  option <= 6)
      if not valid_option
        puts "Invalid Number"
        puts ""
      else
        item = get_store_item(option)
        cost = item['cost']
        quit = (option == 0)
        sleep(1)
        if not quit
          if is_cheating?
            reset_inventory()
          else
            if can_buy_item?(cost)
              buy_item(option, cost)
              puts BOUGHT_MESSAGE + item['item']
            else
              puts FAIL_MESSAGE
            end
          end
          print_wealth
          puts ""
        end
      end
    end
  end
  
  #REM DEAD END
# Function that prints a message when yo reach the game over
  def game_over
    puts "\nYOU HAVE DIED........."
    print_score
  end
  
  # Function that prints the player's wealth
  def print_wealth
    puts "YOU HAVE $#{@wealth}"
  end
  
  #Verify Helpers
  #==========================================================
  
# Fuction that verifies if the player has items
  def has_item?(count)
    count > 0
  end

# Function that determines if the player is cheating
  def is_cheating?
    return true if @wealth <= 0
    false
  end

# Function that determines if the player can buy an item
  def can_buy_item?(cost)
    return true if @wealth >= cost
    false
  end

# Function that verifies the player's strenght
  def verify_strength
    puts "WARNING YOUR STRENGHT IS RUNNING LOW: #{@strenght}" if @strenght<10
  end
  
  #Getter Helpers
  #==========================================================
  
# Function for the microservice of the store
  def get_store
    JSON.parse(RESTful.get(URL_MICROSERVICE_ITEMS))
  end

# Function for the microservice of the store  
  def get_store_item(id)
    JSON.parse(RESTful.get("#{ URL_MICROSERVICE_ITEMS }/#{id}"))
  end

# Function for the microservice of the rooms
  def get_rooms
    JSON.parse(RESTful.get(URL_MICROSERVICE_ROOMS))
  end

# Function for the microservice of the rooms
  def get_room(id)
    JSON.parse(RESTful.get("#{ URL_MICROSERVICE_ROOMS }/#{id}"))
  end

# Function for the microservice of the map
  def get_room_items
    Integer(eval(JSON.parse(RESTful.get("#{URL_MICROSERVICE_MAP}?id=#{@room}&pos=#{POSITION}")))[:contents])
  end
  
  
  #Other Helpers
  #==========================================================s
# Function to reset the inventory
  def reset_inventory
    puts "YOU HAVE TRIED TO CHEAT ME!\n"
    @wealth=0
    @inventory['food'] /= 4 
    @inventory.each do |key, value| 
      @inventory[key] = 0 if key != 'food'
    end
  end

# Function to buy food
  def buy_food(cost)
    while true
      puts "HOW MANY UNITS OF FOOD?"
      quantity = Integer(gets.chomp)
      total_cost = cost * quantity
      if can_buy_item?(total_cost)
        break
      else
        puts FAIL_MESSAGE
      end
      @inventory['food'] += quantity
    end
    total_cost
  end

# Fuction to buy food
  def buy_item(option, cost)
    case option
      when 1
        @inventory['light'] += 1
      when 2 
        @inventory['axe'] += 1
      when 3 
        @inventory['sword'] += 1
      when 4
        cost = buy_food(cost)
      when 5 
        @inventory['amulet'] += 1
      when 6 
        @inventory['suit'] += 1
    end
    @wealth = @wealth-cost
  end

# Function to print the description of a room
  def describe_room(id)
    puts "\n**************************"
    if id == -1 
     puts "IT IS TOO DARK TO SEE ANYTHING"
    else
      room = get_room(id)['room']
      puts room
      room_description
    end
    puts "YOU ARE CARRYING:"
  end

# Function to print the descriptions of the monsters
  def describe_monster(contents)
    @monster="FEROCIOUS WEREWOLF" if contents==1
    @monster="FANATICAL FLESHGORGER" if contents==2
  	@monster="MALOVENTY MALDEMER" if contents==3
  	@monster="DEVASTATING ICE-DRAGON" if contents==4
    level = (5 * contents)
    puts "IT IS A #{@monster}. THE DANGER LEVEL IS #{level}"
    level 
  end
  
  #REM ROOM DESCRIPTION
# Function to get the room description 
  def room_description
    contents = get_room_items
    level = 0
    if contents == 0
      puts "ROOM IS EMPTY" 
    else
      if contents >= 5
        puts "THERE IS TREASURE HERE WORTH #{contents}"
      elsif contents < 5
        puts "DANCER...THERE IS A MONSTER HERE...." 
        level = describe_monster(contents)
      end
    end
    level
  end
  
  #REM MAJOR HANDLING ROUTINE
# Function for the major handling routine
  def major_handling_routine
    print_info
    print_inventory
    verify_strength
    @tally += 1
  end

# Function that prints a message when you win
  def win 
    puts "YOU'VE DONE IT!! THAT WAS THE EXIT FROM THE CASTLE YOU HAVE SUCCEEDED, #{@name}! YOU MANAGED TO GET OUT OF THE CASTLE WELL DONE!"
    @winner = true
    print_score
  end
  
  # REM EAT FOOD
# Function that handles the food for recovery in the game
  def eat
   puts "\n-----------------------------------"
    if @inventory['food'] < 1
      puts NOT_ENOUGH_FOOD
    else
      puts "YOU HAVE #{@inventory['food']} UNITS OF FOOD"
      puts "HOW MANY DO YOU WANT TO EAT?"
      units = Integer(gets.chomp)
      if  units > @inventory['food']
        puts NOT_ENOUGH_FOOD
      else
        @inventory['food'] -= units
        @strenght += units
      end
    end
    sleep(1)
  end

# Function that handles the monster attacks  
  def monster_attacks(danger)
    attack = Random.new.rand(0...10)
    sleep(1)
    if attack >= 1
      if attack > danger or (@strenght==0)
      	puts "THE #{@monster} DEFEATED YOU"
      	@strenght/=2
      	danger = 0
      else
        puts "THE #{@monster} WOUNDS YOU!\nYOUR STRENGHT IS #{@strenght}"
        @strenght -= 5
      end
    else
      puts "THE #{@monster} MISSED"
    end
    danger
  end
  
# Function that handles the player attacks 
  def attack(danger)
    attack = Random.new.rand(0...5)
    if attack >= 1
      sleep(1)
      puts "YOU MANAGE TO WOUND #{@monster}"
    	danger=(5*danger/6)
    	if attack > danger
    	  @monsters_killed += 1 
    	  puts "AND YOU MANAGED TO KILL THE #{@monster}\nYOU HAVE KILLED #{@monsters_killed} MONSTERS!"
    	  danger = 0
    	  set_to_room(@room, 0)
    	else
    	   puts "#{@monster}'s STRENGHT IS #{danger}"
    	end
    else
      puts "YOU MISSED"
    end  
    danger
  end
  
  #REM THE BATTLE
# Function that handles the trancision in a fight
  def battle(danger)
    prng = Random.new
    puts "\n------------------------------------"
    while danger > 0
      turn = prng.rand(0...2)
      if turn == 0
      	puts "#{@monster} ATTACKS"
      	danger = monster_attacks(danger)
      else
      	puts "YOU ATTACK"
      	danger = attack(danger)
      end 
      puts ""
      sleep(2.5)
    end
    sleep(1)
    
  end

# Function that handles the armor in a fight
  def get_armory(danger)
    if @inventory['suit'] >= 1
      puts "YOUR ARMOR INCREASES YOUR CHANCE OF SUCCESS" 
      danger = 3 * (danger / 4)
    end
    if @inventory['axe']==0 and @inventory['sword']==0 
      puts "YOU HAVE NO WEAPONS. YOU MUST FIGHT WITH BARE HANDS"
      danger += (danger + danger/5)
    end
    puts "YOU HAVE ONLY AN AXE TO FIGHT WITH"  if @inventory['axe']>=1 and @inventory['sword']==0
    puts "YOU MUST FIGHT WITH YOUR SWORD" if @inventory['axe']==0 and @inventory['sword']>=1 
    sleep(1)
    danger
  end

# Function that handles weapons in a fight
  def select_weapon(danger)
    while true
      puts "WHICH WEAPON? 1 - AXE, 2 - SWORD"
      weapon = Integer(gets.chomp)
      if (weapon<1 or weapon>2)
         puts "INVALID KEY"
      elsif weapon==1 and @inventory['axe'] >= 1
        puts "AXE SELECTED"
        danger = 4*danger/5
        @inventory['axe'] -= 1
        break
      elsif weapon==2 and @inventory['sword']>=1 
        puts "SWORD SELECTED"
        danger = 3*danger/4
        @inventory['sword'] -= 1
        break 
      else
        puts "WEAPON IS NOT AVAILABLE"
      end
    end
    sleep(1)
    danger
  end
  
  #REM FIGHT
# Function that handles the fight in the game
  def fight 
    danger = room_description
    if danger > 0
      sleep(1)
      puts "------------------------------------"
      puts "PRESS ANY KEY TO FIGHT"
      gets.chomp
      danger = get_armory(danger)
      danger = select_weapon(danger) if @inventory['axe']>0 or @inventory['sword']>0 
      battle(danger)
    end
  end
  
  #REM PICK UP TREASURE
  # Function that allows you to pickup a treasure
  def pickup_treasure
    contents = get_room_items
    if contents == 0
      puts "THERE IS NO TREASURE TO PICK UP"
    else
      @wealth += contents
      puts "PICKED UP $#{contents}!"
      set_to_room(@room, 0)
    end
    
  end
  
  # Function that allows you to use a Magical Amulet
  def abbracadabra
    magical_power = Random.new.rand(0...50) 
    if @inventory['amulet'] > 0
      @strenght += @inventory['amulet'] * magical_power
      @inventory['amulet'] -= 1
      puts "YOU HAVE USED THE MAGIC OF HARRY HOUDINI, YOUR STRENGHT IS #{@strenght}"
    else
      puts "YOU DON'T HAVE AN AMULET"
    end
  end
  
# Function for the functionality of the diferent moves in the game
  def pick(move)
    quit = false
    case move
      when 'Q'
        print_score
        quit = true
      when 'H'
        print_help
      when 'C'
        eat
      when 'I'
        show_inventory
      when 'N' 
      	if @room == 1 
      	  puts 'NO EXIT THAT WAY'
      	 else
      	   @room = 1
      	end
      when 'S' 
      	if @room == 2 
      		puts 'THERE IS NO EXIT SOUTH'
      	else
      	  @room = 2
      	end
      when 'E' 
      	if @room == 3
      		puts 'YOU CANNOT GO IN THAT DIRECTION'
      	else
      	  @room = 3
      	end
      when 'W' 
      	if @room == 4
      	  puts 'YOU CANNOT MOVE THROUGH SOLID STONE'
      	 else
      	   @room = 4
      	end
      when 'U' 
      	if @room == 5
        	puts 'THERE IS NO WAY UP FROM HERE'
        else
          @room = 5
        end
      when 'D' 
      	if @room == 6 
      	  puts 'YOU CANNOT DESCEND FROM HERE'
      	else
      	  @room = 6
      	end
      when 'F' 
      	if @room == 7
      	  puts 'THERE IS NOTHING TO FIGHT HERE'
      	 else
      	   fight
        end
      when 'M'
        prng = Random.new
        @room = prng.rand(1...20)
        if @room == 6 or @room == 11
          win
          quit = true
        end
      when 'P'
        if @room == 7
          puts "THERE IS NO TREASURE TO PICK UP"
        elsif @inventory['light'] == 0
          puts "YOU CANNOT SEE WHERE IT IS"
        else
      	   pickup_treasure
      	end
      when 'A'
        abbracadabra
      when 'V'
        win
        quit = true
    end
    quit
  end
  
  #==========================================================

# Funtion to play the game
  def play_game
    puts "-----------------------------------"
    puts "WEREWOLVES AND WANDERER"
    puts "-----------------------------------"
    
    sleep(1.5)
    puts "\n-----------------------------------"
    puts 'WHAT IS YOUR NAME, EXPLORER?'
    @name = gets.chomp.upcase
    puts "\n-----------------------------------"
    print_info
    sleep(1.5)
    
    #Initialiase
    setup_castle
    
    # INVENTORY/PROVISIONS
    show_inventory
    
    #MAJOR HANDLING ROUTINE
    while @strenght > 0 
      puts "\n-----------------------------------"
      major_handling_routine
      
      puts "\nWHAT DO YOU WANT TO DO?"
      puts "PRESS 'H' FOR HELP"
      
      move = gets.chomp.upcase
      quit = pick(move)
      break if quit
      
      @strenght -= 5
      sleep(1)
    end
    if not @winner
      game_over
    end
  end
end


#==========================================================
game = Game.new
game.play_game
