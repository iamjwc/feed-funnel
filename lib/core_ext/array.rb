class Array
  def mean
    self.inject(0) {|n, i| n + i } / self.size.to_f
  end

  def standard_deviation(mean = nil)
    mean ||= self.mean

    Math.sqrt(self.map {|i| (i - mean) ** 2 }.mean)
  end
end

