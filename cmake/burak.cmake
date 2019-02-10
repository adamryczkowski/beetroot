# get_target(<TEMPLATE_NAME> [PATH <Ścieżka do targets.cmake>] <Args...>)
#
# High level function responsible for 
# 1. finding a target defining function by its template name (or path), 
# 2. get all its arguments by properly combining default values with already existing variables and arguments Args...
# 3. if target defined by that arguments exists already, return its name, otherwise...
# 3. ...instatiate its dependencies (which may be internal and external) by calling declare_dependencies(), 
# 4. define the target by calling generate_targets() and
# 5. return the actual target name.
#

get_filename_component(__PREFIX "${CMAKE_CURRENT_LIST_FILE}" DIRECTORY)
set(CMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY 1) #We disable use of CMake package registry. See https://cmake.org/cmake/help/v3.2/variable/CMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY.html . With this variable set, the only version of the packages will be the version we actually intend to use.

include(${__PREFIX}/burak_variables_misc.cmake)
include(${__PREFIX}/burak_data_def.cmake)
include(${__PREFIX}/burak_get_target.cmake)
include(${__PREFIX}/burak_finalize.cmake)
include(${__PREFIX}/burak_reading_targets.cmake)
include(${__PREFIX}/burak_parse_variables.cmake)
include(${__PREFIX}/burak_global_storage.cmake)
include(${__PREFIX}/burak_global_storage_misc.cmake)
include(${__PREFIX}/burak_dependency_processing.cmake)
include(${__PREFIX}/burak_ids.cmake)
include(${__PREFIX}/burak_external_target.cmake)
include(${__PREFIX}/build_install_prefix.cmake)
include(${__PREFIX}/set_operations.cmake)
include(${__PREFIX}/prepare_arguments_to_pass.cmake)
include(${__PREFIX}/missing_dependency.cmake)
include(${__PREFIX}/burak_messages.cmake)


_set_behavior_outside_defining_targets()
if(NOT __NOT_SUPERBUILD)
	_set_property_to_db(GLOBAL ALL EXTERNAL_DEPENDENCIES "" FORCE)
else()
	message(STATUS "Beginning of the second phase")
endif()
set(__RANDOM ${__RANDOM})
include(ExternalProject)


#We hijack the project() command to make sure, that during the superbuild phase no actual compiling will take place.
macro(project) 
	if(__NOT_SUPERBUILD)
		_project(${ARGN})
	else()
		message("No languages in project ${ARGV0}")
		_project(${ARGV0} NONE)
	endif()
endmacro()

function(_invoke_apply_dependency_to_target __DEPENDEE_INSTANCE_ID __INSTANCE_ID __OUT_FUNCTION_EXISTS)
	_retrieve_instance_data(${__INSTANCE_ID} PATH __TARGETS_CMAKE_PATH)
	_retrieve_instance_args(${__INSTANCE_ID} MODIFIERS __ARGS)
	set(__TMP_LIST "${__ARGS__LIST}")
	_retrieve_instance_args(${__INSTANCE_ID} I_FEATURES __ARGS)
	list(APPEND __TMP_LIST ${__ARGS__LIST})
	_retrieve_instance_args(${__INSTANCE_ID} LINKPARS __ARGS)
	_retrieve_instance_pars(${__INSTANCE_ID} __PARS)
	list(APPEND __TMP_LIST ${__ARGS__LIST})
	set(__ARGS__LIST ${__TMP_LIST})
	_make_instance_name(${__DEPENDEE_INSTANCE_ID} __DEP_INSTANCE_NAME)
	_make_instance_name(${__INSTANCE_ID} __INSTANCE_NAME)
	
	_retrieve_instance_data(${__INSTANCE_ID} DEP_INSTANCES __DEP_ID_LIST)
	_insert_names_from_dependencies("${__DEP_ID_LIST}" __ARGS)

	get_filename_component(__TEMPLATE_DIR "${__TARGETS_CMAKE_PATH}" DIRECTORY)
	_read_functions_from_targets_file("${__TARGETS_CMAKE_PATH}")
#	message(STATUS "_get_target_internal()3 Serialbox_SerialboxCStatic_INSTALL_DIR: ${Serialbox_SerialboxCStatic_INSTALL_DIR}")
	
	set(CMAKE_CURRENT_SOURCE_DIR "${__TEMPLATE_DIR}")

	_instantiate_variables(__ARGS __PARS "${__ARGS__LIST}")
	unset(__NO_OP)
#	apply_to_target(${__DEPENDEE_INSTANCE_ID} ${__INSTANCE_NAME})
#	take_dependency_from_target(${__DEPENDEE_INSTANCE_ID} ${__INSTANCE_NAME})

	get_target_property(__TYPE ${__DEP_INSTANCE_NAME} TYPE)
	if("${__TYPE}" STREQUAL "INTERFACE_LIBRARY" )
		set(KEYWORD "INTERFACE")
	else()
		set(KEYWORD "PUBLIC")
	endif()


	apply_dependency_to_target(${__DEP_INSTANCE_NAME} ${__INSTANCE_NAME})

#	message(STATUS "_invoke_apply_dependency_to_target(): __TARGETS_CMAKE_PATH: ${__TARGETS_CMAKE_PATH} __DEPENDEE_INSTANCE_ID: ${__DEPENDEE_INSTANCE_ID} __INSTANCE_ID: ${__INSTANCE_ID} __NO_OP: ${__NO_OP}")
	if(__NO_OP)
		set(${__OUT_FUNCTION_EXISTS} 0 PARENT_SCOPE)
	else()
		set(${__OUT_FUNCTION_EXISTS} 1 PARENT_SCOPE)
	endif()
endfunction()

function(_make_sure_no_apply_to_target __TARGETS_CMAKE_PATH __DEPENDENT __DEPENDEE)
	_read_functions_from_targets_file("${__TARGETS_CMAKE_PATH}")
	unset(__NO_OP)
	apply_to_target("NO_TARGET" "NO_TARGET")
	if(NOT __NO_OP)
		message(FATAL_ERROR "Cannot use ${__DEPENDENT} as a dependency of ${__DEPENDEE}, because ${__DEPENDENT} has take_dependency_from_target() function defined which cannot be called when ${__DEPENDEE} does not generate a target.")
	endif()
endfunction()

#General function that parses whatever arguments were passed to it after the required parameters.
#Additionally, the function includes a list ${__OUT_PREFIX}__LIST with all actually set arguments for e.g. easier calculation of hash.
function(_parse_general_function_arguments __POSITIONAL __OPTIONS __oneValueArgs __multiValueArgs __OUT_PREFIX )
	set(__ARGSKIP 4)
	set(__ARG_I -1)
	set(__TO_REMOVE )
	set(__ALL_PARS ${__POSITIONAL} ${__OPTIONS} ${__oneValueArgs} ${__multiValueArgs})
	set(__ALL_PARS_COPY ${__ALL_PARS})
	list(REMOVE_DUPLICATES __ALL_PARS_COPY)
	list(LENGTH __ALL_PARS __ALL_PARS_COUNT)
	list(LENGTH __ALL_PARS_COPY __UNIQUE_PARS_COUNT)
	if(${__UNIQUE_PARS_COUNT} LESS ${__ALL_PARS_COUNT})
		message(FATAL_ERROR "Internal beetroot error: non-unique names of parameters passed to _parse_general_function_arguments(\"${__POSITIONAL}\" \"${__OPTIONS}\" \"${__oneValueArgs}\" \"${__multiValueArgs}\" ${__OUT_PREFIX})")
	endif()
	if(__POSITIONAL)
		foreach(__POS_ITEM IN LISTS __POSITIONAL)
#			message(STATUS "_parse_general_function_arguments(): __POS_ITEM: ${__POS_ITEM}")
			math(EXPR __ARGSKIP "${__ARGSKIP} + 1")
			math(EXPR __ARG_I "${__ARG_I} + 1")
			list(APPEND __TO_REMOVE ${__ARG_I})
#			message(STATUS "_parse_general_function_arguments(): __ARGSKIP: ${__ARGSKIP}")
			if(${ARGC} LESS_EQUAL ${__ARGSKIP})
				message(FATAL_ERROR "Internal beetroot error: _append_postprocessing_action(${__ACTION}) was passed less arguments than the number of obligatory positional parameters ${__POSITIONAL}")
			endif()
			set(___PARSED_${__POS_ITEM} "${ARGV${__ARGSKIP}}")
#			message(STATUS "_parse_general_function_arguments(): Got positional value ___PARSED_${__POS_ITEM}: ${ARGV${__ARGSKIP}} __TO_REMOVE: ${__TO_REMOVE}. ")
		endforeach()
#		message(STATUS "_parse_general_function_arguments(): ARGV${__ARGSKIP}: ${ARGV${__ARGSKIP}}")
		set(__COPY_ARGS "${ARGN}")
#		message(STATUS "_parse_general_function_arguments(): Going to remove: ${__TO_REMOVE} from __COPY_ARGS: ${__COPY_ARGS} ")
		list(REMOVE_AT __COPY_ARGS ${__TO_REMOVE})
	else()
		set(__COPY_ARGS ${ARGV})
	endif()
	
#	message(STATUS "_parse_general_function_arguments(): After positional arguments: __COPY_ARGS: ${__COPY_ARGS}")
	cmake_parse_arguments(___PARSED "${__OPTIONS}" "${__oneValueArgs}" "${__multiValueArgs}" ${__COPY_ARGS})
	set(__unparsed ${___PARSED_UNPARSED_ARGUMENTS})
	if(__unparsed)
		message(FATAL_ERROR "Internal beetroot error: Undefined postprocessing for targets file: ${__unparsed}. All options: ${__COPY_ARGS}")
	endif()
	set(__ARGLIST)
	foreach(__VAR IN LISTS __POSITIONAL __OPTIONS __oneValueArgs __multiValueArgs )
		if( NOT "${___PARSED_${__VAR}}" STREQUAL "")
			set(${__OUT_PREFIX}_${__VAR} ${___PARSED_${__VAR}} PARENT_SCOPE)
			list(APPEND __ARGLIST ${__VAR})
		elseif(${__VAR} IN_LIST __OPTIONS)
			set(___PARSED_${__VAR} 0 PARENT_SCOPE)
			set(${__OUT_PREFIX}_${__VAR} ${___PARSED_${__VAR}} PARENT_SCOPE)
		endif()
	endforeach()
	set(${__OUT_PREFIX}__LIST ${__ARGLIST} PARENT_SCOPE)
endfunction()


function(_parse_file_options __INSTANCE_ID __TARGETS_CMAKE_PATH __IS_TARGET_FIXED __TEMPLATE_OPTIONS __OUT_SINGLETON_TARGETS __OUT_NO_TARGETS __OUT_LANGUAGES __OUT_NICE_NAME __OUT_EXPORTED_VARIABLES __OUT_LINK_TO_DEPENDEE)
	set(__OPTIONS SINGLETON_TARGETS NO_TARGETS LINK_TO_DEPENDEE)
	set(__oneValueArgs NICE_NAME)
	set(__multiValueArgs LANGUAGES EXPORTED_VARIABLES)
	
	set(__PARSED_LANGUAGES)
	set(__PARSED_SINGLETON_TARGETS)
	set(__PARSED_NO_TARGETS)
	cmake_parse_arguments(__PARSED "${__OPTIONS}" "${__oneValueArgs}" "${__multiValueArgs}" ${__TEMPLATE_OPTIONS})
	set(__unparsed ${__PARSED_UNPARSED_ARGUMENTS})
	if(__unparsed)
		message(FATAL_ERROR "Undefined TEMPLATE_OPTIONS in ${__TARGETS_CMAKE_PATH}: ${__unparsed}")
	endif()
	
#	message(STATUS "_parse_file_options(): __TEMPLATE_OPTIONS: ${__TEMPLATE_OPTIONS}")
	if(__PARSED_LANGUAGES)
#		message(STATUS "_parse_file_options(): __PARSED_LANGUAGES: ${__PARSED_LANGUAGES}")
		set(__CMAKE_LANGUAGES CXX C CUDA Fortran ASM)
		foreach(__LANGUAGE IN LISTS __PARSED_LANGUAGES)
			if(NOT ${__LANGUAGE} IN_LIST __CMAKE_LANGUAGES)
				message(FATAL_ERROR "Option LANGUAGES in TEMPLATE_OPTIONS defined in ${__TARGETS_CMAKE_PATH} contains unknown language \"${__LANGUAGE}\".")
			endif()
		endforeach()
		set(${__OUT_LANGUAGES} ${__PARSED_LANGUAGES} PARENT_SCOPE)
	else()
		set(${__OUT_LANGUAGES} "" PARENT_SCOPE)
	endif()
	
	_make_path_hash(${__TARGETS_CMAKE_PATH} __PATH_HASH)
	if(__PARSED_SINGLETON_TARGETS)
		set(${__OUT_SINGLETON_TARGETS} 1 PARENT_SCOPE)
		if(NOT __IS_TARGET_FIXED)
			message(FATAL_ERROR "When using SINGLETON_TARGETS option, please list all targets using ENUM_TARGETS rather than ENUM_TEMPLATES.")
		endif()
	else()
		set(${__OUT_SINGLETON_TARGETS} 0 PARENT_SCOPE)
	endif()

	if(__PARSED_NO_TARGETS)
		set(${__OUT_NO_TARGETS} 1 PARENT_SCOPE)
	else()
		set(${__OUT_NO_TARGETS} 0 PARENT_SCOPE)
	endif()

	if(__PARSED_NICE_NAME)
		set(${__OUT_NICE_NAME} "${__PARSED_NICE_NAME}" PARENT_SCOPE)
	else()
		set(${__OUT_NICE_NAME} "" PARENT_SCOPE)
	endif()
	
	if(__PARSED_EXPORTED_VARIABLES)
		set(${__OUT_EXPORTED_VARIABLES} "${__PARSED_EXPORTED_VARIABLES}" PARENT_SCOPE)
	else()
		set(${__OUT_EXPORTED_VARIABLES} "" PARENT_SCOPE)
	endif()

	if(__PARSED_LINK_TO_DEPENDEE)
		set(${__OUT_LINK_TO_DEPENDEE} "1" PARENT_SCOPE)
	else()
		set(${__OUT_LINK_TO_DEPENDEE} "0" PARENT_SCOPE)
	endif()
endfunction()

__prepare_template_list()


