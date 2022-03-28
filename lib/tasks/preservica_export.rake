# frozen_string_literal: true

# Example:  rake preservica:export_tree[structural_object/d1dc8009-e39e-44bc-bee9-f46637981e08,Preservation-1,brbl]
# rubocop:disable  Metrics/BlockLength
namespace :preservica do
  desc "Export tree of preservica objects"
  task :export_tree, [:uri, :representation_name, :admin_set_key] => :environment do |_task, args|
    Rails.logger = Logger.new(STDOUT)
    root_object_id = (args[:uri].split('/')[-1]).to_s
    if args[:uri].include?("structural_object")
      pattern = :pattern_one
      destination = "preservica_export/StructuralObject-#{root_object_id}"
      structural_object = Preservica::StructuralObject.where(admin_set_key: args[:admin_set_key], id: root_object_id)
      information_objects = structural_object.information_objects
    elsif args[:uri].include?("information_object")
      pattern = :pattern_two
      destination = "preservica_export/InformationObject-#{root_object_id}"
      information_objects = [Preservica::InformationObject.where(admin_set_key: args[:admin_set_key], id: root_object_id)]
    else
      raise StandardError, "Invalid URI: #{args[:uri]}"
    end
    exporter = PreservicaExporter.new(destination)
    FileUtils.mkdir_p destination.to_s
    Rails.logger.info("Writing XML files to #{destination}")
    time = Benchmark.measure do
      exporter.write_object_to_file(structural_object, "0000") if pattern == :pattern_one
      exporter.write_information_objects(information_objects, args[:representation_name], pattern)
    end
    Rails.logger.info("#{exporter.file_count} files written.")
    Rails.logger.info("Completed in #{time.real} seconds.")
  end

  class PreservicaExporter
    attr_reader :file_count
    attr_reader :destination

    def initialize(destination)
      @destination = destination
      @file_count = 0
    end

    def write_information_objects(information_objects, representation_name, pattern)
      information_objects.each_with_index do |information_object, index1|
        index = index1.to_s.rjust(4, '0').to_s
        write_object_to_file(information_object, index)
        representation = information_object.fetch_by_representation_name(representation_name)[0]
        write_object_to_file(representation, index)
        content_objects = representation.content_objects
        Rails.logger.info("Warning!! Multiple content objects found for pattern one for InformationObject #{information_object.id}") if pattern == :pattern_one && content_objects.count > 1
        write_content_objects(content_objects, index)
      end
    end

    def write_content_objects(content_objects, index_prefix)
      content_objects.each_with_index do |content_object, index1|
        index = "#{index_prefix}-#{index1.to_s.rjust(4, '0')}"
        write_object_to_file(content_object, index)
        generations = content_object.active_generations
        Rails.logger.info("\n\nWarning!! Multiple active generations for content object: #{content_object.id}\n") if generations.count > 1
        write_generations(content_object, generations, index)
      end
    end

    def write_generations(content_object, generations, index_prefix)
      generations.each_with_index do |generation, index1|
        index = "#{index_prefix}-#{index1.to_s.rjust(4, '0')}"
        write_object_to_file(generation, index)
        bitstreams = generation.bitstreams
        Rails.logger.info("\n\nWarning!! Multiple bitstreams for content_object: #{content_object.id} with generation #{generation.id} at index #{index3}\n") if bitstreams.count > 1
        write_bitstreams(bitstreams, index)
      end
    end

    def write_bitstreams(bitstreams, index_prefix)
      bitstreams.each_with_index do |bitstream, index1|
        index = "#{index_prefix}-#{index1.to_s.rjust(4, '0')}"
        write_object_to_file(bitstream, index)
      end
    end

    def write_object_to_file(object, index)
      filename = "#{destination}/#{object.class.name.gsub('Preservica::', '')}_#{index}_#{object.id}.xml"
      Rails.logger.debug("Writing to file #{filename}")
      File.open(filename, "w") { |f| f.write object.xml }
      @file_count += 1
    end
  end
end
# rubocop:enable  Metrics/BlockLength
