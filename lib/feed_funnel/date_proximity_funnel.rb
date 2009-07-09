class FeedFunnel::DateProximityFunnel < Funnel
  def similar?(item, f_item)
    master_date = DateTime.parse(self.field_from(item)).to_time
    other_date  = DateTime.parse(self.field_from(f_item)).to_time

    (master_date - other_date).abs <= 10 * 60
  rescue
    false
  end
end

