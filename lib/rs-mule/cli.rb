# Copyright (c) 2014 Ryan Geyer
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'yaml'

module RsMule
  class Cli < Thor
    no_commands {
      def get_right_api_client()
        client_auth_params = {}
        thor_shell = Thor::Shell::Color.new
        unless @options.keys.include?('rs_auth_file') | @options.keys.include?('rs_auth_hash')
          message = <<EOF
You must supply right_api_client authentication details as either a hash or
a yaml authentication file!
EOF
          thor_shell.say(thor_shell.set_color(message, :red))
          exit 1
        end
        if @options[:rs_auth_file]
          client_auth_params = YAML.load_file(@options[:rs_auth_file])
        end

        if @options[:rs_auth_hash]
          client_auth_params = options[:rs_auth_hash]
        end

        RightApi::Client.new(client_auth_params)
      end
    }

    desc "run_executable", "Runs a specified recipe or RightScript on instances targeted by tag"
    option :rs_auth_hash, :type => :hash, :desc => "A hash of right_api_client auth parameters in the form (email:foo@bar.baz password:password account_id:12345)"
    option :rs_auth_file, :desc => "A yaml file containing right_api_client auth parameters to use for authentication"
    option :tags, :type => :array, :required => true
    option :tag_match_strategy, :desc => "If multiple tags are specified, this will determine how they are matched.  When set to \"all\" instances with all tags will be matched.  When set to \"any\" instances with any of the provided tags will be matched.  Defaults to \"all\""
    option :executable_type, :desc => "What value is being provided for the executable parameter. One of [auto|right_script_name|right_script_href|recipe_name]"
    option :right_script_revision, :desc => "When a RightScript name is provided, this can be used to specify which revision to use.  If not provided the latest revision will be used."
    def run_executable(executable)
      client = get_right_api_client

      mule = RsMule::RunExecutable.new(client)
      mule.run_executable(@options[:tags], executable, @options)
    end
  end
end