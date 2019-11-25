# _get_variables(<path to targets.cmake> <out_arguments_prefix> <out_template_names> <out_DEFINE_EXTERNAL_PROJECT> <Args...>)
#
# Parses targets.cmake and gets the actual value of the variables based on the 
# 1. defaults declared in targets.cmake,
# 2. overriden by pre-existing CMake variables which names matches the declared parameters in the targets.cmake
# 3. overriden by named arguments passed in Args... .
# The values are checked for validity and stored in the standard format in prefix out_arguments_prefix. 
# Moreover it saves template names declared in the targets.cmake (in ${out_template_names}) and information about external project in ${out_external}.
#
# The algorithm allows for default values for parameters to be dependent on other variables, which allows to encode parameter transformation logic, because the
# values for the variables will be taken _after_ injecting the cached variables and - which is non trivial - the arguments Args... (which override everything).
#
# Moreover, the mentioned algorithm is run several times, as long as the names of the variables stabilise. That means, that variable defined as 
#
# set(LINK_PARAMETERS 
#	NEVER_ENDING_INTEGER	SCALAR	INTEGER "${NEVER_ENDING_INTEGET}+1")
#
# Will never parse, because on each run of the algorithm the value for NEVER_ENDING_INTEGET will be different. 
#
# But this is usefull for e.g.
#
# if("${MY_OTHER_ARG}" STREQUAL "1" )
#	set(TMP "SINGULAR")
# else()
#	set(TMP "PLURAL")
# endif()
#
# set(LINK_PARAMETERS 
#	MY_OTHER_ARG	SCALAR	INTEGER 1
#	ARG	SCALAR	CHOICE(SINGULAR;PLURAL) ${TMP}
# )
function(_get_variables __TARGETS_CMAKE_PATH __CALLING_FILE __ARGS_IN __FLAG_VERIFY __FLAG_IGNORE_INCLUDE_ERRORS __FLAG_IGNORE_CACHE_VARIABLES __OUT_VARIABLE_DIC __OUT_PARAMETERS_DIC __OUT_TEMPLATE_NAMES __OUT_EXTERNAL_PROJECT_INFO __OUT_IS_TARGET_FIXED __OUT_GLOBAL_OPTIONS)
	set(__ARGUMENT_HASH)
	set(__ITERATION_COUNT 0)

	set(__ARGUMENT_HASH_OLD "")
	set(__ARG_LIST "${ARGN}")
	set(__OVERRIDEN_ARGS "") #List of all args that are non-default
#	message(STATUS "${__PADDING}_get_variables(): ARGN: ${ARGN}")

#	set(__DEBUG_VAR_NAME TEST_NAME)
	set(__DEBUG_VAR_NAME )
	if(NOT "${__DEBUG_VAR_NAME}" STREQUAL "")
#__FLAG_IGNORE_CACHE_VARIABLES
		message(STATUS "${__PADDING}_get_variables(): DEBUG_RUN for ${__DEBUG_VAR_NAME}. __FLAG_IGNORE_CACHE_VARIABLES: ${__FLAG_IGNORE_CACHE_VARIABLES}")
		message(STATUS "${__PADDING}_get_variables(): __ARGS_${__DEBUG_VAR_NAME} is set to ${__ARGS_${__DEBUG_VAR_NAME}}")
		message(STATUS "${__PADDING}_get_variables(): ${__DEBUG_VAR_NAME}: ${${__DEBUG_VAR_NAME}}")
		message(STATUS "${__PADDING}_get_variables(): __ARG_LIST: ${__ARG_LIST}")
	endif()
#	message(STATUS "${__PADDING}_get_variables(): __ARGS_IN: ${__ARGS_IN}: ${${__ARGS_IN}__LIST} __TARGETS_CMAKE_PATH: ${__TARGETS_CMAKE_PATH}")
#	message(STATUS "${__PADDING}_get_variables(): __TARGETS_CMAKE_PATH: ${__TARGETS_CMAKE_PATH} __CALLING_FILE: ${__CALLING_FILE}")
	foreach(__ITERATION RANGE 10)
		if(NOT "${__DEBUG_VAR_NAME}" STREQUAL "")
			message(STATUS "${__PADDING}_get_variables(): __ITERATION: ${__ITERATION}, beggining of the loop, __ARGS_${__DEBUG_VAR_NAME}: ${__ARGS_${__DEBUG_VAR_NAME}}")
		endif()
		set_property(GLOBAL PROPERTY __BURAK_VARIABLES_NOT_ADDED 0)



	   #Reads parameters from targets.cmake.
		if(${__ITERATION} EQUAL 0)
			_read_parameters("${__TARGETS_CMAKE_PATH}" "${__ARGS_IN}" __PARS __ARGS __IN_TEMPLATE_NAMES __IN_EXTERNAL_PROJECT_INFO __IN_IS_TARGET_FIXED __GLOBAL_OPTIONS)
			if(__FLAG_IGNORE_CACHE_VARIABLES)
    		    _blank_variables(__PARS__LIST "")
    		endif()
 			if(NOT "${__DEBUG_VAR_NAME}" STREQUAL "")
 			   if(NOT "${__DEBUG_VAR_NAME}" IN_LIST __PARS__LIST)
      			message(STATUS "${__PADDING}_get_variables(): NOT debugging variable ${__DEBUG_VAR_NAME} here.")
		      	set(__DEBUG_VAR_NAME )
            endif()
 			endif()

		else()
			_read_parameters("${__TARGETS_CMAKE_PATH}" __ARGS __PARS __ARGS __IN_TEMPLATE_NAMES __IN_EXTERNAL_PROJECT_INFO __IN_IS_TARGET_FIXED __GLOBAL_OPTIONS)
		endif()
		if(NOT "${__DEBUG_VAR_NAME}" STREQUAL "")
			message(STATUS "${__PADDING}_get_variables(): __ITERATION: ${__ITERATION}, after parsing cmake, __ARGS_${__DEBUG_VAR_NAME}: ${__ARGS_${__DEBUG_VAR_NAME}}")
			message(STATUS "${__PADDING}_get_variables(): __PARS_${__DEBUG_VAR_NAME}__TYPE: ${__PARS_${__DEBUG_VAR_NAME}__TYPE}")
			message(STATUS "${__PADDING}_get_variables(): __PARS_${__DEBUG_VAR_NAME}__CONTAINER: ${__PARS_${__DEBUG_VAR_NAME}__CONTAINER}")
			message(STATUS "${__PADDING}_get_variables(): __PARS_${__DEBUG_VAR_NAME}: ${__PARS_${__DEBUG_VAR_NAME}}")
			message(STATUS "${__PADDING}_get_variables(): __ARGS_${__DEBUG_VAR_NAME}: ${__ARGS_${__DEBUG_VAR_NAME}}")
		endif()

		if(NOT __PARS__LIST)
			if(__ARG_LIST)
				message(FATAL_ERROR "Passed variables ${__ARG_LIST} to the target ${__TARGETS_CMAKE_PATH} from ${__CALLING_FILE} when the target does not accept any kind of parameters")
			endif()
			break() #no variables
		endif()



	   #Reads parameters from cache
      _read_variables_from_cache(__PARS __ARGS "" cache __ARGS)
	       if(NOT "${__DEBUG_VAR_NAME}" STREQUAL "")
		       message(STATUS "${__PADDING}_get_variables(): __ITERATION: ${__ITERATION}, after reading from cache, __ARGS_${__DEBUG_VAR_NAME}: ${__ARGS_${__DEBUG_VAR_NAME}}")
	       endif()
#			message(STATUS "${__PADDING}_get_variables(): ARGN: ${__ARG_LIST}")


      #Reads parameters from args. These have the highest priority and cannot be overriden.
		_read_variables_from_args(__PARS __ARGS "${__CALLING_FILE}" "${__TARGETS_CMAKE_PATH}" __ARGS ${__ARG_LIST})
			if(NOT "${__DEBUG_VAR_NAME}" STREQUAL "")
   			message(STATUS "${__PADDING}_get_variables(): __ITERATION: ${__ITERATION}, after reading from args, __ARGS_${__DEBUG_VAR_NAME}: ${__ARGS_${__DEBUG_VAR_NAME}}, ARGN: ${ARGN}")
   		endif()
#			message(STATUS "${__PADDING}_get_variables(): __ARGS__SRC_BCTYPE: ${__ARGS__SRC_BCTYPE}")
		_calculate_hash(__ARGS __ARGS__LIST "_getvars_" __ARGUMENT_HASH_NEW __HASH_SOURCE)
		
      if(NOT "${__DEBUG_VAR_NAME}" STREQUAL "")
		   message(STATUS "${__PADDING}_get_variables(): __ARGUMENT_HASH_OLD: ${__ARGUMENT_HASH_OLD}, __ARGUMENT_HASH_NEW: ${__ARGUMENT_HASH_NEW}, __HASH_SOURCE: ${__HASH_SOURCE}")
		endif()
		if("${__ARGUMENT_HASH_NEW}" STREQUAL "${__ARGUMENT_HASH_OLD}")
			break()
		endif()
		set(__ARGUMENT_HASH_OLD "${__ARGUMENT_HASH_NEW}")
	endforeach()
	
	if(NOT "${__DEBUG_VAR_NAME}" STREQUAL "")
   	_serialize_variables(__ARGS __ARGS__LIST __TMP_SERIALIZED)
		message(STATUS "${__PADDING}_get_variables(): finally: ${__TMP_SERIALIZED}")
   endif()

	
	if(NOT __FLAG_IGNORE_INCLUDE_ERRORS)
		get_property(__ERROR_IN_INCLUDE GLOBAL PROPERTY __BURAK_VARIABLES_NOT_ADDED)
		if("${__ERROR_IN_INCLUDE}" STREQUAL "1")
			_get_relative_path("${__TARGETS_CMAKE_PATH}" __TARGETS_CMAKE_PATH_REL)
			message(FATAL_ERROR "Unable to include foreign parameters in ${__TARGETS_CMAKE_PATH_REL}")
		endif()
	endif()
	
#	if("${__TARGETS_CMAKE_PATH}" MATCHES "/serialbox.cmake")
#		message(WARNING "_get_variables(): __TARGETS_CMAKE_PATH: ${__TARGETS_CMAKE_PATH} __IN_EXTERNAL_PROJECT_INFO: ${__IN_EXTERNAL_PROJECT_INFO} __IN_TEMPLATE_NAMES: ${__IN_TEMPLATE_NAMES} __OUT_EXTERNAL_PROJECT_INFO: ${__OUT_EXTERNAL_PROJECT_INFO}")
#	else()
#		message(STATUS "${__PADDING}_get_variables(): __TARGETS_CMAKE_PATH: ${__TARGETS_CMAKE_PATH} __IN_EXTERNAL_PROJECT_INFO: ${__IN_EXTERNAL_PROJECT_INFO} __IN_TEMPLATE_NAMES: ${__IN_TEMPLATE_NAMES}")
#	endif()
	if(NOT "${__ARGUMENT_HASH_NEW}" STREQUAL "${__ARGUMENT_HASH_OLD}")
		_get_relative_path("${__TARGETS_CMAKE_PATH}" __TARGETS_CMAKE_PATH_REL)
		message(FATAL_ERROR "Could not converge the values of arguments after ${__ITERATION} iterations. Solution: make sure the variables' definitions don't form circular references in ${__TARGETS_CMAKE_PATH_REL}.")
	endif()
#	message(STATUS "${__PADDING}_get_variables(): __FLAG_VERIFY: ${__FLAG_VERIFY}")
	foreach(__VAR_NAME IN LISTS __PARS__LIST)
#			message(STATUS "${__PADDING}_get_variables(): Veryfying variable ${__VAR_NAME}")
		if("${__ARGS__SRC_${__VAR_NAME}}" STREQUAL "default")
			set(__SRC "as default parameter in ${__TARGETS_CMAKE_PATH}")
		elseif("${__ARGS__SRC_${__VAR_NAME}}" STREQUAL "cache")
			set(__SRC "as already set variable, perhaps in the calling CMakeLists.txt")
		elseif("${__ARGS__SRC_${__VAR_NAME}}" STREQUAL "args")
			set(__SRC "as explicitely set function named argument in the ${__CALLING_FILE}")
		else()
			message(FATAL_ERROR "Internal beetroot error: Unknown source of variable ${__VAR_NAME}: __ARGS__SRC_${__VAR_NAME}: ${__ARGS__SRC_${__VAR_NAME}}")
		endif()
		if("${__VAR_NAME}" IN_LIST __PARS__LIST_FEATURES)
			set(__BOOL_FEATURES 1)
		else()
			set(__BOOL_FEATURES 0)
		endif()
		if("${__ARGS__SRC_${__VAR_NAME}}" STREQUAL "default")
		   set(__ACTUAL_FLAG_VERIFY 0)
		else()
		   set(__ACTUAL_FLAG_VERIFY "${__FLAG_VERIFY}")
		endif()
		_verify_parameter("${__VAR_NAME}" "${__SRC}" "${__PARS_${__VAR_NAME}__CONTAINER}" "${__PARS_${__VAR_NAME}__TYPE}" "${__ARGS_${__VAR_NAME}}" ${__BOOL_FEATURES} "${__TARGETS_CMAKE_PATH}" "${__ACTUAL_FLAG_VERIFY}" __VAR_BETTER_VALUE)
#		message(STATUS "${__PADDING}_get_variables(): After verification of ${__VAR_NAME} \"${__ARGS_${__VAR_NAME}}\" -> \"${__VAR_BETTER_VALUE}\".")
		set(__ARGS_${__VAR_NAME} ${__VAR_BETTER_VALUE})
	endforeach()
	
	set(__ARGS__LIST_MODIFIERS ${__PARS__LIST_MODIFIERS})
	set(__ARGS__LIST_LINKPARS ${__PARS__LIST_LINKPARS})
	set(__ARGS__LIST_FEATURES ${__PARS__LIST_FEATURES})

	_pass_arguments_higher(__ARGS ${__OUT_VARIABLE_DIC})
	_pass_parameters_higher(__PARS ${__OUT_PARAMETERS_DIC})
	
	if(NOT "${__DEBUG_VAR_NAME}" STREQUAL "")
   	_serialize_variables(__ARGS __ARGS__LIST __TMP_SERIALIZED)
		message(STATUS "${__PADDING}_get_variables(): finally: ${__TMP_SERIALIZED}")
   endif()
	
	set(${__OUT_TEMPLATE_NAMES} "${__IN_TEMPLATE_NAMES}" PARENT_SCOPE)
	set(${__OUT_EXTERNAL_PROJECT_INFO} "${__IN_EXTERNAL_PROJECT_INFO}" PARENT_SCOPE)
	set(${__OUT_IS_TARGET_FIXED} "${__IN_IS_TARGET_FIXED}" PARENT_SCOPE)
	set(${__OUT_GLOBAL_OPTIONS} "${__GLOBAL_OPTIONS}" PARENT_SCOPE)
	
endfunction()

macro(_parse_parameters __DEFINITIONS __OUT_ARGS __OUT_PARS __TARGETS_CMAKE_PATH __BOOL_FEATURES)
#	set(__DEFINITIONS ${__DEFINITIONS})
	list(LENGTH ${__DEFINITIONS} __TMP)
	
#	message(STATUS "${__PADDING}_parse_parameters(), __DEFINITIONS=${${__DEFINITIONS}} ${__OUT_ARGS}__LIST: ${${__OUT_ARGS}__LIST}")
	math(EXPR __PARS_LENGTH "${__TMP} / 4 - 1")
	math(EXPR __PARS_CHECK "${__TMP} % 4")
	if(NOT "${__PARS_CHECK}" STREQUAL "0")
		message(FATAL_ERROR "Wrong number of elements in the PARAMETERS/FEATURES variable defined in ${__TARGETS_CMAKE_PATH}. Expected number of elements divisible by 4, but got ${__TMP} elements: ${${__DEFINITIONS}}")
	endif()
#	message(STATUS "${__PADDING}_parse_parameters(), __PARS_LENGTH=${__PARS_LENGTH}")
	if(NOT "${__TMP}" STREQUAL 0)
		set(__LIST)
		foreach(__VAR_NR RANGE "${__PARS_LENGTH}")
			math(EXPR __TMP "${__VAR_NR}*4")
			list(GET ${__DEFINITIONS} ${__TMP} __VAR_NAME )
			if( "${__VAR_NAME}" MATCHES "^_.*$")
				message(FATAL_ERROR "Cannot declare variables that start with underscore (like \"${__VARNAME}\"). Error encountered in ${__TARGETS_CMAKE_PATH}.")
			endif()
			if(NOT "${__VAR_NAME}" MATCHES "^[A-Za-z][A-Za-z0-9_]*$")
				message(FATAL_ERROR "Variables must start with the letter and consit only from letters, digits and underscores, not like \"${__VARNAME}\" encounterd in ${__TARGETS_CMAKE_PATH}.")
			endif()
			math(EXPR __TMP_CONTAINER "${__VAR_NR}*4 + 1")
			list(GET ${__DEFINITIONS} ${__TMP_CONTAINER} __TMP_CONTAINER)
			math(EXPR __TMP_TYPE "${__VAR_NR}*4 + 2")
			list(GET ${__DEFINITIONS} ${__TMP_TYPE} __TMP_TYPE)
			math(EXPR __TMP_DEFAULT "${__VAR_NR}*4 + 3")
			list(GET ${__DEFINITIONS} ${__TMP_DEFAULT} __TMP_DEFAULT)
			if("${__TMP_CONTAINER}" STREQUAL "VECTOR")
				string(REPLACE ":" ";" __TMP_DEFAULT "${__TMP_DEFAULT}")
			elseif("${__TMP_CONTAINER}" STREQUAL "OPTION")
				if("${__TMP_TYPE}" STREQUAL "")
					set(__TMP_TYPE BOOL)
				elseif(NOT "${__TMP_TYPE}" STREQUAL "BOOL")
					message(FATAL_ERROR "Type of the OPTION variable ${__VAR_NAME} defined in ${__TARGETS_CMAKE_PATH} must always be BOOL (or simply left empty like \"\").")
				endif()
			endif()
			if( "${__TMP_TYPE}" STREQUAL "BOOL")
				if(__TMP_DEFAULT)
					set(__TMP_DEFAULT 1)
				else()
					set(__TMP_DEFAULT 0)
				endif()
            endif()
			set(__SKIP 0)
#			if("${__VAR_NAME}" STREQUAL "LIB_MYVAR")
#				message(STATUS "${__PADDING}_parse_parameters(): ${__OUT_ARGS}_${__VAR_NAME}__CONTAINER: ${__TMP_CONTAINER} ${__OUT_ARGS}_${__VAR_NAME}__TYPE: ${__TMP_TYPE} ${__OUT_ARGS}_${__VAR_NAME}: ${__TMP_DEFAULT}")
#			endif()
			if("${__VAR_NAME}" IN_LIST ${__OUT_ARGS}__LIST)
#				message(STATUS "${__PADDING}_parse_parameters(): ${__OUT_PARS}_${__VAR_NAME}__CONTAINER: ${__TMP_CONTAINER} ${__OUT_PARS}_${__VAR_NAME}__TYPE: ${__TMP_TYPE} ${__OUT_ARGS}_${__VAR_NAME}: ${__TMP_DEFAULT}")
				if(NOT "${${__OUT_PARS}_${__VAR_NAME}__CONTAINER}" STREQUAL "${__TMP_CONTAINER}" OR
					NOT "${${__OUT_PARS}_${__VAR_NAME}__TYPE}" STREQUAL "${__TMP_TYPE}" OR
					NOT "${${__OUT_ARGS}_${__VAR_NAME}}" STREQUAL "${__TMP_DEFAULT}")
					_get_relative_path("${__TARGETS_CMAKE_PATH}" __NICE_PATH)
					message(FATAL_ERROR "Multiple definitions of the same variable/modifier (here: \"${__VAR_NAME}\") are not the same. One definition is a ${${__OUT_PARS}_${__VAR_NAME}__CONTAINER} of type ${${__OUT_PARS}_${__VAR_NAME}__TYPE} = \"${${__OUT_ARGS}_${__VAR_NAME}}\" and the other is a ${__TMP_CONTAINER} of type ${__TMP_TYPE} = \"${__TMP_DEFAULT}\". Modifiers and variables share the same namespace. Error encountered in ${__NICE_PATH}.")
				else()
					set(__SKIP 1)
				endif()
			endif()
			if(NOT __SKIP)
#				message(STATUS "${__PADDING}_parse_parameters(): exporting ${__OUT_PARS}_${__VAR_NAME}__CONTAINER: ${__TMP_CONTAINER} ${__OUT_PARS}_${__VAR_NAME}__TYPE: ${__TMP_TYPE} ${__OUT_ARGS}_${__VAR_NAME}: ${__TMP_DEFAULT}")
				set(${__OUT_PARS}_${__VAR_NAME}__CONTAINER ${__TMP_CONTAINER})
				set(${__OUT_PARS}_${__VAR_NAME}__TYPE ${__TMP_TYPE})
				set(${__OUT_ARGS}_${__VAR_NAME} ${__TMP_DEFAULT})
				set(${__OUT_PARS}_${__VAR_NAME}__DEFAULT ${__TMP_DEFAULT})
				set(${__OUT_ARGS}__SRC_${__VAR_NAME} default)
				list(APPEND ${__OUT_ARGS}__LIST "${__VAR_NAME}")
				list(APPEND ${__OUT_PARS}__LIST "${__VAR_NAME}")
			endif()
#			message(STATUS "${__PADDING}_parse_parameters(): Found variable ${__VAR_NAME} with container ${__OUT_PARS}_${__VAR_NAME}__CONTAINER: ${${__OUT_PARS}_${__VAR_NAME}__CONTAINER}")
		endforeach()
	endif()
endmacro()

# Reads, parses and checks parameter definition from targets.cmake.
# Also initializes argument list with the default value of each parameter.
function(_read_parameters __TARGETS_CMAKE_PATH __EXISTING_ARGS __OUT_PARAMETERS_PREFIX __OUT_ARGUMENTS_PREFIX __OUT_TEMPLATE_NAMES __OUT_EXTERNAL_PROJECT_INFO __OUT_IS_TARGET_FIXED __OUT_GLOBAL_OPTIONS)
	if(__EXISTING_ARGS)
		_instantiate_variables(${__EXISTING_ARGS} "" "${${__EXISTING_ARGS}__LIST}" )
	endif()
	_read_targets_file("${__TARGETS_CMAKE_PATH}" 0 __READ_PREFIX __IS_TARGET_FIXED)
	

	set(${__OUT_ARGUMENTS_PREFIX}__LIST)
	set(${__OUT_PARAMETERS_PREFIX}__LIST_MODIFIERS)
	set(${__OUT_PARAMETERS_PREFIX}__LIST_FEATURES)
	set(${__OUT_PARAMETERS_PREFIX}__LIST_LINKPARS)

	set(${__OUT_PARAMETERS_PREFIX}__LIST)
#	message(STATUS "${__PADDING}_read_parameters(): __READ_PREFIX_LINK_PARAMETERS: ${__READ_PREFIX_LINK_PARAMETERS}")
	
	_parse_parameters(__READ_PREFIX_BUILD_PARAMETERS ${__OUT_ARGUMENTS_PREFIX} ${__OUT_PARAMETERS_PREFIX} "${__TARGETS_CMAKE_PATH}" 0)
	
#	message(STATUS "${__PADDING}_read_parameters(): __READ_PREFIX_BUILD_PARAMETERS: ${__READ_PREFIX_BUILD_PARAMETERS}")
#	message(STATUS "${__PADDING}_read_parameters(): ${__OUT_PARAMETERS_PREFIX}__LIST: ${${__OUT_PARAMETERS_PREFIX}__LIST}")
	set(${__OUT_PARAMETERS_PREFIX}__LIST_MODIFIERS "${${__OUT_PARAMETERS_PREFIX}__LIST}")


	set(${__OUT_PARAMETERS_PREFIX}__LIST)
	_parse_parameters(__READ_PREFIX_BUILD_FEATURES ${__OUT_ARGUMENTS_PREFIX} ${__OUT_PARAMETERS_PREFIX} "${__TARGETS_CMAKE_PATH}" 1)
	set(${__OUT_PARAMETERS_PREFIX}__LIST_FEATURES "${${__OUT_PARAMETERS_PREFIX}__LIST}")
	list_intersect(__INTERSECT ${__OUT_PARAMETERS_PREFIX}__LIST_MODIFIERS ${__OUT_PARAMETERS_PREFIX}__LIST_FEATURES)
	if(__INTERSECT)
		message(FATAL_ERROR "The parameters ${__INTERSECT} are defined both in BUILD_PARAMETERS and BUILD_FEATURES. Parameters in BUILD_FEATURES, BUILD_PARAMETERS and LINK_PARAMETERS share the same namespace and it is illegal to re-define already defined parameter.")
	endif()

	set(${__OUT_PARAMETERS_PREFIX}__LIST)
	_parse_parameters(__READ_PREFIX_LINK_PARAMETERS ${__OUT_ARGUMENTS_PREFIX} ${__OUT_PARAMETERS_PREFIX} "${__TARGETS_CMAKE_PATH}" 0)
	set(${__OUT_PARAMETERS_PREFIX}__LIST_LINKPARS "${${__OUT_PARAMETERS_PREFIX}__LIST}")
	set(__LIST ${${__OUT_PARAMETERS_PREFIX}__LIST_MODIFIERS} ${${__OUT_PARAMETERS_PREFIX}__LIST_FEATURES})
	list_intersect(__INTERSECT __LIST ${__OUT_PARAMETERS_PREFIX}__LIST_LINKPARS)
	if(__INTERSECT)
		message(FATAL_ERROR "The parameters ${__INTERSECT} are defined both in LINK_PARAMETERS and one of BUILD_PARAMETERS and BUILD_FEATURES. Parameters in BUILD_FEATURES, BUILD_PARAMETERS and LINK_PARAMETERS share the same namespace and it is illegal to re-define already defined parameter.")
	endif()
	
	set(${__OUT_PARAMETERS_PREFIX}__LIST ${${__OUT_PARAMETERS_PREFIX}__LIST_MODIFIERS} ${${__OUT_PARAMETERS_PREFIX}__LIST_FEATURES} ${${__OUT_PARAMETERS_PREFIX}__LIST_LINKPARS})
	
	_pass_arguments_higher(${__OUT_ARGUMENTS_PREFIX} ${__OUT_ARGUMENTS_PREFIX})
	_pass_parameters_higher(${__OUT_PARAMETERS_PREFIX} ${__OUT_PARAMETERS_PREFIX})
	
	
	set(${__OUT_TEMPLATE_NAMES} "${__READ_PREFIX_ENUM_TEMPLATES}" PARENT_SCOPE)
	set(${__OUT_EXTERNAL_PROJECT_INFO} "${__READ_PREFIX_DEFINE_EXTERNAL_PROJECT}" PARENT_SCOPE)
	set(${__OUT_IS_TARGET_FIXED} "${__IS_TARGET_FIXED}" PARENT_SCOPE)
	set(${__OUT_GLOBAL_OPTIONS} "${__READ_PREFIX_FILE_OPTIONS}" PARENT_SCOPE)
endfunction()

# _read_variables_from_cache(__PARS __ARGS __VALUES __OUT_ARGS)
#
# Iterates over all variables in __PARS, and combines the values taken from __ARGS with overrides taken as the same name, but with optional prefix "${__VALUES}_".
function(_read_variables_from_cache __PARS __ARGS __VALUES __SOURCE __OUT_ARGS)
	foreach(__VAR IN LISTS ${__PARS}__LIST)
	   if("${__VALUES}" STREQUAL "")
	      set(__EXT_VARNAME ${__VAR})
	   else()
   	   set(__EXT_VARNAME ${__VALUES}_${__VAR})
	   endif()
		if(NOT "${${__EXT_VARNAME}}" STREQUAL "")
			set(${__OUT_ARGS}_${__VAR} "${${__EXT_VARNAME}}" PARENT_SCOPE)
#			message(STATUS "${__PADDING}_read_variables_from_cache(): ${__EXT_VARNAME}: ${${__EXT_VARNAME}} != 0, so setting ${__OUT_ARGS}__SRC_${__VAR}: ${__SOURCE}")
			set(${__OUT_ARGS}__SRC_${__VAR} "${__SOURCE}" PARENT_SCOPE)
		else()
			set(${__OUT_ARGS}_${__VAR} "${${__ARGS}_${__VAR}}" PARENT_SCOPE)
		endif()
	endforeach()
	set(${__OUT_ARGS}__LIST "${${__ARGS}__LIST}" PARENT_SCOPE)
endfunction()

function(_verify_parameter NAME CONTEXT CONTAINER TYPE VALUE IS_FEATURE __TARGETS_CMAKE_PATH __FLAG_THROW_ERRORS __OUT2_BETTER_VALUE)
#When IS_FEATURE is set, there is smaller set of valid type+container combinations
	set(VALID_CONTAINERS OPTION SCALAR VECTOR)
	set(VALID_TYPES INTEGER PATH VERSION STRING BOOL)
	if(NOT "${TYPE}" MATCHES "^CHOICE\(.+\)$" AND NOT "${TYPE}" IN_LIST VALID_TYPES)
	    if(__FLAG_THROW_ERRORS)
    		message(FATAL_ERROR "Wrong type for variable ${NAME} ${CONTEXT} in ${__TARGETS_CMAKE_PATH}. Must be INTEGER, PATH, VERSION, STRING or CHOICE(opt1,opt2,...,optN) format, but got ${TYPE}")
        else()
            set(${__OUT2_BETTER_VALUE} ${VALUE} PARENT_SCOPE)
            return()
        endif()
	endif()
	if(NOT "${CONTAINER}" IN_LIST VALID_CONTAINERS)
	    if(__FLAG_THROW_ERRORS)
    		message(FATAL_ERROR "Wrong container for variable ${NAME} ${CONTEXT} in ${__TARGETS_CMAKE_PATH}. Container must be one of OPTION SCALAR or VECTOR, but got ${CONTAINER}")
        else()
            set(${__OUT2_BETTER_VALUE} ${VALUE} PARENT_SCOPE)
            return()
        endif()
	endif()
	if("${CONTAINER}" STREQUAL "OPTION")
		if(NOT "${TYPE}" STREQUAL "BOOL")
			message(FATAL_ERROR "Container OPTION can only contain boolean variables. Please specify type of the variable as BOOL in the definition of ${NAME} ${CONTEXT}")
		endif()
		_verify_value("${NAME}" "${CONTEXT}" BOOL "${VALUE}" "${IS_FEATURE}" "${__TARGETS_CMAKE_PATH}" "${__FLAG_THROW_ERRORS}" BETTER_VALUE)
	else()
	    set(BETTER_VALUE)
		foreach(VAL IN LISTS VALUE)
			_verify_value("${NAME}" "${CONTEXT}" "${TYPE}" "${VAL}" "${IS_FEATURE}" "${__TARGETS_CMAKE_PATH}" "${__FLAG_THROW_ERRORS}" IN_BETTER_VALUE)
			list(APPEND BETTER_VALUE ${IN_BETTER_VALUE} )
#        	message(STATUS "${__PADDING}_verify_parameter(): VALUE: ${VALUE}, IN_BETTER_VALUE: ${IN_BETTER_VALUE}")
		endforeach()

	endif()
	set(${__OUT2_BETTER_VALUE} ${BETTER_VALUE} PARENT_SCOPE)
endfunction()

function(_verify_value NAME CONTEXT TYPE VALUE IS_FEATURE __TARGETS_CMAKE_PATH __FLAG_THROW_ERRORS __VER_BETTER_VALUE)
#	message(STATUS "${__PADDING}_verify_value(): __VER_BETTER_VALUE:  ${__VER_BETTER_VALUE}")
	if("${TYPE}" STREQUAL "INTEGER")
		if(NOT "${VALUE}" MATCHES "^[0-9]+$")
    	    if(__FLAG_THROW_ERRORS)
    			message(FATAL_ERROR "Wrong value of the variable ${NAME} ${CONTEXT}. Expected integer, but got ${VALUE}")
            else()
                set(${__VER_BETTER_VALUE} "${VALUE}" PARENT_SCOPE)
                return()
            endif()
		endif()
	elseif("${TYPE}" STREQUAL "VERSION")
		if(NOT "${VALUE}" MATCHES "^[0-9]+(\\.[0-9]+(\\.[0-9]+)?)?$")
    	    if(__FLAG_THROW_ERRORS)
    			message(FATAL_ERROR "Wrong value of the variable ${NAME} ${CONTEXT}. Expected version with format <int>[.<int>[.<int>]], but got ${VALUE}")
            else()
                set(${__VER_BETTER_VALUE} "${VALUE}" PARENT_SCOPE)
                return()
            endif()
		endif()
	elseif("${TYPE}" STREQUAL "BOOL")
		set(VALID_YES 1 ON YES TRUE Y)
		set(VALID_NO 0 OFF NO FALSE N IGNORE NOTFOUND)
#		if ("${VALUE}" MATCHES "^[1-9][0-9]*$")
#		    set(${__VER_BETTER_VALUE} ${VALUE} PARENT_SCOPE)
#			return() #OK, yes
#		endif()
		if("${VALUE}" IN_LIST VALID_YES)
		    set(${__VER_BETTER_VALUE} "1" PARENT_SCOPE)
#        	message(STATUS "${__PADDING}_verify_value(): Got valid YES response for ${NAME} and storing it in ${__VER_BETTER_VALUE}")
			return() #OK, yes
		endif()
		if("${VALUE}" IN_LIST VALID_NO OR "${VALUE}" STREQUAL "")
#        	message(STATUS "${__PADDING}_verify_value(): Got valid NO response for ${NAME} and storing it in ${__VER_BETTER_VALUE}")
		    set(${__VER_BETTER_VALUE} "0" PARENT_SCOPE)
			return() #OK, no
		endif()
	    if(__FLAG_THROW_ERRORS)
    		message(FATAL_ERROR "Wrong value of the variable ${NAME} ${CONTEXT} in ${__TARGETS_CMAKE_PATH}. Expected BOOL, but got ${VALUE}")
        else()
            set(${__VER_BETTER_VALUE} "${VALUE}" PARENT_SCOPE)
            return()
        endif()
	elseif("${TYPE}" STREQUAL "STRING")
	    set(${__VER_BETTER_VALUE} "${VALUE}" PARENT_SCOPE)
		return() #String is always ok
	elseif("${TYPE}" STREQUAL "PATH")
	    set(${__VER_BETTER_VALUE} "${VALUE}" PARENT_SCOPE)
		return() #Path is always ok - for now...;-)
	else()
#		message(FATAL_ERROR "string(REGEX_MATCH \"^CHOICE\\((.*)\\)$\" CHOICES \"${TYPE}\")")
		string(REGEX REPLACE "^CHOICE\\((.*)\\)$" "\\1" CHOICES "${TYPE}")
		if(NOT CHOICES)
    	    if(__FLAG_THROW_ERRORS)
    			message(FATAL_ERROR "Wrong format of type: ${TYPE} ${CONTEXT} for variable ${NAME}.")
            else()
                set(${__VER_BETTER_VALUE} ${VALUE} PARENT_SCOPE)
                return()
            endif()
		endif()
		string(REPLACE ":" ";" CHOICES_LIST "${CHOICES}")
		if(NOT "${VALUE}" IN_LIST CHOICES_LIST)
	        if(__FLAG_THROW_ERRORS)
    			message(FATAL_ERROR "Value \"${VALUE}\" of the variable ${NAME} in ${__TARGETS_CMAKE_PATH} not in choices ${CHOICES_LIST}")
            else()
                set(${__VER_BETTER_VALUE} ${VALUE} PARENT_SCOPE)
                return()
            endif()
		endif()
	endif()
    set(${__VER_BETTER_VALUE} ${VALUE} PARENT_SCOPE)
endfunction()

function(_read_variables_from_args __PARS __ARGS __CALLING_FILE __TARGETS_CMAKE_PATH __OUT_ARGS)
	set(__OPTIONS)
	set(__oneValueArgs )
	set(__multiValueArgs)
	
	foreach(__PAR IN LISTS ${__PARS}__LIST)
		if("${${__PARS}_${__PAR}__CONTAINER}" STREQUAL "OPTION")
			list(APPEND __OPTIONS ${__PAR})
		elseif("${${__PARS}_${__PAR}__CONTAINER}" STREQUAL "SCALAR")
			list(APPEND __oneValueArgs ${__PAR})
		elseif("${${__PARS}_${__PAR}__CONTAINER}" STREQUAL "VECTOR")
			list(APPEND __multiValueArgs ${__PAR})
		else()
			message(FATAL_ERROR "Wrong type of container (${__PARS}_${__PAR}__CONTAINER = ${${__PARS}_${__PAR}__CONTAINER}) for variable ${__PAR}")
		endif()
	endforeach()
	
	cmake_parse_arguments(__PARSED "${__OPTIONS}" "${__oneValueArgs}" "${__multiValueArgs}" ${ARGN})
#	message(STATUS "${__PADDING}_read_variables_from_args(): __multiValueArgs:${__multiValueArgs} __oneValueArgs: ${__oneValueArgs}" __OPTIONS: ${__OPTIONS})
	if(__DEBUG_VAR_NAME)
		message(STATUS "${__PADDING}_read_variables_from_args(): __PARSED_${__DEBUG_VAR_NAME}: ${__PARSED_${__DEBUG_VAR_NAME}}")
	endif()

	set(__unparsed ${__PARSED_UNPARSED_ARGUMENTS})
	if(__unparsed)
		_get_relative_path("${__CALLING_FILE}" __CALLING_FILE_REL)
		_get_relative_path("${__TARGETS_CMAKE_PATH}" __TARGETS_CMAKE_PATH_REL)
		message(FATAL_ERROR "Undefined variables passed as arguments: ${__unparsed}. Solution: Either add support for arguments \"${__unparsed}\" in ${__TARGETS_CMAKE_PATH_REL}, or change the dependency arguments in ${__CALLING_FILE_REL}. ")
	endif()
	foreach(__OPTION IN LISTS __OPTIONS)
		if(__ARGS_${__OPTION})
			set(__PARSED_${__OPTION} 1)
		endif()
	endforeach()
#	message(FATAL_ERROR "${__ARGS}__LIST: ${${__ARGS}__LIST}")
	_read_variables_from_cache(${__PARS} ${__ARGS} __PARSED "args" __IN_ARGS)
#	message(STATUS "${__PADDING}_read_variables_from_args(): __OUT_ARGS: ${__OUT_ARGS} __PARSED_WHO: ${__PARSED_WHO} __IN_ARGS_WHO: ${__IN_ARGS_WHO} ${__ARGS}__LIST: ${${__ARGS}__LIST} ")
#	message(FATAL_ERROR "__IN_ARGS__LIST: ${__IN_ARGS__LIST}")
	_pass_arguments_higher(__IN_ARGS ${__OUT_ARGS})
endfunction()

