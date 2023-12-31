require 'gosu'

# Main Window
class GameWindow < Gosu::Window
  # Constants and Game Settings - Adjustable 
  WIDTH = 800 
  HEIGHT = 600
  TILE_SIZE = 50
  CHARACTER_SIZE = 40
  MAX_OBSTACLES = 10
  LEVEL_UP_SCORE = 50

  def initialize
    super(WIDTH, HEIGHT)
    self.caption = "Pixel Dodger"

# Game related stuff
    @character_x = (WIDTH / 2) - (CHARACTER_SIZE / 2)       # Character's X - align center
    @character_y = HEIGHT - CHARACTER_SIZE - TILE_SIZE  # Character's Y - align center
    @score = 0           # Initial Score  
    @level = 1           # Initial Level
    @obstacles = []      # Obstacles array
    @obstacle_speed = 5  # Speed of obstacles
# Texts/fonts, music
    @font = Gosu::Font.new(self, "fonts/RetroGaming.ttf", 32)
    @game_name_font = Gosu::Font.new(self, "fonts/upheavtt.ttf", 48)
    @menu_font = Gosu::Font.new(self, "fonts/RetroGaming.ttf", 48)
    @background_music = Gosu::Song.new("background_music.mp3")  # BG music
    @collision_sound = Gosu::Sample.new("fail.mp3")  # Bruh sound when player collides
    @background_music.play(true)  # Loops background music
# Menu setup
    #@menu_font = Gosu::Font.new(48)
    @menu_items = ['Play Game', 'High Scores', 'Exit']
    @selected_item = 0
    @menu_change_cooldown = 350 # 350 milliseconds = 0.35s
    @last_menu_change_time = 0
# Controlling game state 
    @in_menu = true
    @game_over = false
    @high_score_menu = false
# Load high scores 
    load_high_scores
  end


# Game state handling
  def update
    if @in_menu
      handle_menu_input
    elsif @game_over
      handle_game_over_input
    elsif @high_score_menu
      handle_highscore_input
    else
      handle_gameplay_input
    end
  end

# Drawing elements based on game state 
  def draw
    if @in_menu
      draw_menu
    elsif @game_over
      draw_game_over
    elsif @high_score_menu
      draw_high_score
    else
      draw_character
      draw_obstacles
      draw_score
      draw_level
    end
  end

  def needs_cursor?
    false
  end

# ESCAPE = close game/window 
  def button_down(id)
    close if id == Gosu::KB_ESCAPE
  end
  

# Character drawing - Green Sqaure
  def draw_character
    Gosu.draw_rect(@character_x, @character_y, CHARACTER_SIZE, CHARACTER_SIZE, Gosu::Color::GREEN)
  end

# Obstacles drawing
  def draw_obstacles
    @obstacles.each do |obstacle|
      Gosu.draw_rect(obstacle[:x], obstacle[:y], TILE_SIZE, TILE_SIZE, Gosu::Color::RED)
    end
  end

# Write score on top left
  def draw_score
    @font.draw_text("Score: #{@score}", 20, 20, 1, 1, 1, Gosu::Color::WHITE)
  end

# Write level on top right
  def draw_level
    @font.draw_text("Level: #{@level}", 670, 20, 1, 1, 1, Gosu::Color::WHITE)
  end


# Play GAME! 
  # Left Arrow = move left by 5 pixels
  def handle_gameplay_input
    if Gosu.button_down?(Gosu::KB_LEFT) && @character_x > 0
      @character_x -= 5
    end
  # Right Arrow = move right by 5 pixels
    if Gosu.button_down?(Gosu::KB_RIGHT) && @character_x < WIDTH - CHARACTER_SIZE
      @character_x += 5
    end

    move_obstacles      # call obstacles movement
    check_collisions    # call check collisions
    level_up if @score >= @level * LEVEL_UP_SCORE
  end
    
## Function to moving obstacles
## For each obstacles, Y of obstacle is adding pixel from setting obstacle_speed
# The moment obstacle of y reaches bottom of the screen, aka > HEIGHT
# score is plus by 1, Move obstacle(y) back to above screen
# Randomize new horizon point
  def move_obstacles
    spawn_obstacles if @obstacles.length < MAX_OBSTACLES

    @obstacles.each do |obstacle|
      obstacle[:y] += @obstacle_speed
      if obstacle[:y] > HEIGHT
        obstacle[:y] = -TILE_SIZE
        obstacle[:x] = rand(WIDTH / TILE_SIZE) * TILE_SIZE
        @score += 1
      end
    end
  end

# Generate new obstacles under max obstacles settings
# Random between 0 and Number of Obstacles it can fit in one horizontal line
# Random number is then times with Tile size, (default 50px)
# This the calculation to generate random tiles utilizing hashes {x:, y:} :)
# Loop UNTIL @obstacles array reaches max allowed number defined by MAX_OBSTACLES (default = 10)
  def spawn_obstacles
    @obstacles.push({ x: rand(WIDTH / TILE_SIZE) * TILE_SIZE, y: -TILE_SIZE }) until @obstacles.length == MAX_OBSTACLES
  end

# Function for handling Menu Input
# Arrow up and down, select items/menu
# Return = select
  def handle_menu_input
    current_time = Gosu.milliseconds

    if Gosu.button_down?(Gosu::KB_DOWN) && current_time - @last_menu_change_time >= @menu_change_cooldown
      @selected_item = (@selected_item + 1) % @menu_items.length
      @last_menu_change_time = current_time
    elsif Gosu.button_down?(Gosu::KB_UP) && current_time - @last_menu_change_time >= @menu_change_cooldown
      @selected_item = (@selected_item - 1) % @menu_items.length  
      @last_menu_change_time = current_time
    elsif Gosu.button_down?(Gosu::KB_RETURN)
      handle_menu_selection
    end
  end

  def draw_menu
    menu_x = WIDTH / 2 - 150
    menu_y = HEIGHT / 2 - 50
  
     # Write "Pixel Dodger" using the custom font
    @game_name_font.draw_text("Pixel Dodger", (WIDTH - @game_name_font.text_width("Pixel Dodger") * 1.5) / 2, menu_y - 100, 1.5, 1.5, 1.5, Gosu::Color::WHITE)
    
    # Write navigation instructions
    instruction = "Use Arrow Up and Down to Navigate, and Use Enter to Select"
    @menu_font.draw_text(instruction, (WIDTH - @menu_font.text_width(instruction) * 0.5) / 2, menu_y + 200, 1, 0.5, 0.5, Gosu::Color::GRAY)
  
    # Write Play Again and Exit.
    # If index = selected item (from navigation), then color is yellow (selected), the other text is white (unselected)
      @menu_items.each_with_index do |item, index|
      color = (index == @selected_item) ? Gosu::Color::YELLOW : Gosu::Color::WHITE
      @menu_font.draw_text(item, menu_x, menu_y + index * 60, 1, 1, 1, color)
    end
  end

# When player press ENTER
  def handle_menu_selection
    case @selected_item
    when 0
      start_game
    when 1
      high_score
    when 2
      close
    end
  end

# Game Starts HERE
# Settings for game to start is set
  def start_game
    @in_menu = false      # not in menu anymore
    @character_x = (WIDTH / 2) - (CHARACTER_SIZE / 2)       # character's x redifined
    @character_y = HEIGHT - CHARACTER_SIZE - TILE_SIZE # character's y redefined
    @score = 250        # Reset Score to 0
    @obstacles.clear  # Clear all obstacles
    @level = 1        # Reset level to 1
    @obstacle_speed = 5   # obstacle speed = 5
    @game_over = false    # Not gameover state
    @background_music.play(true)  #
  end

  def high_score
    @in_menu = false      # not in menu anymore
    @game_over = false 
    @high_score_menu = true
  end

  def main_menu
    @in_menu = true
    @game_over = false
    @high_score_menu = false
  end

## Check each obstacles if they've collided by iterating and running collision function
  def check_collisions
    @obstacles.each do |obstacle|
      if collision?(@character_x, @character_y, CHARACTER_SIZE, CHARACTER_SIZE, obstacle[:x], obstacle[:y], TILE_SIZE, TILE_SIZE)
        @collision_sound.play
        reset_game
      end
    end
  end


 # Check if two objects (one described by x1, y1, w1, h1, and the other by x2, y2, w2, h2) are touching.
  # x1: X-coordinate (horizontal position) of the first object.
  # y1: Y-coordinate (vertical position) of the first object.
  # w1: Width of the first object.
  # h1: Height of the first object.
  # x2: X-coordinate (horizontal position) of the second object.
  # y2: Y-coordinate (vertical position) of the second object.
  # w2: Width of the second object.
  # h2: Height of the second object.
  def collision?(x1, y1, w1, h1, x2, y2, w2, h2)
    x1 < x2 + w2 && x1 + w1 > x2 && y1 < y2 + h2 && y1 + h1 > y2
  end


# Gameover 
  def reset_game
    @game_over = true
    save_high_scores if new_high_score?  # Check if the current score is a new high score
  end
  
  def new_high_score?
    @high_scores.size < 10 || @score > @high_scores.last
  end

# Conditions when player gets to next level 
  def level_up
    @level += 1
    @obstacle_speed += 1
  end






# EASY GAME OVER INPUT WHEN IN GAME OVER STATE
  def handle_game_over_input
    start_game if Gosu.button_down?(Gosu::KB_RETURN)
    close if Gosu.button_down?(Gosu::KB_ESCAPE)
    main_menu if Gosu.button_down?(Gosu::KB_M)
  end

def handle_highscore_input
  main_menu if Gosu.button_down?(Gosu::KB_BACKSPACE)
end 



# Draw Game Over Menu 
  def draw_game_over
    game_over_text = "Game Over!"
    final_score_text = "Your Score: #{@score}"
    instructions = "Press Enter to Play Again"
    main_menu_text = "Press M to Return to Main Menu"

  
    menu_x = WIDTH / 2 - 150
    menu_y = HEIGHT / 2 - 50
  
    @game_name_font.draw_text(game_over_text, (WIDTH - @game_name_font.text_width(game_over_text)) / 2, menu_y - 60, 1, 1, 1, Gosu::Color::RED)
    @menu_font.draw_text(final_score_text, (WIDTH - @menu_font.text_width(final_score_text)) / 2, menu_y, 1, 1, 1, Gosu::Color::WHITE)
    @menu_font.draw_text(instructions, (WIDTH - @menu_font.text_width(instructions) * 0.65) / 2, menu_y + 65, 1, 0.65, 0.65, Gosu::Color::GRAY)
    @menu_font.draw_text(main_menu_text, (WIDTH - @menu_font.text_width(main_menu_text) * 0.65) / 2, menu_y + 95, 1, 0.65, 0.65, Gosu::Color::GRAY)
  end

  def draw_high_score
    high_score_title = "High Scores"
    instructions = "Press Backspace to Return to Main Menu"
  
    menu_x = WIDTH / 2 - 150
    menu_y = HEIGHT / 2 - 50
  
    @game_name_font.draw_text(high_score_title, (WIDTH - @game_name_font.text_width(high_score_title)) / 2, menu_y - 150, 1, 1, 1, Gosu::Color::RED)
    @menu_font.draw_text(instructions, (WIDTH - @menu_font.text_width(instructions) * 0.65) / 2, menu_y + 300, 1, 0.65, 0.65, Gosu::Color::GRAY)
  
    # Draw high scores
    menu_y -= 130 
    index = 0
    while index < 10
    score= @high_scores[index]
    menu_y += 35
      score_text = "#{index + 1}. #{score}"
      @menu_font.draw_text(score_text, (WIDTH - @menu_font.text_width(score_text) * 0.7) / 2, menu_y, 0.70, 0.70, 0.70, Gosu::Color::WHITE)
    index += 1
    end
  end
  

  def load_high_scores
    @high_scores = []
  
    if File.exist?("highscore.txt")
      File.open("highscore.txt", "r") do |file|
        file.each_line do |line|
          @high_scores << line.to_i
        end
      end
    end
  end

  def save_high_scores
    @high_scores << @score
    @high_scores.sort!.reverse!
    @high_scores = @high_scores.take(10) # Limit to top 10 high scores
    File.write("highscore.txt", @high_scores.join("\n"))
  end
  
  

end # end of main 



# Run
GameWindow.new.show
