class SearcherList < RubyCurses::List
  def convert_value_to_text(value, crow)
    value
  end

  def highlight_focussed_row type, r=nil, c=nil, acolor=nil
    return unless @should_show_focus
    case type
    when :FOCUSSED
      ix = @current_index
      return if is_row_selected ix
      r = _convert_index_to_printable_row() unless r
      focussed = true

    when :UNFOCUSSED
      return if @oldrow.nil? || @oldrow == @current_index
      ix = @oldrow
      return if is_row_selected ix
      r = _convert_index_to_printable_row(@oldrow) unless r
      return unless r # row is not longer visible
      focussed = false
    end
    unless c
      _r, c = rowcol
    end

    @cell_renderer.repaint(@graphic, r, c, ix, list()[ix], focussed, false)
  end

=begin
  def highlight_selected_row r=nil, c=nil, acolor=nil
    return unless @selected_index # no selection
    r = _convert_index_to_printable_row(@selected_index) unless r
    return unless r # not on screen
    unless c
      _r, c = rowcol
    end
    STDERR.puts "r: #{r}, c: #{c}"
    @cell_renderer.repaint(@graphic, r, c, @selected_index, list()[@selected_index], false, true)
  end
  def unhighlight_row index,  r=nil, c=nil, acolor=nil
    return unless index # no selection
    r = _convert_index_to_printable_row(index) unless r
    return unless r # not on screen
    unless c
      _r, c = rowcol
    end
    @cell_renderer.repaint(@graphic, r, c, index, list()[index], false, false)
  end
=end

  def handle_key(ch)
    case ch
    when Ncurses::KEY_NPAGE, Ncurses::KEY_PPAGE
      if ch == Ncurses::KEY_NPAGE
        @toprow += height
      else
        @toprow -= height
      end
      @toprow = 0 if @toprow < 0 #The opposite case is handled inside bounds_check
      @oldrow = @current_index
      @current_index = @toprow
      bounds_check
      @repaint_required = true
      @widget_scrolled = true
    else
      super
    end
  end

  def on_enter_row arow
    super
    if current_value[1] == FILE_MARKER
      if @current_index > @oldrow
        if next_row == :NO_NEXT_ROW
          previous_row
        end
      elsif @current_index < @oldrow
        if previous_row == :NO_PREVIOUS_ROW
          next_row
        end
      end
    end
  end

  def goto_top
    @current_index = -1
    super
  end
end

