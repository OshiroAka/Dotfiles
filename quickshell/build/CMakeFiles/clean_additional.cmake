# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "Release")
  file(REMOVE_RECURSE
  "CMakeFiles/oshiro_autogen.dir/AutogenUsed.txt"
  "CMakeFiles/oshiro_autogen.dir/ParseCache.txt"
  "oshiro_autogen"
  )
endif()
