
# a set of macros for building bundles of devices
#  BEGIN_DEVICE_LIBRARY(devname)
#  END_DEVICE_LIBRARY(devname)
# etc.

#########################################################################
# BEGIN_DEVICE_LIBRARY macro makes sure that all the cmake hooks
# needed for creating a device library are in place.  Those hooks
# are defined in YarpModuleHooks.cmake
#
MACRO(BEGIN_DEVICE_LIBRARY devname)

  # YARP device library bundles should take a "d" suffix for debug
  # versions.
  IF (MSVC)
    SET(CMAKE_DEBUG_POSTFIX "d")
  ENDIF (MSVC)

  # Dependencies on YARP of individual device modules via
  # FIND_PACKAGE(YARP) will be optimized by substituting directly
  # the names of the YARP libraries.
  INCLUDE(YarpLibraryNames)

  # This is a collection of variable used to track all sorts of
  # resources as a device module is created.  For example, when
  # in a device module there is a line like:
  #    LINK_LIBRARIES(foo bar)
  # then instead of those libraries being linked, they are
  # appended to one of these variables.  Similarly for definitions,
  # include paths, source files, etc.  In the end, a single 
  # library target is created based on all this material.
  # This has the down-side that device module CMakeLists.txt
  # files should not get too fancy, and the up-side that
  # those files can be read and written with basic knowledge
  # of CMake.
  SET(YARPY_LIB_LIST0)
  SET(YARPY_XLIB_LIST0)
  SET(YARPY_SRC_LIST0)
  SET(YARPY_INC_LIST0)
  SET(YARPY_LNK_LIST0)
  SET(YARPY_DEF_LIST0)
  SET(YARPY_DEV_LIST0)

  # If we are nested inside a larger device block, we don't
  # have to do much.  If we are the outermost device block,
  # then we need to set up everything.
  IF (YARPY_DEVICES)

    MESSAGE(STATUS "nested library ${devname}")
    SET(DEVICE_PREFIX "${devname}_")

  ELSE (YARPY_DEVICES)

    INCLUDE(UsePkgConfig)
    SET(YARP_KNOWN_DEVICE_LIBS ${YARP_KNOWN_DEVICE_LIBS} ${devname})
    IF (COMPILING_ALL_YARP)
      SET(YARP_MODULE_PATH "${CMAKE_SOURCE_DIR}/conf")
    ELSE (COMPILING_ALL_YARP)
      IF (NOT YARP_MODULE_PATH)
        SET(YARP_MODULE_PATH "${YARP_ROOT}/conf")
      ENDIF (NOT YARP_MODULE_PATH)
    ENDIF (COMPILING_ALL_YARP)
    MESSAGE(STATUS "starting device library: ${devname}")
    SET(YARPY_DEV_LIB_NAME ${devname})
    SET(YARPY_DEVICES TRUE)

    # commands seem to lurk even if variables are removed
    IF (COMMAND END_DEVICE_LIBRARY)
      SET(YARPY_DEVICES_INSTALLED TRUE)
    ENDIF (COMMAND END_DEVICE_LIBRARY)

    SET(YARPY_DEV_GEN ${CMAKE_BINARY_DIR}/generated_code)
    IF (NOT EXISTS ${YARPY_DEV_GEN})
      FILE(MAKE_DIRECTORY ${YARPY_DEV_GEN})
    ENDIF (NOT EXISTS ${YARPY_DEV_GEN})
    SET(DEVICE_PREFIX "${devname}_")
    SET(YARPY_LIB_FLAG EXCLUDE_FROM_ALL)
    IF (NOT YARPY_DEV_LIB_NAME)
      SET(YARPY_DEV_LIB_NAME devices)
    ENDIF (NOT YARPY_DEV_LIB_NAME)

    SET(YARPY_DEV_LIST)
    SET(YARPY_DEV_SRC_LIST)

    IF (NOT YARPY_DEVICES_INSTALLED)
      MESSAGE(STATUS "adding hooks for device library compilation")
      SET(YARPY_DEVICES_INSTALLED TRUE)
      IF (NOT COMPILE_DEVICE_LIBRARY)
        INCLUDE(YarpModuleHooks)
      ENDIF (NOT COMPILE_DEVICE_LIBRARY)
    ENDIF (NOT YARPY_DEVICES_INSTALLED)

    SET(COMPILE_DEVICE_LIBRARY TRUE)

    SET(YARPY_MASTER_DEVICE ${devname})

  ENDIF (YARPY_DEVICES)

ENDMACRO(BEGIN_DEVICE_LIBRARY devname)

MACRO(ADD_DEVICE_NORMALIZED devname type include wrapper)
  INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR})
  SET(YARPDEV_NAME "${devname}")
  SET(YARPDEV_TYPE "${type}")
  SET(YARPDEV_INCLUDE "${include}")
  SET(YARPDEV_WRAPPER "${wrapper}")
  SET(ENABLE_YARPDEV_NAME "1")
  SET(fdir ${YARPY_DEV_GEN})
  IF(NOT fdir)
    SET(fdir ${CMAKE_CURRENT_BINARY_DIR})
  ENDIF(NOT fdir)
  SET(fname ${fdir}/yarpdev_add_${devname}.cpp)
  CONFIGURE_FILE(${YARP_MODULE_PATH}/yarpdev_helper.cpp.in
    ${fname} @ONLY  IMMEDIATE)
  ###MESSAGE(STATUS "Device ${devname} creation code in ${fname}")

  SET(MYNAME "${DEVICE_PREFIX}${devname}")
  IF (NOT COMPILE_BY_DEFAULT)
    SET (COMPILE_BY_DEFAULT FALSE)
  ENDIF (NOT COMPILE_BY_DEFAULT)
  SET(ENABLE_${MYNAME} ${COMPILE_BY_DEFAULT} CACHE BOOL "Enable/disable compilation of ${MYNAME}")

  # for user's convience
  SET(ENABLE_${devname} ${ENABLE_${MYNAME}})
  IF (ENABLE_${devname})
    SET(SKIP_${devname} FALSE)
    SET(SKIP_${MYNAME} FALSE)
  ELSE (ENABLE_${devname})
    SET(SKIP_${devname} TRUE)
    SET(SKIP_${MYNAME} TRUE)
  ENDIF (ENABLE_${devname})

  IF (ENABLE_${MYNAME})
    SET(YARPY_DEV_SRC_LIST ${YARPY_DEV_SRC_LIST} ${fname})
    SET(YARPY_DEV_LIST ${YARPY_DEV_LIST} ${devname})
    SET(YARPY_DEV_ACTIVE TRUE)
    MESSAGE(STATUS " +++ device ${devname}, ENABLE_${devname} is set")
  ELSE (ENABLE_${MYNAME})
    MESSAGE(STATUS " +++ device ${devname}, SKIP_${devname} is set")
  ENDIF (ENABLE_${MYNAME})



ENDMACRO(ADD_DEVICE_NORMALIZED devname type include wrapper)

MACRO(PREPARE_DEVICE devname)
  SET(EXPECT_TYPE FALSE)
  SET(EXPECT_INCLUDE FALSE)
  SET(THE_TYPE "")
  SET(THE_INCLUDE "")
  SET(THE_WRAPPER "")
  FOREACH(arg ${ARGN})
    IF(EXPECT_TYPE)
      SET(THE_TYPE ${arg})
      SET(EXPECT_TYPE FALSE)
    ENDIF(EXPECT_TYPE)
    IF(EXPECT_INCLUDE)
      SET(THE_INCLUDE ${arg})
      SET(EXPECT_INCLUDE FALSE)
    ENDIF(EXPECT_INCLUDE)
    IF(EXPECT_WRAPPER)
      SET(THE_WRAPPER ${arg})
      SET(EXPECT_WRAPPER FALSE)
    ENDIF(EXPECT_WRAPPER)
    IF(arg STREQUAL "TYPE")
      SET(EXPECT_TYPE TRUE)
    ENDIF(arg STREQUAL "TYPE")
    IF(arg STREQUAL "INCLUDE")
      SET(EXPECT_INCLUDE TRUE)
    ENDIF(arg STREQUAL "INCLUDE")
    IF(arg STREQUAL "WRAPPER")
      SET(EXPECT_WRAPPER TRUE)
    ENDIF(arg STREQUAL "WRAPPER")
  ENDFOREACH(arg ${ARGN})
  IF(THE_TYPE AND THE_INCLUDE)
    ADD_DEVICE_NORMALIZED(${devname} ${THE_TYPE} ${THE_INCLUDE} "${THE_WRAPPER}")
  ELSE(THE_TYPE AND THE_INCLUDE)
    MESSAGE(STATUS "Not enough information to create ${devname}")
    MESSAGE(STATUS "  type:    ${THE_TYPE}")
    MESSAGE(STATUS "  include: ${THE_INCLUDE}")
    MESSAGE(STATUS "  wrapper: ${THE_WRAPPER}")
  ENDIF(THE_TYPE AND THE_INCLUDE)
ENDMACRO(PREPARE_DEVICE devname)

MACRO(IMPORT_DEVICES hdr)
  FOREACH (libname ${ARGN})
    IF (NOT COMPILING_ALL_YARP)
      SET(KNOWN FALSE)
      FOREACH (klibname ${YARP_KNOWN_DEVICE_LIBS})
        IF ("${klibname}" STREQUAL "${libname}")
          SET(KNOWN TRUE)
        ENDIF ("${klibname}" STREQUAL "${libname}")
      ENDFOREACH (klibname ${YARP_KNOWN_DEVICE_LIBS})
      IF (KNOWN)
        LINK_LIBRARIES(${libname})
      ELSE (KNOWN)
        FIND_PACKAGE(${libname})
      ENDIF (KNOWN)
    ENDIF (NOT COMPILING_ALL_YARP)

    # Dec08 -- nat removes:
    # LINK_LIBRARIES(optimized ${libname} debug ${libname}d)
    # adds:
    IF(MSVC)
      LINK_LIBRARIES(optimized ${libname} debug ${libname}d)
    ELSE(MSVC)
      LINK_LIBRARIES(optimized ${libname} debug ${libname})
    ENDIF(MSVC)
    
  ENDFOREACH (libname ${ARGN})
  SET(YARP_CODE_PRE)
  SET(YARP_CODE_POST)
  #  FOREACH(dev ${YARP_DEVICE_LIST})
  FOREACH(dev ${ARGN})
    SET(YARP_CODE_PRE "${YARP_CODE_PRE}\nextern void add_${dev}_devices();")
    SET(YARP_CODE_POST "${YARP_CODE_POST}\n        add_${dev}_devices();")
  ENDFOREACH(dev ${})
  SET(YARP_LIB_NAME ${YARPY_DEV_LIB_NAME})
  CONFIGURE_FILE(${YARP_MODULE_PATH}/yarpdev_import.h.in
    ${hdr} @ONLY  IMMEDIATE)
  MESSAGE(STATUS "generated ${hdr}")
  IF (YARP_LIBRARIES)
    LINK_LIBRARIES(${YARP_LIBRARIES})
  ELSE (YARP_LIBRARIES)
    LINK_LIBRARIES(YARP_dev ${YARP_EXTMOD_TARGETS} ${YARP_dev_EXT_LIBS} YARP_sig YARP_OS)
  ENDIF (YARP_LIBRARIES)
ENDMACRO(IMPORT_DEVICES hdr)


MACRO(TARGET_IMPORT_DEVICES target hdr)
  FOREACH (libname ${ARGN})
    IF (NOT COMPILING_ALL_YARP)
      SET(KNOWN FALSE)
      FOREACH (klibname ${YARP_KNOWN_DEVICE_LIBS})
        IF ("${klibname}" STREQUAL "${libname}")
          SET(KNOWN TRUE)
        ENDIF ("${klibname}" STREQUAL "${libname}")
      ENDFOREACH (klibname ${YARP_KNOWN_DEVICE_LIBS})
      IF (NOT KNOWN)
        FIND_PACKAGE(${libname})
      ENDIF (NOT KNOWN)
    ENDIF (NOT COMPILING_ALL_YARP)
    TARGET_LINK_LIBRARIES(${target} ${libname})
  ENDFOREACH (libname ${ARGN})
  SET(YARP_CODE_PRE)
  SET(YARP_CODE_POST)
  FOREACH(dev ${ARGN})
    SET(YARP_CODE_PRE "${YARP_CODE_PRE}\nextern void add_${dev}_devices();")
    SET(YARP_CODE_POST "${YARP_CODE_POST}\n        add_${dev}_devices();")
  ENDFOREACH(dev ${})
  SET(YARP_LIB_NAME ${YARPY_DEV_LIB_NAME})
  CONFIGURE_FILE(${YARP_MODULE_PATH}/yarpdev_import.h.in
    ${hdr} @ONLY  IMMEDIATE)
  MESSAGE(STATUS "generated ${hdr}")
  IF (YARP_LIBRARIES)
    TARGET_LINK_LIBRARIES(${target} ${YARP_LIBRARIES})
  ELSE (YARP_LIBRARIES)
    TARGET_LINK_LIBRARIES(${target} YARP_dev ${YARP_EXTMOD_TARGETS} ${YARP_dev_EXT_LIBS} YARP_sig YARP_OS)
  ENDIF (YARP_LIBRARIES)
ENDMACRO(TARGET_IMPORT_DEVICES target hdr)
