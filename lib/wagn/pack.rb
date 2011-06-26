

module Wagn::Pack
  mattr_accessor :dirs

  class << self
    def included(base) load_all end
    def dirs() @@dirs ||= [] end

    def dir(newdir)
      dirs << newdir
      #STDERR << "dir[#{dirs.inspect}]\n"
      @@dirs
    end

    def load_all 
      Rails.logger.info "load_all available_modules = #{@@dirs.inspect}\n"
      if dirs.empty?
        #STDERR << "No mods registered: #{Kernel.caller*"\n"}"
      end
      dirs.each do |dir|
        #STDERR << "Mods: #{Dir[dir].inspect}\n"
        Dir[dir].each do |file|
          begin
            #STDERR << "loading mods #{file}\n"
            require_dependency file  #"#{RAILS_ROOT}/modules/#{module_name}"
          rescue Exception=>e
            detail = e.backtrace.join("\n")
            raise "Error loading #{file} #{e.message}\n#{detail}"
          end
        end
      end
    end
  end
end

#STDERR << "\n---- Pack loaded, load card? #{Module.const_defined?(:Card)} ---\n\n"
#require 'card'
