$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'pry'
require 'httparty'

require "issues/version"

module Issues
  class Github
    include HTTParty
    base_uri 'https://api.github.com'
    basic_auth ENV['GH_USER'], ENV['GH_PASS']

    def list_teams(org_id)
      self.class.get("/orgs/#{org_id}/teams")
    end

    def list_members(team_id)
      self.class.get("/teams/#{team_id}/members")
    end
  end
end

binding.pry
