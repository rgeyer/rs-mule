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

module RsMule
  class RunExecutable

    attr_accessor :right_api_client

    # Initializes a new RunExecutable
    #
    # @param [RightApi::Client] right_api_client An instantiated and authenticated
    #   RightApi::Client instance which will be used for making the request(s)
    def initialize(right_api_client)
      @right_api_client = right_api_client
    end

    # Runs a RightScript or Chef Recipe on all instances which have all of the
    # specified tags.
    #
    # @param [String|Array<String>] tags An array of tags.  If a string is
    #   supplied it will be converted to an array of Strings.
    # @param [String] executable RightScript name or href, or the name of a
    #   recipe.  This method will attempt to auto detect which it is, or you
    #   can be friendly and provide a hint using the executable_type option.
    # @param [Hash] options A list of options where the possible values are
    #   - executable_type: One of ["auto","right_script_name","right_script_href","recipe_name"].  When set
    #     to "auto" we will attempt to determine if an executable is a recipe,
    #     a RightScript name, or a RightScript href. Defaults to "auto"
    #   - right_script_revision: When a RightScript name or href is specified,
    #     this can be used to declare the revision to use.  Can be a specific
    #     revision number or "latest".  Defaults to "latest"
    #   - tag_match_strategy: If multiple tags are specified, this will
    #     determine how they are matched.  When set to "all" instances with all
    #     tags will be matched.  When set to "any" instances with any of the
    #     provided tags will be matched.  Defaults to "all"
    # @raise [RightScriptNotFound] If the specified RightScript lineage does
    #   not exist, or the specified revision is not available.
    def run_executable(tags, executable, options={})
      options = {
          :executable_type => "auto",
          :right_script_revision => "latest",
          :tag_match_strategy => "all"
      }.merge(options)
      execute_params = {}
      tags = [tags] unless tags.is_a?(Array)

      case options[:executable_type]
        when "right_script_href"
          execute_params[:right_script_href] = executable
        when "right_script_name"
          scripts = find_right_script_lineage_by_name(executable)
          execute_params[:right_script_href] = right_script_revision_from_lineage(scripts, options[:right_script_revision]).href
        when "recipe_name"
          execute_params[:recipe_name] = executable
        when "auto"
          is_recipe = executable =~ /.*::.*/
          is_href = executable =~ /^\/api\/right_scripts\/[a-zA-Z0-9]*/
          if is_recipe
            execute_params[:recipe_name] = executable
          else
            if is_href
              execute_params[:right_script_href] = executable
            else
              scripts = find_right_script_lineage_by_name(executable)
              execute_params[:right_script_href] = right_script_revision_from_lineage(scripts, options[:right_script_revision]).href
            end
          end
        else
          raise ArgumentError.new("Unknown executable_type (#{options[:executable_type]})")
      end

      resources_by_tag = @right_api_client.tags.by_tag(
          :resource_type => "instances",
          :tags => tags,
          :match_all => options[:tag_match_strategy] == "all" ? "true" : "false"
      )

      resources_by_tag.each do |res|
        instance = @right_api_client.resource(res.links.first["href"])
        instance.run_executable(execute_params)
      end
    end

    private

    # Fetches the entire lineage (all revisions) of a RightScript when provided
    # with it's name
    #
    # @param [String] name The name (or partial name) of the RightScript
    # @return [Array<RightApi::Resource>] An array of RightApi::Resource objects
    #   of media type RightScript[http://reference.rightscale.com/api1.5/media_types/MediaTypeRightScript.html]
    # @raise [RightScriptNotFound] If a lineage of RightScripts with the specified
    #   name is not found.
    def find_right_script_lineage_by_name(name)
      lineage = @right_api_client.right_scripts(:filter => ["name==#{name}"]).index
      if lineage.length == 0
        raise Exception::RightScriptNotFound.new("No RightScripts with the name (#{name}) were found.")
      end
      lineage
    end

    # Gets the specified revision of a RightScript from it's lineage
    #
    # @param [Array<RightApi::Resource>] An array of RightApi::Resource objects
    #   of media type RightScript[http://reference.rightscale.com/api1.5/media_types/MediaTypeRightScript.html]
    # @param [String] An optional parameter for the desired lineage.  When set
    #   to "latest" it will get the highest number committed revision. Specify
    #   0 for the head revision.
    # @raise [RightScriptNotFound] If the specified revision is not in the lineage
    def right_script_revision_from_lineage(lineage, revision="latest")
      right_script = nil
      if revision == "latest"
        latest_script = lineage.max_by{|rs| rs.revision}
        right_script = latest_script
      else
        desired_script = lineage.select{|rs| rs.revision == revision}
        if desired_script.length == 0
          raise Exception::RightScriptNotFound.new("RightScript revision (#{revision}) was not found. Available revisions are (#{lineage.map{|rs| rs.revision}})")
        end
        right_script = desired_script.first
      end
      right_script
    end
  end
end