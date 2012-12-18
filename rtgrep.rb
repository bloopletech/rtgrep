#!/usr/bin/env ruby

$datacolor = $normalcolor = $def_fg_color = 238
$def_bg_color = 16

require 'rbcurse'
require 'rbcurse/core/util/app'


class Searcher
  def initialize(haystack)
    @haystack = haystack
  end

  def self.from_ctagsxy(lines)
    Searcher.new(lines.map { |l| l.split("\t") })
  end

  def search(needle)
    needle_regex = Regexp.new(needle.split("").map { |c| "#{c}[^#{c}]*?" }.join, "i")
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
  def convert_value_to_text(value, row)
    value.join(" ")
  end
end

$datacolor = $normalcolor = $def_fg_color = 238
$def_bg_color = 16


App.new do
  selected_tag = [""]

  at_exit do
    STDERR.print "#{selected_tag[2]}\n#{selected_tag[3]}\n#{selected_tag[1]}\n#{selected_tag[0]}\n" if selected_tag
  end

  @default_prefix = " "

  searcher = Searcher.from_ctagsxy(File.readlines(ARGV.first).map { |s| s.chomp })

  stack :margin_top => 0, :width => :expand, :height => FFI::NCurses.LINES, :color => $normalcolor, :bgcolor => $def_bg_color do
    results_box = SearcherList.new(nil, :list => searcher.all, :width => :expand, :height => FFI::NCurses.LINES - 2, :selection_mode => :single, :suppress_borders => true)
    _position(results_box)
    results_box.instance_variable_set("@display_length", 9001)
    results_box.bind(:PRESS) do
      selected_tag = results_box.current_value
      throw(:close)
    end
    label :text => " ", :width => :expand, :height => 1
    search_box = field :label => "Search >"
    search_box.bind(:CHANGE) do
      results_box.list(searcher.search(search_box.getvalue))
    end
    search_box.bind_key(13) do
      selected_tag = results_box.current_value
      throw(:close)
    end
    search_box.focus
    search_box.cursor_home
  end
end
