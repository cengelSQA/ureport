require 'optionparser'

module Options

	VALID_ATTR = ['id', 'url', 'email', 'key']

	def self.parse
		@config = 'config.yml'
		@options = {}
		OptionParser.new do |opts|
			opts.banner = "Usage: ureport [OPTIONS]"

			opts.on('-u=', '--url=', 'Testrail URL') do |u|
				@options['url'] = u
			end

			opts.on('-e=', '--email=', 'Testrail user email') do |e|
				@options['email'] = e	
			end

			opts.on('-k=', '--key=', 'Testrail user API key') do |k|
				@options['key'] = k
			end

			opts.on('-i=', '--id=', 'Testrail plan or run id') do |i|
				@options['id'] = i
			end
		end.parse!
		merge_config
		validate
		@options['id'] = @options['id'].gsub('R', '')
		@options
	end

	private
	# Pull in any options defined in config file. CLI options overwrite config options.
	def self.merge_config
		if File.exist? @config
			@options = YAML.load_file(@config).merge! @options
		end
	end

	def self.validate
		VALID_ATTR.each do |attr|
			if @options[attr].nil?
				puts "Missing option '#{attr}'" 
				exit
			end
		end
		
	end
end
