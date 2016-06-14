require_relative 'testrail-api/ruby/testrail'

class Report

	STATUSES = {
		1 => :passed,
		2 => :blocked,
		3 => :untested,
		4 => :retest,
		5 => :failed,
		6 => :skipped
	}


	def initialize(config)
		@email = config['email']
		@url = config['url']
		@key = config['key']
		@id = config['id']
		@client = setup_api
		@is_plan = false
		test
	end

	def summary
		puts "Reporting '#{test_name}' results for user '#{user['name']}':"
		report = {passed: 0, blocked: 0, failed: 0, retest: 0, skipped: 0}
		if @is_plan
			results.each do |run|
				run.each_with_object(report) do |result, hash|
					next if result['status_id'].nil?
					next unless result['created_by'] == user['id']
					hash[STATUSES[result['status_id']]] += 1
				end
			end
		else
			results.each_with_object(report) do |result, hash|
				next if result['status_id'].nil?
				next unless result['created_by'] == user['id']
				hash[STATUSES[result['status_id']]] += 1
			end

		end
		report.each_pair do |key, value|	
			puts "\t#{key.capitalize}: #{value}"
		end
		puts "\tTotal: #{report.values.inject(:+)}"
	end

	private
	def results
		return @results unless @results.nil?
		@results = []
		if @is_plan
			test['entries'].each do |entry|
				entry['runs'].each do |run|
					@results << @client.send_get("get_results_for_run/#{run['id']}")
				end
			end
		else
			@results = test	
		end
		@results
	end

	def test
		return @test unless @test.nil?
		begin
			@test = @client.send_get("get_results_for_run/#{@id}")
		rescue TestRail::APIError => e
			if e.message == 'TestRail API returned HTTP 400 ("Field :run_id is not a valid test run.")'
				@is_plan = true
				@test = @client.send_get("get_plan/#{@id}")
			else
				raise e
			end
		end
	end

	def setup_api
		client = TestRail::APIClient.new(@url)
		client.user = @email
		client.password = @key
		client
	end

	def test_name
		if @is_plan
			test['name']
		else
			@client.send_get("get_run/#{@id}")['name']
		end
	end

	def user
		@user ||= @client.send_get "get_user_by_email&email=#{@email}"
	end
end
