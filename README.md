# rs-mule

A [CLI](./#CLI) tool that runs "stuff".  Meant primarily for running RightScripts or Chef recipes on individual nodes, identified by tags.

Also a [Library](./#Library) that allows you to do the same sorta stuff in your own app, cause I'm generous like that.

[<img src="https://travis-ci.org/rgeyer/rs-mule.png" />](https://travis-ci.org/rgeyer/rs-mule)

## CLI

### Authentication
The CLI requires you to authenticate with right_api_client.  Typically providing
your rightscale email address, password, and an account id are sufficient for
getting authenticated.  However you can also use an oAuth token. For more
information on the required parameters check out the
[right_api_client documentation](https://github.com/rightscale/right_api_client)

When using the CLI you can provide RightScale API authentication info in two ways.

#### rs_auth_hash
Perhaps the easiest way to provide the authentication parameters is on the
commandline with the --rs-auth-hash option.

Example:
```
rs-mule [COMMAND] --rs-auth-hash=email:foo@bar.baz password:password account_id:12345
```

#### rs_auth_file
You can also create a YAML file which contains the authentication parameters you
want to supply, then point rs-mule at your authentication parameter file.

You can find an example of this file at the root of this project as
"auth_file.yaml.example", and it looks a little like this.

Example File:
```
---
:email: foo@bar.baz
:password: password
:account_id: 12345
```

You can tell rs-mule to use your parameters file thusly.

Example:
```
rs-mule [COMMAND] --rs-auth-file=/path/to/auth_file.yaml
```

### Usage

rs-mule has one (soon to be two) commands.

```
Commands:
  rs-mule help [COMMAND]                       # Describe available commands or one specific command
  rs-mule run_executable --tags=one two three  # Runs a specified recipe or RightScript on instances targeted by tag
```

#### run_executable command
This is used to run a RightScript or Chef recipe on instances found using a tag
search.

The simplest usage requires the executable to run, and at least one tag.
```
rs-mule run_executable "Some RightScript Name" --tags=tag1
```

##### Tag Matching Strategy
If you provide more than one tag, rs-mule will assume that you want target
instances to possess all of the supplied tags in order for the executable to be
run on them.  However, you can be a little more lenient and have rs-mule run the
executable on instances which have any of the tags.

Script will run only on instances which have both "tag1" and "tag2"
```
rs-mule run_executable "Some RightScript Name" --tags=tag1 tag2
```

The explicit version of above
```
rs-mule run_executable "Some RightScript Name" --tags=tag1 tag2 --tag-match-strategy=all
```

Script will run on any instance which has either "tag1" or "tag2"
```
rs-mule run_executable "Some RightScript Name" --tags=tag1 tag2 --tag-match-strategy=any
```

##### RightScript Version
When you are running a RightScript, rs-mule will assume you want to run the
latest and greatest version.  It'll also assume that revision is not the HEAD
revision.  You can supply a specified revision number, or use 0 if you want to
live on the edge and use the HEAD revision.

Specify revision 3
```
rs-mule run_executable "Some RightScript Name" --tags=tag1 --right-script-revision=3
```

Specify HEAD revision
```
rs-mule run_executable "Some RightScript Name" --tags=tag1 --right-script-revision=0
```

##### Executable Type
The executable value can be one of the following;
* The name of a RightScript
* An API href of a RightScript (Eg. /api/right_scripts/abc123)
* The name of a Chef recipe (Eg. cookbook::recipe)

rs-mule will attempt to automatically detect which one you've supplied by applying
some regular expressions and other detection mechanisms against the executable
string provided.

However, you can remove the guesswork by specifying the executable type as an
option.

RightScript HREF:
```
rs-mule run_executable "/api/right_scripts/abc123" --executable-type=right_script_href --tags=tag1
```

RightScript Name:
```
rs-mule run_executable "Some RightScript Name" --executable-type=right_script_name --tags=tag1
```

Chef Recipe:
```
rs-mule run_executable "cookbook::recipe" --executable-type=recipe_name --tags=tag1
```

## Library
The library does all this cool stuff, and I'll document it, I swear...

## Authors

Created and maintained by [Ryan Geyer][author] (<me@ryangeyer.com>)

## License

MIT (see [LICENSE][license])

[author]:           https://github.com/rgeyer
[issues]:           https://github.com/rgeyer/rs-mule/issues
[license]:          https://github.com/rgeyer/rs-mule/blob/master/LICENSE
[repo]:             https://github.com/rgeyer/rs-mule