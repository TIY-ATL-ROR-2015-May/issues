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

    def list_followers(user, page=1)
      options = { query: { page: page } }
      self.class.get("/users/#{user}/followers", options)
    end

    def list_all_followers(user)
      followers = []
      page = 1
      response = self.list_followers(user, page)
      until response.length == 0
        followers += response
        page += 1
        response = self.list_followers(user, page)
      end
      followers
    end

    def get_page_count(response)
      response.headers['link'].split(', ').find do |link|
        link.match(/rel=\"last\"/)
      end.match(/page=(\d+)/)[1].to_i
    end

    def list_issues(owner, repo)
      params = {
        sort: 'created', # Could also be updated or comments.
        direction: 'desc' # Could also be 'asc'.
      }
      options = { query: params }
      self.class.get("repos/#{owner}/#{repo}/issues", options)
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

    def create_comment(owner, repo, issue_id, comment)
      params = {
        body: comment
      }
      options = { body: params.to_json }
      self.class.post("/repos/#{owner}/#{repo}/issues/#{issue_id}/comments", options)
    end

    def create_issue(owner_id, repo_id, title, body=nil, assignee=nil)
      params = {
        title: title,
        body: body,
        assignee: assignee
      }
      options = { body: params.to_json }
      self.class.post("/repos/#{owner_id}/#{repo_id}/issues", options)
    end
  end

  class App
    def initialize
      @github = Github.new
    end

    def prompt(question, validator)
      puts question
      input = gets.chomp
      until input =~ validator
        puts "Sorry, I didn't understand that."
        puts question
        input = gets.chomp
      end
      input
    end

    def confirm?(question)
      answer = prompt(question, /^[yn]$/i)
      answer.upcase == 'Y'
    end

    def assign_homework
      course = prompt("What class (Github Org) would you like to assign
                       homework for?", /^[\w\-]+$/)
      repo = prompt("What repo do you use to track homework?", /^\w+$/)
      team = prompt("What team are your students on?", /^\w+$/)
      title = prompt("What is the title of this homework?", /^[\w\-\ ]+$/)
      gist_id = prompt("What is the Gist Id for this homework issue?",
                       /^[0-9a-f]{20}$/)

      body = @github.get_gist_content(gist_id)
      students = @github.get_team_by_name(course, team)
      students.each do |student|
        @github.create_issue(course, repo, title,
                             body, student['login'])
      end
    end
  end
end

binding.pry
