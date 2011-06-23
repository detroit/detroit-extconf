module Detroit

  #
  def ExtConf(options={})
    ExtConf.new(options)
  end

  # The ExtConf tool utilizes extconf.rb script and Autotools standard Makefile
  # to compile native extensions.
  #
  # NOTE: By neccessity this tool shells out to the command line.
  #
  #--
  # TODO: win32 cross-compile ?
  # TODO: current? method
  #++
  class ExtConf < Tool

    #def self.available?
    #  #... check for make tools ...
    #end

    #
    MAKE_COMMAND = ENV['make'] || (RUBY_PLATFORM =~ /(win|w)32$/ ? 'nmake' : 'make')

    # Compile statically? Applies only to compile method. (false)
    attr_accessor :static

    #
    def initialize_defaults
      @static = false
    end

    # Check to see if this project has extensions that need to be compiled.
    def compiles?
      !extensions.empty?
    end

    # Extension directories. Often this will simply be 'ext'.
    # but sometimes more then one extension is needed and are kept
    # in separate directories. This works by looking for ext/**/*.c
    # files, where ever they are is considered an extension directory.
    def extensions
      @extensions ||= Dir['ext/**/*.c'].collect{ |file| File.dirname(file) }.uniq
    end

    # Create Makefile(s).
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

    alias_method :purge, :distclean

    #
    def assembly_compile
      compile
    end

    #
    def assembly_clean
      clean
    end

    #
    def assembly_purge
      purge
    end

    private

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
