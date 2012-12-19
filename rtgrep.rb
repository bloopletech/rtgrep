#!/usr/bin/env ruby

$datacolor = $normalcolor = $def_fg_color = 238
$def_bg_color = 16

require 'rbcurse'
require 'rbcurse/core/util/app'


$datacolor = $normalcolor = $def_fg_color = 238
$def_bg_color = 16


class Searcher
  def initialize(haystack)
    @haystack = haystack
  end

  def self.from_ctagsxy(lines)
    Searcher.new(lines.map { |l| l.split("\t") })
  end

  def search(needle)
    needle_parts = needle.split("").map do |c|
      c = Regexp.escape(c)
      "#{c}[^#{c}]*?"
    end.join
    needle_regex = Regexp.new(needle_parts, "i")
    #needle_regex = Regexp.new(needle.split("").map { |c| "#{c}?[^#{c}]*?" }.join, "i")
    @haystack.select { |line| line[0] =~ needle_regex }.sort_by do |line|
      shortest_match = nil
      line[0].to_enum(:scan, needle_regex).map do
        match_data = Regexp.last_match
        offset = match_data.offset(0)
        if !shortest_match || ((offset[1] - offset[0]) < (shortest_match[1] - shortest_match[0]))
          shortest_match = offset
        end
      end

      ((shortest_match[0]) * 1.0) + ((shortest_match[1] - shortest_match[0]) * 0.5) + ((line[0].length) * 0.3)
    end
  end

  def all
    @haystack
  end
end

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
end

class SearcherListCellRenderer < RubyCurses::ListCellRenderer
  def repaint graphic, r=@row,c=@col, row_index=-1,value=@text, focussed=false, selected=false
    if focussed
      offset = 236
      attr_offset = Ncurses::A_NORMAL
    else
      offset = 0
      attr_offset = Ncurses::A_NORMAL
    end

    blank = Chunks::Chunk.new(ColorMap.get_color(252, offset), ' ', attr_offset)

    chunks = Chunks::ChunkLine.new
    chunks << Chunks::Chunk.new(ColorMap.get_color(252, offset), value[0], Ncurses::A_BOLD)
    chunks << blank
    chunks << Chunks::Chunk.new(ColorMap.get_color(252, offset), value[1], attr_offset)
    chunks << blank
    chunks << Chunks::Chunk.new(ColorMap.get_color(245, offset), value[2], attr_offset)
    chunks << blank
    chunks << Chunks::Chunk.new(ColorMap.get_color(245, offset), value[3], attr_offset)
    chunks << Chunks::Chunk.new(ColorMap.get_color(252, offset), " " * (@display_length - chunks.length), attr_offset)
    
  
    graphic.wmove r, c
    graphic.show_colored_chunks chunks, ColorMap.get_color(238), nil
  end
end

App.new do
  selected_tag = [""]

  at_exit do
    STDERR.print "#{selected_tag[2]}\n#{selected_tag[3]}\n#{selected_tag[1]}\n#{selected_tag[0]}\n" if selected_tag
  end

  @default_prefix = " "

  searcher = Searcher.from_ctagsxy(File.readlines(ARGV.first).map { |s| s.chomp })

  stack :margin_top => 0, :width => :expand, :height => FFI::NCurses.LINES, :color => $normalcolor, :bgcolor => $def_bg_color do
    $key_map = :neither
    results_box = SearcherList.new(nil, :list => searcher.all, :width => :expand, :height => FFI::NCurses.LINES - 2, :selection_mode => :single, :suppress_borders => true)
    _position(results_box)
    results_box.instance_variable_set("@display_length", 9001)
    results_box.cell_renderer(SearcherListCellRenderer.new(:display_length => results_box.width))
    results_box.bind(:PRESS) do
      selected_tag = results_box.current_value
      throw(:close)
    end
    label :text => " ", :width => :expand, :height => 1
    search_box = field :label => "Search >"
    search_box.bind(:CHANGE) do
      results_box.list(searcher.search(search_box.getvalue)) if search_box.getvalue.length >= 3
    end
    search_box.bind_key(13) do
      selected_tag = results_box.current_value
      throw(:close)
    end
    search_box.bind_key(2727) do
      selected_tag = nil
      throw(:close)
    end
    results_box.bind(2727) do
      selected_tag = nil
      search_box.focus
      search_box.cursor_end
    end

    search_box.focus
    search_box.cursor_home
  end
end
