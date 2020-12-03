require 'benchmark'
require 'csv'

image_details = CSV.read("image_details.csv")
puts Benchmark.realtime(){
  image_details.each do |row|
    puts row[0]
    `curl -s -o /dev/null "#{row[1]}"`
  end
}
