fs = require 'fs'
path = require 'path'
mkdirp = require "mkdirp"
minimist = require 'minimist'

DEFAULT_PATTERN = '^build(-[0-9]+)?$'

E_OK = 0
E_BAD_ARGS = 1
E_ERROR = 2
E_VERSION = 3

say = (m...) -> console.error m...

to_path = (args...) -> path.resolve ([process.cwd()].concat args)...

parse_args = (argv) -> minimist argv.slice 2

move = (a, b) ->
    say "Moving #{a} -> #{b}"
    fs.renameSync a, b

main = (argv) ->
    {build_root, pattern} = parse_args argv

    unless build_root
        say "Usage:\n\t@me --build_root=<...> [--pattern=<...>]\n\tDefault pattern: /#{DEFAULT_PATTERN}/"
        process.exit E_BAD_ARGS

    try
        re = if pattern then (new RegExp pattern) else (new RegExp DEFAULT_PATTERN)
    catch e
        say "bad pattern: ", pattern, e
        process.exit E_BAD_ARGS

    try
        builds = fs.readdirSync(to_path build_root)
                   .filter((fn) -> re.test(fn) and not fs.statSync(to_path build_root, fn).isFile())
                   .map((fn) -> path.basename fn)
                   .sort()
                   .reverse()

        builds.map (build_name) ->
            [build, number_str] = build_name.split '-'

            if number_str is undefined
              move (to_path build_root, build_name), (to_path build_root, "#{build}-1")
            else
              number = parseInt number_str, 10
              move (to_path build_root, build_name), (to_path build_root, "#{build}-#{number+1}")

    catch e
        say "Sorry, an error occured:\n\t#{e}"
        process.exit E_ERROR


module.exports = main