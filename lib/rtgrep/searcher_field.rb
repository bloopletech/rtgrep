class SearcherField < RubyCurses::Field
  def searcher_list(list)
    @searcher_list = list
  end

  def handle_key(ch)
    if ((32..126).to_a + @key_handler.keys + [13]).include?(ch)
      super
    else
      @searcher_list.handle_key(ch)
      focus
    end
  end
end

