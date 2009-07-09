class FeedFunnel::DirectMatchFunnel < Funnel
  def similar?(item, f_item)
    self.field_from(item) == self.field_from(f_item)
  end
end

