package require tcltest
namespace import tcltest::*

# Add module dir to tm paths
set ThisScriptDir [file dirname [info script]]
set ModuleDir [file normalize [file join $ThisScriptDir ..]]
::tcl::tm::path add $ModuleDir

package require configurator
namespace import configurator::*


test makeSetConfigCmd-1 {Returns a list where the first element is the key} {
  set alias [makeSetConfigCmd device 1 "1|0"]
  lindex $alias 0
} device

test makeSetConfigCmd-2 {Returns a list referencing a function that will fail \
if the wrong number of arguments passed to it} -setup {
  set alias [makeSetConfigCmd device 1 "1|0"]
  set cmd [lindex $alias 1]
} -body {
  {*}$cmd
} -result {wrong # args: should be "device 1|0"} -returnCodes {error}

test makeSetConfigCmd-3 {Returns a list referencing a function that will \
accept many arguments if requested} -setup {
  set alias [makeSetConfigCmd options many "option ?option ..?"]
  set cmd [lindex $alias 1]
} -body {
  {*}$cmd 1 5 4 hello
} -result [dict create options {1 5 4 hello}]

test makeSetConfigCmd-4 {Returns a list referencing a function that will \
fail if many arguments requested but none given} -setup {
  set alias [makeSetConfigCmd options many "option ?option ..?"]
  set cmd [lindex $alias 1]
} -body {
  {*}$cmd
} -result {wrong # args: should be "options option ?option ..?"} \
  -returnCodes {error}


test makeSectionCmd-1 {Returns a list referencing a function that will \
fail with a sensible error message if wrong number of arguments given} -setup {
  set deviceSectionAliases [list \
    [makeSetConfigCmd write_cache 1 "1|0"]                  \
    [makeSetConfigCmd dma 1 "1|0"]                          \
    [makeSetConfigCmd options many "option ?option ..?"]]
  set alias [makeSectionCmd device $deviceSectionAliases \
                                   "deviceName deviceDetails"]
  set cmd [lindex $alias 1]
} -body {
  {*}$cmd
} -result {wrong # args: should be "device deviceName deviceDetails"} \
  -returnCodes {error}


test parseConfig-1 {Returns correct dictionary for script passed} -setup {
  set script {
    device /dev/hda
    write_cache 1
    dma 1
    options ro boost
  }

  set aliases [list \
    [makeSetConfigCmd device 1 "1|0"]                       \
    [makeSetConfigCmd write_cache 1 "1|0"]                  \
    [makeSetConfigCmd dma 1 "1|0"]                          \
    [makeSetConfigCmd options many "option ?option ..?"]]
} -body {
  parseConfig -aliases $aliases $script
} -result [dict create device /dev/hda write_cache 1 dma 1 options {ro boost}]

test parseConfig-2 {Returns nested dictionary for script passed} -setup {
  set script {
    device /dev/hda {
      write_cache 1
      dma 1
      options ro boost
    }

    device /dev/hdb {
      write_cache 0
      dma 0
      options rw stable
    }
  }

  set deviceSectionAliases [list \
    [makeSetConfigCmd write_cache 1 "1|0"]                  \
    [makeSetConfigCmd dma 1 "1|0"]                          \
    [makeSetConfigCmd options many "option ?option ..?"]]

  set aliases [list \
    [makeSectionCmd device $deviceSectionAliases "deviceName deviceDetails"]]

} -body {
  parseConfig -aliases $aliases $script
} -result [dict create /dev/hda [dict create        \
                                      write_cache 1 \
                                      dma 1         \
                                      options {ro boost}]   \
                       /dev/hdb [dict create        \
                                      write_cache 0 \
                                      dma 0         \
                                      options {rw stable}]]

test parseConfig-3 {Ensure non hidden commands can be run} -setup {
  set script {
    title "The answer to 2 + 2 is [expr {2 + 2}]"
  }

  set aliases [list \
    [makeSetConfigCmd title 1 "title"]]

} -body {
  parseConfig -aliases $aliases $script
} -result [dict create title "The answer to 2 + 2 is 4"]


cleanupTests
