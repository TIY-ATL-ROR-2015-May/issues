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

    def get_team_by_name(org_id, team_name)
      teams = self.list_teams(org_id)
      team = teams.find { |x| x['name'] == team_name }
      self.list_members(team['id'])
    end

    def get_gist(gist_id)
      self.class.get("/gists/#{gist_id}")
    end

    def get_gist_content(gist_id)
      response = self.get_gist(gist_id)
      response['files'].values.first['content']
    end

    def create_issue
    end
  end
end

binding.pry
