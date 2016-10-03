module RacersHelper
  def toRacer(value)
    r = value.is_a?(Racer) ? value : Racer.new(value)
    r
  end
end
