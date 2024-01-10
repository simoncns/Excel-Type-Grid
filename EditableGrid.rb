require 'curses'

class Interface
  attr_reader :current_col, :current_row

  def initialize(rows, cols)
    @rows = rows
    @cols = cols
    @data = Array.new(rows) { Array.new(cols, '') }
    @current_row = 0
    @current_col = 0
    @formula_editor = ''
  end

  def display
    Curses.clear
    print_grid
    print_formula_editor
    print_display_panel
    Curses.refresh
  end

  def edit_mode(row, col)
    Curses.echo
    Curses.setpos(row + 1, col * 5 + 3 + @formula_editor.length)
    input = Curses.getstr
    @formula_editor = input
    @data[row][col] = @formula_editor
    Curses.noecho
  end

  def update_cell
    begin
      result = eval(@formula_editor)
      @data[@current_row][@current_col] = result.to_s
    rescue StandardError => e
      @data[@current_row][@current_col] = "Error: #{e.message}"
    end
  end

  private

  def print_grid
    (0..@cols).each do |col|
      if col + 1 <= 9
        Curses.addstr("    #{col + 1} ")
      else
        Curses.addstr("    #{col + 1}")
      end
    end
    Curses.addstr("\n")

    (0...@rows).each do |row|
      if row + 1 <= 9
        Curses.addstr("#{row + 1}   ||  ")
      else
        Curses.addstr("#{row + 1}  ||  ")
      end
      (0...@cols).each do |col|
        content = " #{@data[row][col]} "
        if row == @current_row && col == @current_col
          Curses.attron(Curses.color_pair(Curses::COLOR_RED) | Curses::A_BOLD) { Curses.addstr(">#{content}<") }
        else
          Curses.addstr(content)
        end
        Curses.addstr("||  ")
      end
      Curses.addstr("\n")
    end
  end

  def print_formula_editor
    Curses.setpos(@rows + 3, 0)
    Curses.addstr("Formula Editor: #{@formula_editor}")
  end

  def print_display_panel
    Curses.setpos(@rows + 5, 0)
    Curses.addstr("Display Panel: #{@data[@current_row][@current_col]}")
  end
end

def main
  rows = 20
  cols = 20
  interface = Interface.new(rows, cols)

  Curses.init_screen
  Curses.start_color
  Curses.init_pair(Curses::COLOR_RED, Curses::COLOR_RED, Curses::COLOR_BLACK)
  Curses.cbreak
  Curses.noecho
  Curses.stdscr.keypad(true)

  loop do
    interface.display

    case Curses.getch
    when Curses::KEY_UP
      interface.instance_variable_set('@current_row', [interface.instance_variable_get('@current_row') - 1, 0].max)
    when Curses::KEY_DOWN
      interface.instance_variable_set('@current_row', [interface.instance_variable_get('@current_row') + 1, rows - 1].min)
    when Curses::KEY_LEFT
      interface.instance_variable_set('@current_col', [interface.instance_variable_get('@current_col') - 1, 0].max)
    when Curses::KEY_RIGHT
      interface.instance_variable_set('@current_col', [interface.instance_variable_get('@current_col') + 1, cols - 1].min)
    when 'e'
      interface.edit_mode(interface.current_row, interface.current_col)
    when 'u'
      interface.update_cell
    when 'q'
      break
    end
  end

  Curses.close_screen
end

main
