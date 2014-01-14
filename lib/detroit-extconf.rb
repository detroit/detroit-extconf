require 'detroit-standard'

module Detroit

  ##
  # The ExtConf tool utilizes extconf.rb script and Autotools standard Makefile
  # to compile native extensions.
  #
  # Targets the following standard toolchain stations:
  #
  # * compile
  # * clean
  # * purge
  #
  # @note By neccessity this tool shells out to the command line.
  #
  # @todo Can we implement a win32 cross-compile?
  class ExtConf < Tool

    # Works with the Standard assembly.
    #
    # @!parse
    #   include Standard
    #
    assembly Standard

    # Location of manpage for tool.
    MANPAGE = File.dirname(__FILE__) + '/../man/detroit-dnote.5'

    # Platform specific make command.
    MAKE_COMMAND = ENV['make'] || (RUBY_PLATFORM =~ /(win|w)32$/ ? 'nmake' : 'make')

    # Set attribute defaults.
    #
    # @return [void]
    def prerequisite
      @static = false
    end

    # Compile statically? Applies only to compile method. (false)
    attr_accessor :static

    # Create Makefile(s).
    #
    # @return [void]
    def configure
      extensions.each do |directory|
        next if File.exist?(File.join(directory, 'Makefile'))
        report "configuring #{directory}"
        cd(directory) do
          sh "ruby extconf.rb"
        end
      end
    end

    # Compile extensions.
    def compile
      configure
      if static
        make 'static'
      else
        make
      end
    end

    # Remove enough compile products for a clean compile.
    def clean
      make 'clean'
    end

    # Remove all compile products.
    def distclean
      make 'distclean'
      extensions.each do |directory|
        makefile = File.join(directory, 'Makefile')
        rm(makefile) if File.exist?(makefile)
      end
    end

    alias purge distclean

    # Check to see if this project has extensions that need to be compiled.
    def compiles?
      !extensions.empty?
    end

    alias compile? compiles?
    alias clean?   compiles?
    alias purge?   compiles?

    # Extension directories. Often this will simply be 'ext'.
    # but sometimes more then one extension is needed and are kept
    # in separate directories. This works by looking for ext/**/*.c
    # files, where ever they are is considered an extension directory.
    def extensions
      @extensions ||= Dir['ext/**/*.c'].collect{ |file| File.dirname(file) }.uniq
    end

    # @todo 
    # def current?
    # end

    # This tool ties into the `compile`, `clean` and `purge` stations of the
    # standard assembly.
    #
    # @return [Boolean]
    def assemble?(station, options={})
      return true if station == :compile
      return true if station == :clean
      return true if station == :purge
      return false
    end

  private

    #
    def make(target='')
      extensions.each do |directory|
        report "compiling #{directory}"
        cd(directory) do
          shell "#{MAKE_COMMAND} #{target}"
        end
      end
    end

    # Eric Hodel said NOT to copy the compiled libs.
    #
    #task :copy_files do
    #  cp "ext/**/*.#{dlext}", "lib/**/#{arch}/"
    #end
    #
    #def dlext
    #  Config::CONFIG['DLEXT']
    #end
    #
    #def arch
    #  Config::CONFIG['arch']
    #end

    # Cross-compile for Windows. (TODO)

    #def make_mingw
    #  abort "NOT YET IMPLEMENTED"
    #end

  end

end
