class PaginationHelper
  attr_reader :page, :items, :count, :pages, :prev, :next

  def initialize(count:, page: 1, items: 25)
    @count = count
    @page = page.to_i
    @items = items.to_i
    @pages = (@count.to_f / @items).ceil
    @prev = @page > 1 ? @page - 1 : nil
    @next = @page < @pages ? @page + 1 : nil
  end
end
