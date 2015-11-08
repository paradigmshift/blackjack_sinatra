require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
  :path => '/',
  :secret => 'some random string'

helpers do

  def create_deck
    rank = %w(Spades Diamonds Hearts Clubs)
    suit = %w(2 3 4 5 6 7 8 9 10 Jack Queen King Ace)
    rank.product(suit).shuffle
  end

  def calculate_total(hand)
    total = 0
    hand.map do |card|
      card[1].to_i == 0 && card[1] != 'Ace'? total += 10 : total += card[1].to_i
    end

    hand.select { |card| card[1] =='Ace' }.count.times do # check for Aces and ajust accordingly
      total + 11 <= 21 ? total += 11 : total += 1
    end

    total
  end

  def bust?(hand)
    calculate_total(hand) > 21
  end

  def blackjack?(hand)
    calculate_total(hand) == 21
  end

  def img_url(card)
    card_jpg = card[0].downcase + "_" + card[1].downcase + ".jpg"
    "<img src='/images/cards/#{card_jpg}' class='card_img'/>"
  end

  def won_bet
    session[:money] += session[:bet]
  end

  def lost_bet
    session[:money] -= session[:bet]
  end

end

#-------------------------------------------------------------------------------
# Set name and initial money
#-------------------------------------------------------------------------------

get '/' do
  redirect 'get-name' if not session[:name]
  session[:money] = 500
  redirect '/game-start'
end

get '/get-name' do
  erb :get_name
end

post '/set-name' do
  session[:name] = params[:name]
  if params[:name].empty?
    @error = "Please enter your name"
    halt erb(:get_name)
  end
  redirect '/'
end

#-------------------------------------------------------------------------------
# Game loop
#-------------------------------------------------------------------------------

get '/game-start' do
  session[:deck] = create_deck
  session[:player_hand] = []
  session[:dealer_hand] = []
  session[:bet] = nil
  session[:turn] = 'player'
  session[:message] = nil 
  2.times do
    session[:player_hand] << session[:deck].pop
    session[:dealer_hand] << session[:deck].pop
  end
  redirect '/game-loop'
end

get '/get-bet' do
  @error = params[:error]
  @error = "You have $0 left, please get more cash" if session[:money] == 0
  erb :bet
end

post '/set-bet' do
  if session[:money] >= params[:bet].to_i
    session[:bet] = params[:bet].to_i
    redirect '/game-loop?turn=player'
  else
    error = 'Not enough cash'
    redirect "/get-bet?error=#{error}"
  end
end

get '/game-loop' do
  redirect '/get-bet' if not session[:bet]
  case
  when blackjack?(session[:dealer_hand]) || blackjack?(session[:player_hand])
    redirect 'who-blackjack'
  when bust?(session[:dealer_hand]) || bust?(session[:player_hand])
    redirect 'who-bust'
  end
  redirect '/hit-or-stay' if session[:turn] == 'player'
  # Dealer's turn
  if calculate_total(session[:dealer_hand]) < 17
    session[:dealer_hand] << session[:deck].pop
    redirect '/game-loop'
  end
  redirect '/compare-hands'
end

get '/hit-or-stay' do
  erb :hit_or_stay
end

post '/stay' do
  session[:turn] = 'dealer'
  redirect '/game-loop'
end

post '/hit' do
  session[:player_hand] << session[:deck].pop
  redirect '/game-loop'
end

#-------------------------------------------------------------------------------
# Bust/Blackjack
#-------------------------------------------------------------------------------
get '/who-bust' do
  if bust?(session[:player_hand])
    lost_bet
    session[:message] = "You busted!"
  else
    won_bet
    session[:message] = "Dealer busted!"
  end
  redirect "/results"
end

get '/who-blackjack' do
  if blackjack?(session[:player_hand])
    won_bet
    session[:message] = "Blackjack! You won!"
  else
    lost_bet
    session[:message] = "Dealer hit Blackjack! You lose!"
  end
  redirect "/results"
end

#-------------------------------------------------------------------------------
# Results
#-------------------------------------------------------------------------------

get '/compare-hands' do
  if calculate_total(session[:player_hand]) > calculate_total(session[:dealer_hand])
    won_bet
    redirect 'results?winner=player'
  else
    lost_bet
    redirect 'results?winner=dealer'
  end
end

get '/results' do
  @error = params[:error]
  @winner = params[:winner]
  erb :results
end
