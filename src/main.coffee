fs = require 'fs'
path = require 'path'
mkdirp = require "mkdirp"
minimist = require 'minimist'
vcdiff = require '../lib/vcdiff'

DELTA_FN = "delta.json"
BUILD_ID_FN = "build_id.json"
BUNDLE_FILTER = (bundle_name) -> bundle_name.indexOf("-min.js") > 0

VERSION = (require '../package').version

E_OK = 0
E_BAD_ARGS = 1
E_ERROR = 2
E_VERSION = 3

to_path = (args...) -> path.resolve ([process.cwd()].concat args)...

vcd = new vcdiff.Vcdiff
vcd.blockSize = 20

calc_delta = (base, target) -> vcd.encode base, target
apply_delta = (base, delta) -> vcd.decode base, delta

read = (fn) -> fs.readFileSync(fn).toString()
write = (fn, content) ->
    mkdirp.sync path.dirname fn
    fs.writeFileSync fn, content

to_json = (data) -> JSON.stringify data
from_json = (data) -> JSON.parse data

say = (m...) -> console.error m...

gen_delta = (base, target) -> [(path.basename target), (calc_delta (read base), (read target))]

get_build_id = (build_root) ->
    bi = JSON.parse read (to_path build_root, BUILD_ID_FN)
    bi.buildid

toDict = (list_of_lists) ->
    x = {}
    list_of_lists.map ([k, v]) -> x[k] = v
    x

parse_args = (argv) -> minimist argv.slice 2

main = (argv) ->
    {old_build_root, new_build_root, delta_root, v, version} = parse_args argv

    if v is true
        say "Version #{VERSION}"
        process.exit E_VERSION
   
    unless old_build_root and new_build_root and delta_root
        say "Usage:\n\t@me --old_build_root=<...> --new_build_root=<...> --delta_root=<...>\nor, to get version:\n\t@me -v"
        process.exit E_BAD_ARGS

    #try
    old_build_id = get_build_id old_build_root

    realms = fs.readdirSync(new_build_root)
               .filter (fn) -> not fs.statSync(to_path new_build_root, fn).isFile()
               .map (fn) -> path.basename fn

    deltas = realms.map (realm) ->
        files = fs.readdirSync to_path new_build_root, realm
                  .filter BUNDLE_FILTER
                  .map (fn) -> path.basename fn

        [realm, (toDict (files.map (fn) -> gen_delta (to_path old_build_root, realm, fn), (to_path new_build_root, realm, fn)))]

    deltas.map ([realm, delta]) -> write (to_path delta_root, old_build_id, realm, DELTA_FN), (to_json delta)

#    catch e
#        say "Sorry, an error occured:\n\t#{e}"
#        process.exit E_ERROR


#main process.argv

module.exports = main



