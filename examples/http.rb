require 'bundler'
Bundler.setup

require 'eff'
require 'json'
require 'faraday'

module Http
  Get = Struct.new(:url)

  def self.get(url)
    Eff.send Get.new(url)
  end

  def self.run(effect)
    case effect
    when Eff::Impure
      if effect.v.class == Http::Get
        conn = Faraday.new(:url => 'http:/') do |faraday|
          faraday.adapter Faraday.default_adapter
        end
        result = conn.get effect.v.url
        run(effect.k.call(JSON.parse(result.body)))
      else
        Eff::Impure.new(effect.v, -> (x) { run(effect.k.call(x)) })
      end
    when Eff::Pure
      effect
    end
  end

  def self.run_cached(effect, cache=[])
    runner = lambda { |effect, cache|
      case effect
      when Eff::Impure
        request = effect.v
        if request.class == Http::Get
          if cached = cache[request.url]
            runner.call(effect.k.call(cached), cache)
          else
            conn = Faraday.new(:url => 'http:/') do |faraday|
              faraday.adapter Faraday.default_adapter
            end
            result = JSON.parse(conn.get(request.url).body)
            runner.call(effect.k.call(result), cache.merge({request.url => result}))
          end
        else
          Eff::Impure.new(effect.v, -> (x) { runner.call(effect.k.call(x), cache) })
        end
      when Eff::Pure
        effect
      end
    }

    runner.call(effect, {})
  end
end

module Github
  GetRepoCount = Struct.new(:user_id)
  GetLocation = Struct.new(:user_id)

  def self.get_repo_count(user_id)
    Eff.send(GetRepoCount.new(user_id))
  end

  def self.get_location(user_id)
    Eff.send(GetLocation.new(user_id))
  end

  def self.run(effect)
    case effect
    when Eff::Impure
      if effect.v.class == Github::GetLocation
        run(Http.get("https://api.github.com/users/#{effect.v.user_id}").bind do |result|
          effect.k.call(result["location"])
        end)
      elsif effect.v.class == Github::GetRepoCount
        run(Http.get("https://api.github.com/users/#{effect.v.user_id}").bind do |result|
          effect.k.call(result["public_repos"])
        end)
      else
        Eff::Impure.new(effect.v, -> (x) { run(effect.k.call(x)) })
      end
    when Eff::Pure
      effect
    end
  end
end

def report_for(name)
  Github.get_repo_count(name).bind do |count|
    Github.get_location(name).bind do |location|
      Eff::FEFree.return "location: #{location}, repo count: #{count}"
    end
  end
end

# Running the report calls the same GitHub endpoint twice.
puts Eff.run(Http.run(Github.run(report_for(ARGV.first))))

# Simply replacing the Http effect handler with a cached version avoids this problem.
# puts Eff.run(Http.run_cached(Github.run(report_for(ARGV.first))))
