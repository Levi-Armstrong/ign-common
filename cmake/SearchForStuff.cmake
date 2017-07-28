include (${project_cmake_dir}/Utils.cmake)
include (CheckCXXSourceCompiles)

include (${project_cmake_dir}/FindOS.cmake)
include (FindPkgConfig)
include (${project_cmake_dir}/FindFreeimage.cmake)

########################################
# Find ignition math
set(IGNITION-MATH_REQUIRED_MAJOR_VERSION 3)
if (NOT DEFINED IGNITION-MATH_LIBRARY_DIRS AND NOT DEFINED IGNITION-MATH_INCLUDE_DIRS AND NOT DEFINED IGNITION-MATH_LIBRARIES)
  find_package(ignition-math${IGNITION-MATH_REQUIRED_MAJOR_VERSION} QUIET)
  if (NOT ignition-math${IGNITION-MATH_REQUIRED_MAJOR_VERSION}_FOUND)
    message(STATUS "Looking for ignition-math${IGNITION-MATH_REQUIRED_MAJOR_VERSION}-config.cmake - not found")
    BUILD_ERROR ("Missing: Ignition math${IGNITION-MATH_REQUIRED_MAJOR_VERSION} library.")
  else()
    message(STATUS "Looking for ignition-math${IGNITION-MATH_REQUIRED_MAJOR_VERSION}-config.cmake - found")
  endif()
endif()

########################################
# Include man pages stuff
include (${project_cmake_dir}/Ronn2Man.cmake)
add_manpage_target()

#################################################
# Find tinyxml2. Only debian distributions package tinyxml with a pkg-config
# Use pkg_check_modules and fallback to manual detection
# (needed, at least, for MacOS)

# By default use system installation on UNIX and Apple, and internal copy on Windows
if (NOT DEFINED USE_EXTERNAL_TINYXML2)
  if (UNIX OR APPLE)
    message (STATUS "By default use system installation on UNIX and Apple")
    set (USE_EXTERNAL_TINYXML2 True)
  elseif(WIN32)
    message (STATUS "By default use internal tinyxml2 on Windows")
    set (USE_EXTERNAL_TINYXML2 False)
  else()
    message (STATUS "Unknown platform, unable to configure tinyxml2.")
    BUILD_ERROR("Unknown platform")
  endif()
endif()

if (USE_EXTERNAL_TINYXML2)
  pkg_check_modules(tinyxml2 tinyxml2)
  if (NOT tinyxml2_FOUND)
      find_path (tinyxml2_INCLUDE_DIRS tinyxml2.h ${tinyxml2_INCLUDE_DIRS} ENV CPATH)
      find_library(tinyxml2_LIBRARIES NAMES tinyxml2)
      set (tinyxml2_FAIL False)
      if (NOT tinyxml2_INCLUDE_DIRS)
        message (STATUS "Looking for tinyxml2 headers - not found")
        set (tinyxml2_FAIL True)
      endif()
      if (NOT tinyxml2_LIBRARIES)
        message (STATUS "Looking for tinyxml2 library - not found")
        set (tinyxml2_FAIL True)
      endif()
      if (NOT tinyxml2_LIBRARY_DIRS)
        message (STATUS "Looking for tinyxml2 library dirs - not found")
        set (tinyxml2_FAIL True)
      endif()
  endif()

  if (tinyxml2_FAIL)
    message (STATUS "Looking for tinyxml2.h - not found")
    BUILD_ERROR("Missing: tinyxml2")
  endif()
else()
  # Needed in WIN32 since in UNIX the flag is added in the code installed
  message (STATUS "Skipping search for tinyxml2")
  set (tinyxml2_INCLUDE_DIRS "${CMAKE_SOURCE_DIR}/src/tinyxml2")
  set (tinyxml2_LIBRARIES "")
  set (tinyxml2_LIBRARY_DIRS "")
endif()


# Macro to check for visibility capability in compiler
# Original idea from: https://gitorious.org/ferric-cmake-stuff/
macro (check_gcc_visibility)
  include (CheckCXXCompilerFlag)
  check_cxx_compiler_flag(-fvisibility=hidden GCC_SUPPORTS_VISIBILITY)
endmacro()

########################################
# Find libdl
find_path(libdl_include_dir dlfcn.h /usr/include /usr/local/include)
if (NOT libdl_include_dir)
  message (STATUS "Looking for dlfcn.h - not found")
  BUILD_ERROR ("Missing libdl: Required for plugins.")
  set (libdl_include_dir /usr/include)
else (NOT libdl_include_dir)
  message (STATUS "Looking for dlfcn.h - found")
endif ()

find_library(libdl_library dl /usr/lib /usr/local/lib)
if (NOT libdl_library)
  message (STATUS "Looking for libdl - not found")
  BUILD_ERROR ("Missing libdl: Required for plugins.")
  set(libdl_library "")
else (NOT libdl_library)
  message (STATUS "Looking for libdl - found")
endif ()

#################################################
# Find uuid
#  - In UNIX we use uuid library
#  - In Windows the native RPC call, no dependency needed
if (UNIX)
  include (FindPkgConfig REQUIRED)
  pkg_check_modules(uuid uuid)

  ########################################
  # Find GNU Triangulation Surface Library
  pkg_check_modules(gts gts)
  if (gts_FOUND)
    message (STATUS "Looking for GTS - found")
    set (HAVE_GTS TRUE)
    include_directories(${gts_INCLUDE_DIRS})
    link_directories(${gts_LIBRARY_DIRS})
    add_definitions(${gts_CFLAGS})
  else ()
    message (STATUS "Looking for GTS - not found")
    set (HAVE_GTS FALSE)
    BUILD_ERROR ("GNU Triangulation Surface library not found.")
  endif ()

  if (NOT uuid_FOUND)
    message (STATUS "Looking for uuid pkgconfig file - not found")
    BUILD_ERROR ("uuid not found, Please install uuid")
  else ()
    message (STATUS "Looking for uuid pkgconfig file - found")
    include_directories(${uuid_INCLUDE_DIRS})
    link_directories(${uuid_LIBRARY_DIRS})
  endif ()
elseif (MSVC)
  message (STATUS "Using Windows RPC UuidCreate function")
endif()

# In Visual Studio we use configure.bat to trick all path cmake
# variables so let's consider that as a replacement for pkgconfig
if (MSVC)
  set (PKG_CONFIG_FOUND TRUE)
endif()

if (PKG_CONFIG_FOUND)

  if (NOT MSVC)
    ########################################
    # Find libswscale format
    pkg_check_modules(libswscale libswscale)
    if (NOT libswscale_FOUND)
      BUILD_WARNING("libswscale not found.")
    else (NOT libswscale_FOUND)
      message(STATUS "libswscale found.")
      set (HAVE_SWSCALE True)
    endif ()

    ########################################
    # Find AV device. Only check for this on linux.
    if (UNIX)
      pkg_check_modules(libavdevice libavdevice>=56.4.100)
      if (NOT libavdevice_FOUND)
        BUILD_WARNING ("libavdevice not found. Recording to a video device will be disabled.")
      endif ()
    endif ()

    if (NOT libavdevice_FOUND)
      set (HAVE_AVDEVICE False)
    else()
      set (HAVE_AVDEVICE True)
    endif()

    ########################################
    # Find AV format
    pkg_check_modules(libavformat libavformat)
    if (NOT libavformat_FOUND)
      BUILD_WARNING("libavformat not found.")
    else (NOT libavformat_FOUND)
      message(STATUS "libavformat found.")
      set (HAVE_AVFORMAT True)
    endif()

    ########################################
    # Find avcodec
    pkg_check_modules(libavcodec libavcodec)
    if (NOT libavcodec_FOUND)
      BUILD_WARNING("libavcodec not found.")
    else (NOT libavcodec_FOUND)
      message(STATUS "libavcodec found.")
      set (HAVE_AVCODEC True)
    endif()

    ########################################
    # Find avutil
    pkg_check_modules(libavutil libavutil)
    if (NOT libavutil_FOUND)
      BUILD_WARNING("libavutil not found.")
    else (NOT libavutil_FOUND)
      message(STATUS "libavutil found.")
      set (HAVE_AVUTIL True)
    endif ()
  endif()

  include_directories(${libswscale_INCLUDE_DIRS})
  link_directories(${libswscale_LIBRARY_DIRS})

  include_directories(${libavformat_INCLUDE_DIRS})
  link_directories(${libavformat_LIBRARY_DIRS})

  include_directories(${libavcodec_INCLUDE_DIRS})
  link_directories(${libavcodec_LIBRARY_DIRS})

  include_directories(${libavutil_INCLUDE_DIRS})
  link_directories(${libavutil_LIBRARY_DIRS})

  include_directories(${libavdevice_INCLUDE_DIRS})
  link_directories(${libavdevice_LIBRARY_DIRS})

endif(PKG_CONFIG_FOUND)
