require 'non-haml'
require_relative 'r_math'
include RMath

NonHaml.generate "hi.c", "hi-source.c"
