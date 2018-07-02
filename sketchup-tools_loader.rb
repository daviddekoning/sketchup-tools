require "sketchup.rb"
require "extensions.rb"

# Load plugin as extension (so that user can disable it)

module DKS
    def self.reload
        original_verbose = $VERBOSE
        $VERBOSE = nil
        pattern = File.join(__dir__, '**/*.rb')
        Dir.glob(pattern).each { |file| load file }.size
        # Cannot use `Sketchup.load` because its an alias for `Sketchup.require`.
    ensure
        $VERBOSE = original_verbose
    end
end

cutlist_loader = SketchupExtension.new "My_Plugin Loader", "cutlist/cutlist.rb"
cutlist_loader.copyright= "Copyright 2017-2018 David de Konign"
cutlist_loader.creator= "David de Koning"
cutlist_loader.version = "0.1"
cutlist_loader.description = "counts dimensional lumber and sheet goods in a sketchup model."
Sketchup.register_extension cutlist_loader, true