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

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'helper'))

describe RsMule::RunExecutable do
  # Mocks success with the simplest request.  Namely request with a single tag,
  # a recipe name, and no inputs
  #
  # @return A flexmock of RightApi::Client that expects all the right stuff.
  def mockTheHappyPath(options={})
    options = {
        :mock_run_executable => true,
        :match_all => "true"
    }.merge(options)
    by_tag_flexmock = flexmock("by_tag")
    by_tag_flexmock
    .should_receive("by_tag")
    .with(:resource_type => "instances", :tags => ["foo"], :match_all => options[:match_all])
    .and_return([flexmock(:links => [{"rel" => "resource", "href" => "/api/clouds/1/instances/abc123"}])])

    instance_flexmock = flexmock(:href => "/api/clouds/1/instances/abc123")
    instance_flexmock.should_receive("run_executable") if options[:mock_run_executable]

    flexmock(:tags => by_tag_flexmock, :resource => instance_flexmock)
  end

  def mockRightScriptLookup(client)
    client
    .should_receive("right_scripts")
    .once
    .and_return(flexmock(:index => [
        flexmock(:href => "href1", :revision => 1),
        flexmock(:href => "href2", :revision => 2)
    ]))
    client
  end

  describe "#run_executable" do

    context "when string is supplied for tags" do
      it "converts it to an array of tags" do
        client = mockTheHappyPath
        re = RsMule::RunExecutable.new(client)
        re.run_executable("foo", "cookbook::recipe")
      end
    end

    context "when string is supplied for update_inputs" do
      it "converts it to an array" do
        client = mockTheHappyPath
        instance_inputs_mock = flexmock("instance.inputs")
        instance_inputs_mock.should_receive("multi_update").once.with(:inputs => {"foo" => "text:barbaz"})
        client.resource.should_receive("inputs").and_return(instance_inputs_mock)

        re = RsMule::RunExecutable.new(client)
        re.run_executable("foo", "cookbook::recipe", :inputs => {"foo" => "text:barbaz"}, :update_inputs => "current_instance")
      end
    end

    context "when executable type option is auto" do
      it "detects RightScript name and looks up href" do
        client = mockTheHappyPath(:mock_run_executable => false)
        client = mockRightScriptLookup(client)
        client.resource
          .should_receive("run_executable")
          .once
          .with(:right_script_href => "href2")

        re = RsMule::RunExecutable.new(client)
        re.run_executable("foo", "barbaz")
      end

      it "detects RightScript href and uses it" do
        client = mockTheHappyPath(:mock_run_executable => false)
        client.resource
        .should_receive("run_executable")
        .once
        .with(:right_script_href => "/api/right_scripts/abc123")

        re = RsMule::RunExecutable.new(client)
        re.run_executable("foo", "/api/right_scripts/abc123")
      end

      it "detects recipe" do
        client = mockTheHappyPath(:mock_run_executable => false)
        client.resource
        .should_receive("run_executable")
        .once
        .with(:recipe_name => "cookbook::recipe")

        re = RsMule::RunExecutable.new(client)
        re.run_executable("foo", "cookbook::recipe")
      end
    end

    context "when executable type option is right_script_name" do
      it "looks up RightScript href by name" do
        client = mockTheHappyPath(:mock_run_executable => false)
        client = mockRightScriptLookup(client)
        client.resource
          .should_receive("run_executable")
          .once
          .with(:right_script_href => "href2")

        re = RsMule::RunExecutable.new(client)
        re.run_executable("foo", "barbaz", :executable_type => "right_script_name")
      end
    end

    context "when executable type option is right_script_href" do
      it "uses it" do
        client = mockTheHappyPath(:mock_run_executable => false)
        client.resource
          .should_receive("run_executable")
          .once
          .with(:right_script_href => "barbaz")

        re = RsMule::RunExecutable.new(client)
        re.run_executable("foo", "barbaz", :executable_type => "right_script_href")
      end
    end

    context "when executable type option is recipe_name" do
      it "uses it" do
        client = mockTheHappyPath(:mock_run_executable => false)
        client.resource
          .should_receive("run_executable")
          .once
          .with(:recipe_name => "barbaz")

        re = RsMule::RunExecutable.new(client)
        re.run_executable("foo", "barbaz", :executable_type => "recipe_name")
      end
    end

    context "when executable type option is an invalid option" do
      it "raises an ArgumentError" do
        client = flexmock("client")
        re = RsMule::RunExecutable.new(client)
        expect { re.run_executable("foo", "barbaz", :executable_type => "bogus") }.to raise_error ArgumentError
      end
    end

    context "when right_script_revision is latest" do
      it "uses the newest revision" do
        client = mockTheHappyPath(:mock_run_executable => false)
        client = mockRightScriptLookup(client)
        client.resource
        .should_receive("run_executable")
        .once
        .with(:right_script_href => "href2")

        re = RsMule::RunExecutable.new(client)
        re.run_executable("foo", "barbaz")
      end
    end

    context "when tag_match_strategy option is set to any" do
      it "calls the API with match_all set to false" do
        client = mockTheHappyPath(:match_all => "false")
        client = mockRightScriptLookup(client)

        re = RsMule::RunExecutable.new(client)
        re.run_executable("foo", "barbaz", :tag_match_strategy => "any")
      end
    end

    context "when inputs option is supplied" do
      it "passes them along" do
        client = mockTheHappyPath(:mock_run_executable => false)
        client.resource
          .should_receive("run_executable")
          .once
          .with(:recipe_name => "cookbook::recipe", :inputs => {"foo" => "text:barbaz"})

        re = RsMule::RunExecutable.new(client)
        re.run_executable("foo", "cookbook::recipe", :inputs => {"foo" => "text:barbaz"})
      end
    end
  end

  describe "#find_right_script_lineage_by_name" do
    context "when name results in empty lineage" do
      it "raises RightScriptNotFound" do
        client = mockTheHappyPath
        client
          .should_receive("right_scripts")
          .once
          .and_return(flexmock(:index => []))

        re = RsMule::RunExecutable.new(client)

        expect {re.run_executable("foo","barbaz")}.to raise_error RsMule::Exception::RightScriptNotFound
      end
    end
  end

  describe "#right_script_revision_from_lineage" do
    context "when revision is latest" do
      it "has already been tested in a couple cases above" do

      end
    end

    context "when revision is specified" do
      context "and specified revision is unavailable" do
        it "raises RightScriptNotFound" do
          client = mockTheHappyPath
          client = mockRightScriptLookup(client)

          re = RsMule::RunExecutable.new(client)

          expect {
            re.run_executable("foo","barbaz", :right_script_revision => 3)
          }.to raise_error RsMule::Exception::RightScriptNotFound
        end
      end

      context "and specified revision is available" do
        it "uses it" do
          client = mockTheHappyPath(:mock_run_executable => false)
          client = mockRightScriptLookup(client)
          client.resource
            .should_receive("run_executable")
            .once
            .with(:right_script_href => "href1")

          re = RsMule::RunExecutable.new(client)
          re.run_executable("foo", "barbaz", :right_script_revision => 1)
        end
      end
    end
  end

  describe "#update_inputs" do
    context "when current_instance is supplied" do
      it "updates current instance inputs" do
        client = mockTheHappyPath
        instance_inputs_mock = flexmock("instance.inputs")
        instance_inputs_mock.should_receive("multi_update").once.with(:inputs => {"foo" => "text:barbaz"})
        client.resource.should_receive("inputs").and_return(instance_inputs_mock)

        re = RsMule::RunExecutable.new(client)
        re.run_executable("foo", "cookbook::recipe", :inputs => {"foo" => "text:barbaz"}, :update_inputs => ["current_instance"])
      end
    end

    context "when next_instance is supplied" do
      it "updates next instance inputs" do
        client = mockTheHappyPath
        instance_inputs_mock = flexmock("instance.inputs")
        instance_inputs_mock.should_receive("multi_update").once.with(:inputs => {"foo" => "text:barbaz"})
        next_instance_mock = flexmock(:show => flexmock(:inputs => instance_inputs_mock))
        parent_mock = flexmock(:show => flexmock(:next_instance => next_instance_mock))
        client.resource.should_receive("parent").and_return(parent_mock)

        re = RsMule::RunExecutable.new(client)
        re.run_executable("foo", "cookbook::recipe", :inputs => {"foo" => "text:barbaz"}, :update_inputs => ["next_instance"])
      end
    end

    context "when deployment is supplied" do
      it "updates deployment inputs" do
        client = mockTheHappyPath
        instance_inputs_mock = flexmock("instance.inputs")
        instance_inputs_mock.should_receive("multi_update").once.with(:inputs => {"foo" => "text:barbaz"})
        deployment_mock = flexmock(:show => flexmock(:inputs => instance_inputs_mock))
        client.resource.should_receive("deployment").and_return(deployment_mock)

        re = RsMule::RunExecutable.new(client)
        re.run_executable("foo", "cookbook::recipe", :inputs => {"foo" => "text:barbaz"}, :update_inputs => ["deployment"])
      end
    end
  end
end