require 'bundler'
Bundler.setup

require 'eff'
require 'json'
require 'faraday'

require_relative './tty'

module Http
  Get = Struct.new(:url)

  def self.get(url)
    Eff.send Get.new(url)
  end

  def self.run(effect)
    Eff::EffectHandler.new
      .on_impure(Http::Get) do |request, k|
        conn = Faraday.new(:url => 'http:/') do |faraday|
          faraday.adapter Faraday.default_adapter
        end
        result = conn.get request.url
        k.call(JSON.parse(result.body))
      end
      .run(effect)
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
    Eff::EffectHandler.new
      .on_impure(Github::GetLocation) do |request, k|
        Http.get("https://api.github.com/users/#{request.user_id}").bind do |result|
          k.call(result["location"])
        end
      end
      .on_impure(Github::GetRepoCount) do |request, k|
        Http.get("https://api.github.com/users/#{request.user_id}").bind do |result|
          k.call(result["public_repos"])
        end
      end
      .run(effect)
  end
end

def user_report_for(name)
  Github.get_repo_count(name).bind do |count|
    Github.get_location(name).bind do |location|
      Eff::FEFree.return "location: #{location}, repo count: #{count}"
    end
  end
end

def print_report(name)
  user_report_for(name).bind do |string|
    TTY.put string
  end
end

def map_m(monad_type, array)
  monad = monad_type.return(nil)
  array.each do |e|
    monad = monad >> yield(e)
  end
  monad
end

def print_reports(names)
  map_m(Eff::FEFree, names) do |name|
    print_report(name)
  end
end

# Printing the report calls the same GitHub endpoint twice.
Eff.run(Http.run(Github.run(TTY.run_io(print_reports(ARGV)))))

# Simply replacing the Http effect handler with a cached version avoids this problem.
Eff.run(Http.run_cached(Github.run(TTY.run_io(print_reports(ARGV)))))
