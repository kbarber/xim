require 'curses'

module Xim
  class Editor
    include Curses

    attr_accessor :mode

    def initialize(opts = {})
      @opts = opts

      @mode = :normal

      file = @opts[:file]

      init_screens

      if file
        load_file(:file => file)
      else
        new_file
      end

      main_loop
    end

    def init_screens
      Curses.init_screen
      Curses.start_color

      Curses.init_pair(COLOR_RED,COLOR_WHITE,COLOR_RED)

      @screen = Curses::Window.new(0,0,0,0)
      @screen.keypad(true)

      @main_scr = @screen.subwin(@screen.maxy-2,0,0,0)
      @main_scr.keypad(true)
      @main_scr.idlok(true)
      @main_scr.scrollok(true)
      @main_scr.setscrreg(0, @screen.maxy)
      @main_scr.refresh

      @status_scr = @screen.subwin(1,0,@screen.maxy-2,0)
      @status_scr.keypad(true)
      @status_scr.refresh
      @status_scr.attrset(Curses::A_REVERSE)

      @command_scr = @screen.subwin(1,0,@screen.maxy-1,0)
      @command_scr.keypad(true)
      @command_scr.refresh

      Curses.noecho
      Curses.cbreak
      Curses.raw

      @screen.setpos(0, 0)
      @screen.refresh
    end

    def load_file(opts = {})
      @file_name = opts[:file]

      @file_x = 0
      @file_y = 0

      f = File.open(@file_name)
      @file_contents = f.readlines()

      @file_contents.each do |line|
        @main_scr.addstr(line)
      end

      @main_scr.setpos(0,0)
      @main_scr.refresh
      update_status_line
    end

    def new_file(opts = {})
      @file_x = 0
      @file_y = 0
      @file_contents = ["\n"]
      @file_name = nil
      update_status_line
    end

    def quit
      Curses.close_screen
      puts "closing ..."
      exit(0)
    end

    def main_loop
      loop do
        react_to_key
      end
    rescue Interrupt => e
      quit
    end

    def react_to_key
      case @mode
      when :normal then react_to_key_normal
      when :command then react_to_key_command
      when :insert then react_to_key_insert
      end
    end

    def react_to_key_normal
      case @screen.getch
      when Curses::Key::UP then cursor_up
      when Curses::Key::DOWN then cursor_down
      when Curses::Key::RIGHT then cursor_right
      when Curses::Key::LEFT then cursor_left
      when ?x then cursor_del
      when ?X then cursor_del_left
      when ?u then scroll_up
      when ?d then scroll_down
      when ?: then command_mode
      when ?i then insert_mode
      end
    end

    def react_to_key_command
      ch = @command_scr.getch
      case ch.ord
      when 10 then command_submit
      when 32..126 then command_entry(ch)
      when 127 then command_delete
      when 27 then normal_mode
      end
    end

    def react_to_key_insert
      ch = @screen.getch
      case ch.ord
      when 10, 32..126 then insert_entry(ch)
      when 27 then normal_mode
      end
    end

    def cursor_up
      if @file_y > 0
        if (@main_scr.cury == 0)
          scroll_up
        else
          @main_scr.setpos(@main_scr.cury - 1, @main_scr.curx)
        end
        @file_y -= 1

        if @file_x >= (@file_contents[@file_y].length - 2)
          @max_x = @file_contents[@file_y].length - 1
          @main_scr.setpos(@main_scr.cury, @max_x)
          @file_x = @max_x
        end

        update_status_line
      end
    end

    def cursor_down
      if @file_y < (@file_contents.length - 1)
        if @main_scr.cury == (@main_scr.maxy - 1)
          scroll_down
        else
          @main_scr.setpos(@main_scr.cury + 1, @main_scr.curx)
        end
        @file_y += 1

        if @file_x >= (@file_contents[@file_y].length - 2)
          @max_x = @file_contents[@file_y].length - 1
          @main_scr.setpos(@main_scr.cury, @max_x)
          @file_x = @max_x
        end

        update_status_line
      end
    end

    def cursor_right
      if @file_x < (@file_contents[@file_y].length - 2)
        @main_scr.setpos(@main_scr.cury, @main_scr.curx + 1)
        @file_x += 1
        update_status_line
      end
    end

    def cursor_left
      if @file_x > 0
        @main_scr.setpos(@main_scr.cury, @main_scr.curx - 1)
        @file_x -= 1
        update_status_line
      end
    end

    def cursor_del
      if @file_x < (@file_contents[@file_y].length - 2)
        @main_scr.delch
        @file_contents[@file_y].slice!(@file_x)
      elsif @file_x == (@file_contents[@file_y].length - 2)
        @main_scr.delch
        cursor_left
        @file_contents[@file_y].slice!(@file_x)
      end
      @main_scr.refresh
    end

    def cursor_del_left
      if @file_x < (@file_contents[@file_y].length - 2)
        unless @main_scr.curx == 0
          cursor_left
          @main_scr.delch
          @file_contents[@file_y].slice!(@file_x)
        end
      end
      @main_scr.refresh
    end

    def scroll_up
      @main_scr.scrl(-1)
    end

    def scroll_down
      @main_scr.scrl(1)
    end

    def update_status_line
      x = @main_scr.curx
      y = @main_scr.cury

      @status_scr.setpos(0, 0)
      @status_scr.deleteln
      @status_scr.addstr(status_line)
      @status_scr.refresh

      @main_scr.setpos(y,x)
      @main_scr.refresh
    end

    def status_line
      "#{@file_name ? @file_name : '[No Name]'} [#{@file_x},#{@file_y}]"
    end

    def command_mode
      @main_x = @main_scr.curx
      @main_y = @main_scr.cury

      @command_string = ""
      @command_x = 0
      @command_y = 0

      @command_scr.setpos(0, 0)
      @command_scr.deleteln
      @command_scr.addstr(":")
      @command_scr.refresh

      @mode = :command
    end

    def normal_mode
      @main_scr.refresh

      @mode = :normal
    end

    def insert_mode
      @mode = :insert
    end

    def command_entry(ch)
      @command_scr.addch(ch)
      @command_string = @command_string.insert(@command_x, ch)
      @command_x += 1
      @command_scr.refresh
    end

    def command_delete
      if @command_x == 0
        command_area_clear
        normal_mode
      else
        @command_scr.setpos(0, @command_scr.curx - 1)
        @command_x -= 1
        @command_scr.delch
        @command_string.slice!(@command_x)
        @command_scr.refresh
      end
    end

    def command_submit
      command_area_clear
      command_submit_process(@command_string)
      normal_mode
    end

    def command_submit_process(command)
      case command
      when 'w'
        command_write
      when 'q'
        quit
      end
    end

    def command_write
      if @file_name
        tmpf = temp_file(@file_name)
        f = File.open(tmpf, 'w')
        @file_contents.each do |line|
          f.write(line)
        end
        f.close
        File.rename(tmpf, @file_name)
        command_status_update("\"#{@file_name}\" written")
      else
        command_status_error("E32: No file name")
      end
    end

    def temp_file(orig_file)
      orig_file + '.tmp.' + Random.new.rand(1000000).to_s
    end

    def command_status_update(status)
      command_area_clear
      @command_scr.addstr(status)
      @command_scr.refresh
    end

    def command_status_error(error)
      command_area_clear
      @command_scr.attron(color_pair(COLOR_RED)|A_BOLD)
      @command_scr.addstr(error)
      @command_scr.attrset(A_NORMAL)
      @command_scr.refresh
    end

    def command_area_clear
      @command_scr.attrset(A_NORMAL)
      @command_scr.clear
      @command_scr.refresh
    end

    def insert_entry(ch)
      @main_scr.insch(ch)
      @file_contents[@file_y] = @file_contents[@file_y].insert(@file_x, ch)
      cursor_right
      @main_scr.refresh
    end
  end
end
