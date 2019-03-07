# Common header for superproject
# ---------------

cmake_minimum_required(VERSION 3.13)

if(NOT SUPERBUILD_ROOT)
	set(CURRENT_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
	foreach(DEPTH RANGE 15)
		if("${CURRENT_DIR}" STREQUAL "/")
			set(SUPERBUILD_ROOT )
			message(STATUS "Found superproject root at ${SUPERBUILD_ROOT}")
			break()
		endif()
		if(EXISTS "${CURRENT_DIR}/cmake/root.cmake")
			set(SUPERBUILD_ROOT "${CURRENT_DIR}")
			break()
		endif()
		get_filename_component(CURRENT_DIR ${CURRENT_DIR} DIRECTORY)
	endforeach()
	if ("${SUPERBUILD_ROOT}" STREQUAL "")
		message(FATAL_ERROR "Cannot find a superproject structures on top of the current directory.")
	endif()
	set (CMAKE_MODULE_PATH "${SUPERBUILD_ROOT}/cmake")
	include(beetroot/beetroot)
endif()

