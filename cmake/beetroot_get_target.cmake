#Expects the target described by the target properties already exists, and it simply brings it.
#It will never define a new target. User can parametrize it with features or target parameters. In latter case it will 
#act as a filter that limits compatibility with the existing targets
function(get_existing_target __TEMPLATE_NAME)
	_get_target_behavior(__GET_TARGET_BEHAVIOR)
	get_property(__CALLING_FILE GLOBAL PROPERTY __BURAK_CALLEE_PATH)
	if("${__CALLING_FILE}" STREQUAL "")
		set(__CALLING_FILE "${CMAKE_PARENT_LIST_FILE}")
	endif()

	file(RELATIVE_PATH __CALLING_FILE ${SUPERBUILD_ROOT} ${__CALLING_FILE})
#	message(STATUS "${__PADDING}get_existing_target(): __CALLING_FILE: ${__CALLING_FILE}")
#	message(STATUS "${__PADDING}get_existing_target(): Called get_existing_target(${__TEMPLATE_NAME}) on phase ${__GET_TARGET_BEHAVIOR}")
	if("${__GET_TARGET_BEHAVIOR}" STREQUAL "INSIDE_GENERATE_TARGETS")
		message(FATAL_ERROR "Calling get_existing_target from inside generate_targets is disallowed. To call dependency use declare_dependencies() (in which you cannot define targets).")
	endif()
	if(NOT __TEMPLATE_NAME)
		message(FATAL_ERROR "get_error was called without any arguments")
	endif()
	string(REPLACE "-" "_" __TEMPLATE_NAME "${__TEMPLATE_NAME}")

	_parse_TARGETS_PATH("${__TEMPLATE_NAME}" "${__CALLING_FILE}" ${ARGN})

#	__rename_arguments(${__PARENT_ARGS_PREFIX} __DEFAULT_ARGS)
	
	_get_variables("${__TARGETS_CMAKE_PATH}" "${__CALLING_FILE}" "" 1 0 __VARIABLE_DIC __PARAMETERS_DIC __TEMPLATES __EXTERNAL_PROJECT_INFO__LIST __IS_TARGET_FIXED __FILE_OPTIONS__LIST ${ARGN}) #Stores and verifies all immidiate parameters into the __VARIABLE_DIC arg structure and __PARAMETERS_DIC declarations.
	_serialize_variables(__VARIABLE_DIC __VARIABLE_DIC__LIST_MODIFIERS __TMP_MODIFIERS)
	_serialize_variables(__VARIABLE_DIC __PARAMETERS_DIC__LIST_LINKPARS __TMP_LINKPARS)
	_serialize_variables(__VARIABLE_DIC __PARAMETERS_DIC__LIST_FEATURES __TMP_FEATURES)
#	message(STATUS "${__PADDING}get_existing_target(): got the following modifiers: __TMP_MODIFIERS: ${__TMP_MODIFIERS}")
#	message(STATUS "${__PADDING}get_existing_target(): got the following linkpars: __TMP_LINKPARS: ${__TMP_LINKPARS}")
#	message(STATUS "${__PADDING}get_existing_target(): got the following features: __TMP_FEATURES: ${__TMP_FEATURES}")

#	message(STATUS "${__PADDING}get_existing_target(): __PARAMETERS_DIC_MYPAR__DEFAULT: ${__PARAMETERS_DIC_MYPAR__DEFAULT} __PARAMETERS_DIC_MYPAR__CONTAINER: ${__PARAMETERS_DIC_MYPAR__CONTAINER}")
	if(__PARENT_ARGS_PREFIX) #It will not be set if get_existing_target is called directly from CMakeLists.txt
		_remove_variables_with_default_value(__VARIABLE_DIC __PARAMETERS_DIC __VARIABLE_DIC__LIST_MODIFIERS __VARIABLE_DIC__LIST_MODIFIERS) #Removes all modifiers which value user has not changed in his declare_dependencies().
		_serialize_variables(__VARIABLE_DIC __VARIABLE_DIC__LIST_MODIFIERS __TMP_MODIFIERS)
#		message(STATUS "${__PADDING}get_existing_target(): after _remove_variables_with_default_value(): __TMP_MODIFIERS: ${__TMP_MODIFIERS}")
	endif()
 
#	_remove_default_variables(__VARIABLE_DIC __VARIABLE_DIC__LIST_MODIFIERS __VARIABLE_DIC__LIST_MODIFIERS)
#	_serialize_variables(__VARIABLE_DIC __VARIABLE_DIC__LIST_MODIFIERS __TMP_MODIFIERS)
#	message(STATUS "${__PADDING}get_existing_target(): after _remove_default_variables(): __TMP_MODIFIERS: ${__TMP_MODIFIERS}")
	
	if(__PARENT_ALL_VARIABLES)
#		message(STATUS "${__PADDING}get_existing_target(): XXXXX __TEMPLATE_NAME: ${__TEMPLATE_NAME} __DEFAULT_ARGS: ${__DEFAULT_ARGS}  FLOAT_PRECISION: ${FLOAT_PRECISION}")
		_blank_variables(__PARENT_ALL_VARIABLES __VARIABLE_DIC__LIST) #Blanks all variables that may have been set by dependee's declare_dependencies().
#		_serialize_variables(__VARIABLE_DIC __VARIABLE_DIC__LIST __SERIALIZED_VARIABLES)
#		message(STATUS "${__PADDING}get_existing_target(): after _blank_variables __TEMPLATE_NAME: ${__TEMPLATE_NAME} __SERIALIZED_VARIABLES: ${__SERIALIZED_VARIABLES}")
	endif()
	
	_serialize_variables(__VARIABLE_DIC __VARIABLE_DIC__LIST_MODIFIERS __TMP_MODIFIERS)
#	message(STATUS "${__PADDING}get_existing_target(): modifiers after removal of deafaults: __TMP_MODIFIERS: ${__TMP_MODIFIERS}")

	_make_instance_id(${__TEMPLATE_NAME} __VARIABLE_DIC 1 __INSTANCE_ID __HASH_SOURCE) 
#	message(STATUS "${__PADDING}get_existing_target(): got __INSTANCE_ID: ${__INSTANCE_ID} from __TEMPLATE_NAME: ${__TEMPLATE_NAME} __HASH_SOURCE: ${__HASH_SOURCE}")
#	if("${__TEMPLATE_NAME}" STREQUAL "GridTools::gridtools")
#		message(WARNING "GridTools::gridtools ### __INSTANCE_ID: ${__INSTANCE_ID} i __HASH_SOURCE: ${__HASH_SOURCE}")
#		message(FATAL_ERROR "TODO: Gdy rejestruje się instance (który może być singletonem), to w celu policzenia INSTANCE_ID przyjmowane są jakieś target parametry - w przypadku gridtools to jest precision=4, bo tak jest domyślnie. Potem należy je zamienić na precision=8, ale niestety niektóre właściwości nie pozwalają na to - np. zapisana ścieżka instalacji, która zawiera external_id, który zależy od tych niefortunnych (i pewnie nigdy nie używanych) wartości paramertrów ")
#	endif()
#	message(STATUS "${__PADDING}get_existing_target(): __TEMPLATE_NAME ${__TEMPLATE_NAME} got __INSTANCE_ID: ${__INSTANCE_ID}. DWARF: ${DWARF} ")
	if("${__GET_TARGET_BEHAVIOR}" STREQUAL "GATHERING_DEPENDENCIES" OR "${__GET_TARGET_BEHAVIOR}" STREQUAL "OUTSIDE_SCOPE")
		#Add dependencies together with their arguments to the list. They will be instatiated later on, during generate_targets run
		_put_dependencies_into_stack("${__INSTANCE_ID}")
		_can_descend_recursively(${__INSTANCE_ID} DEPENDENCIES __CAN_DESCEND)
		if(NOT __CAN_DESCEND)
			_get_recurency_list(DEPENDENCIES __FEATUREBASE_LIST)
			_get_nice_featurebase_names("{__FEATUREBASE_LIST}" __OUTVAR)
			message(FATAL_ERROR "Cyclic dependency graph encountered (in the calling order): ${__OUTVAR}")
		endif()

		if("${__GET_TARGET_BEHAVIOR}" STREQUAL "OUTSIDE_SCOPE")
			set(__TARGET_REQUIRED 1)
		else()
			set(__TARGET_REQUIRED 0)
		endif()


#		_descend_dependencies_stack()
#		_ascend_dependencies_stack()
		
#		_get_parent_dependency_from_stack(__PARENT_INSTANCE_ID)
#		message(STATUS "${__PADDING}get_existing_target(): __PARENT_INSTANCE_ID: ${__PARENT_INSTANCE_ID}")
		
#		message(STATUS "${__PADDING}get_existing_target(): _store_instance_link_data(${__INSTANCE_ID} \"${__PARENT_INSTANCE_ID}\" __VARIABLE_DIC __PARAMETERS_DIC ${__TEMPLATE_NAME} ${__TARGETS_CMAKE_PATH} ${__IS_TARGET_FIXED})")
		_store_virtual_instance_data(
			${__INSTANCE_ID} 
			__VARIABLE_DIC 
			__PARAMETERS_DIC 
			${__TEMPLATE_NAME} 
			"${__TARGETS_CMAKE_PATH}" 
			${__IS_TARGET_FIXED}
			__EXTERNAL_PROJECT_INFO
			${__TARGET_REQUIRED}  
			__FILE_OPTIONS 
			"${__TEMPLATES}" 
			__FILE_HASH
		)

#		_store_instance_link_data(
#			 ${__INSTANCE_ID}
#			"${__PARENT_INSTANCE_ID}"
#			__VARIABLE_DIC 
#			__PARAMETERS_DIC
#			 ${__TEMPLATE_NAME} 
#			 ${__TARGETS_CMAKE_PATH} 
#			 ${__IS_TARGET_FIXED}
#			"${__TEMPLATES}"
#			 )

		_ascend_from_recurency(${__INSTANCE_ID} DEPENDENCIES)
#		message(STATUS "${__PADDING}get_existing_target(): __INSTANCE_ID: ${__INSTANCE_ID}")
#		_debug_show_instance(${__INSTANCE_ID} 2 "" __MESSAGE __ERROR)
#		message("${__MESSAGE}")
#		if(__ERROR)
#			message(FATAL_ERROR "${__ERROR}")
#		endif()
	elseif("${__GET_TARGET_BEHAVIOR}" STREQUAL "DEFINING_TARGETS") #in this phase get_target retrieves
#		if(NOT "${ARGV1}" STREQUAL "")
#			_retrieve_instance_data(${__INSTANCE_ID} I_TARGET_NAME __TARGET_NAME)
#			if("${__TARGET_NAME}" STREQUAL "")
#				message(FATAL_ERROR "Cannot retrieve target name of ${__TEMPLATE_NAME}. Are you sure you do not request target name of the dependee or unrelated target?")
#			endif()
#			set(__OUT ${ARGV1})
#			if(__OUT)
#				set(${__OUT} "${__TARGET_NAME}" PARENT_SCOPE)
#			endif()
#		endif()
	else()
		message(FATAL_ERROR "Unknown global state __GET_TARGET_BEHAVIOR = \"${__GET_TARGET_BEHAVIOR}\"")
	endif()
endfunction()

function(build_target __TEMPLATE_NAME)
#	message(STATUS "${__PADDING}build_target(): __TEMPLATE_NAME: ${__TEMPLATE_NAME} ${ARGN}")
	get_target(${__TEMPLATE_NAME} __TMP_INSTANCE_NAME ${ARGN})
endfunction()

function(get_target __TEMPLATE_NAME __OUT) 
	_get_target_behavior(__GET_TARGET_BEHAVIOR)
	get_property(__CALLING_FILE GLOBAL PROPERTY __BURAK_CALLEE_PATH)
#	message(STATUS "get_target(): __TEMPLATE_NAME: ${__TEMPLATE_NAME} __CALLING_FILE: \"${__CALLING_FILE}\"")
	if("${__CALLING_FILE}" STREQUAL "")
		set(__CALLING_FILE "${CMAKE_PARENT_LIST_FILE}")
#		message(STATUS "get_target(): __TEMPLATE_NAME: ${__TEMPLATE_NAME} __CALLING_FILE: \"${__CALLING_FILE}\"")
	endif()
	file(RELATIVE_PATH __CALLING_FILE ${SUPERBUILD_ROOT} ${__CALLING_FILE})
#	message(STATUS "${__PADDING}get_existing_target(): __CALLING_FILE: ${__CALLING_FILE}")
#	message(STATUS "${__PADDING}get_target(): Called get_target(${__TEMPLATE_NAME}) on phase ${__GET_TARGET_BEHAVIOR}")
	if("${__GET_TARGET_BEHAVIOR}" STREQUAL "INSIDE_GENERATE_TARGETS")
		message(FATAL_ERROR "Calling get_target from inside generate_targets is disallowed. To call dependency use declare_dependencies() (in which you cannot define targets).")
	endif()
	if(NOT __TEMPLATE_NAME)
		message(FATAL_ERROR "get_error was called without any arguments")
	endif()
	string(REPLACE "-" "_" __TEMPLATE_NAME "${__TEMPLATE_NAME}")

	_parse_TARGETS_PATH("${__TEMPLATE_NAME}" "${__CALLING_FILE}" ${ARGN})
#	message(STATUS "${__PADDING}get_target(): __TEMPLATE_NAME: ${__TEMPLATE_NAME} USE_NETCDF: \"${USE_NETCDF}\" ARGN: ${ARGN}")
#	message(STATUS "${__PADDING}get_target(): __TEMPLATE_NAME: ${__TEMPLATE_NAME} ARGN: ${ARGN}")
	_get_variables("${__TARGETS_CMAKE_PATH}" "${__CALLING_FILE}" "" 1 0 __VARIABLE_DIC __PARAMETERS_DIC __TEMPLATES __EXTERNAL_PROJECT_INFO__LIST __IS_TARGET_FIXED __FILE_OPTIONS__LIST ${ARGN})
#	message(STATUS "${__PADDING}get_target(): __TEMPLATE_NAME: ${__TEMPLATE_NAME} __PARAMETERS_DIC_USE_NETCDF__TYPE: ${__PARAMETERS_DIC_USE_NETCDF__TYPE} __VARIABLE_DIC_USE_NETCDF: ${__VARIABLE_DIC_USE_NETCDF}")
	if(__PARENT_ALL_VARIABLES)
#		message(STATUS "${__PADDING}get_target(): XXXXX __TEMPLATE_NAME: ${__TEMPLATE_NAME} __PARENT_ALL_VARIABLES: ${__PARENT_ALL_VARIABLES}  FLOAT_PRECISION: ${FLOAT_PRECISION}")
		_blank_variables(__PARENT_ALL_VARIABLES __VARIABLE_DIC__LIST) #Blanks all variables that may have been set by dependee's declare_dependencies().
	endif()
#	if(__FILE_OPTIONS)
#		message(STATUS "${__PADDING}get_target(): __FILE_OPTIONS: ${__FILE_OPTIONS}")
#	endif()
	if("${__VARIABLE_DIC_VERSION}" STREQUAL "KUC")
		message(FATAL_ERROR "__VARIABLE_DIC_VERSION: ${__VARIABLE_DIC_VERSION}")
	endif()
	_make_instance_id(${__TEMPLATE_NAME} __VARIABLE_DIC 0 __INSTANCE_ID __HASH_SOURCE)
#		_serialize_variables(__VARIABLE_DIC __VARIABLE_DIC__LIST __SERIALIZED_VARIABLE_DIC)
#		message(STATUS "${__PADDING}get_target(): __TEMPLATE_NAME: ${__TEMPLATE_NAME} __INSTANCE_ID: ${__INSTANCE_ID} __SERIALIZED_VARIABLE_DIC: ${__SERIALIZED_VARIABLE_DIC}")
	if("${__GET_TARGET_BEHAVIOR}" STREQUAL "GATHERING_DEPENDENCIES" OR "${__GET_TARGET_BEHAVIOR}" STREQUAL "OUTSIDE_SCOPE")
		#Add dependencies together with their arguments to the list. They will be instatiated later on, during generate_targets run
#		message(STATUS "${__PADDING}get_target(): __TEMPLATE_NAME ${__TEMPLATE_NAME} got __INSTANCE_ID: ${__INSTANCE_ID} features: ${__PARAMETERS_DIC__LIST_FEATURES} modifiers: ${__PARAMETERS_DIC__LIST_MODIFIERS}" )
#		message(STATUS "${__PADDING}get_target(): __INSTANCE_ID: ${__INSTANCE_ID} list of params: ${__PARAMETERS_DIC__LIST}" )
#		message(STATUS "${__PADDING}get_target(): __INSTANCE_ID: ${__INSTANCE_ID} list of modifiers: ${__PARAMETERS_DIC__LIST_MODIFIERS}" )
		_discover_dependencies(${__INSTANCE_ID} ${__TEMPLATE_NAME} "${__TARGETS_CMAKE_PATH}" __VARIABLE_DIC __PARAMETERS_DIC __EXTERNAL_PROJECT_INFO ${__IS_TARGET_FIXED} __FILE_OPTIONS "${__TEMPLATES}" 1)
#		_debug_show_instance(${__INSTANCE_ID} 2 "" __MESSAGE __ERROR)
#		message("${__MESSAGE}")
#		if(__ERROR)
#			message(FATAL_ERROR "${__ERROR}")
#		endif()
		if(__OUT)
			set(${__OUT} "${__INSTANCE_NAME}" PARENT_SCOPE)
		endif()
	elseif("${__GET_TARGET_BEHAVIOR}" STREQUAL "DEFINING_TARGETS")
		_retrieve_instance_data(${__INSTANCE_ID} I_TARGET_NAME __TARGET_NAME)
		if("${__TARGET_NAME}" STREQUAL "")
			message(FATAL_ERROR "Cannot retrieve target name of ${__TEMPLATE_NAME}. Are you sure you do not request target name of the dependee or unrelated target or that the target parameters used for the match are the same as used in the declare dependencies?")
		endif()
		if(__OUT)
			set(${__OUT} "${__TARGET_NAME}" PARENT_SCOPE)
		endif()
	else()
		message(FATAL_ERROR "Unknown global state __GET_TARGET_BEHAVIOR = \"${__GET_TARGET_BEHAVIOR}\"")
	endif()
	
	if("${__GET_TARGET_BEHAVIOR}" STREQUAL "OUTSIDE_SCOPE")
#		message(STATUS "${__PADDING}_get_target() Linking ${__INSTANCE_ID} to global")
		_link_instances_together("" "${__INSTANCE_ID}")
	endif()
endfunction()

#Calls targets.cmake:generate_targets() to create the declared target during the project phase run of the CMake. 
#Does nothing on the SUPERBUILD phase, as the internal project dependencies are of no concern then.
function(_get_target_internal __INSTANCE_ID __OUT_FUNCTION_EXISTS)
#	message(STATUS "${__PADDING}_get_target_internal(): trying to instantiate ${__INSTANCE_ID}")
	if(NOT __NOT_SUPERBUILD)
		return()
	endif()
	_retrieve_instance_data(${__INSTANCE_ID} I_TEMPLATE_NAME __TEMPLATE_NAME)
	_retrieve_instance_data(${__INSTANCE_ID} GENERATE_TARGETS_INCLUDE_LINKPARS __GENERATE_TARGETS_INCLUDE_LINKPARS)
	
	_make_instance_name(${__INSTANCE_ID} __INSTANCE_NAME)
	_retrieve_instance_data(${__INSTANCE_ID} PATH __TARGETS_CMAKE_PATH)

	_retrieve_instance_args(${__INSTANCE_ID} I_FEATURES __ARGS)
	set(__ARGS__LIST_FEATURES "${__ARGS__LIST}")
	_retrieve_instance_args(${__INSTANCE_ID} MODIFIERS __ARGS)
	set(__ARGS__LIST_MODIFIERS "${__ARGS__LIST}")
	list(APPEND __ARGS__LIST ${__ARGS__LIST_FEATURES})
	if(__GENERATE_TARGETS_INCLUDE_LINKPARS)
		_retrieve_instance_args(${__INSTANCE_ID} LINKPARS __ARGS)
		set(__ARGS__LIST_LINKPARS "${__ARGS__LIST}")
		list(LENGTH __ARGS__LIST_LINKPARS __LEN_LINKPARS)
		if("${__LEN_LINKPARS}" STREQUAL "0")
			message("WARNING: In ${__TARGETS_CMAKE_PATH} (template ${__TEMPLATE_NAME}) template option GENERATE_TARGETS_INCLUDE_LINKPARS is set, but there is no LINK_PARAMETERS.")
		else()
#			message(STATUS "${__PADDING}_get_target_internal(): Adding the following LINKPARS before calling generate_targets() of ${__INSTANCE_ID}: ${__ARGS__LIST_LINKPARS}")
			_retrieve_instance_data(${__INSTANCE_ID} LINKPARS __SERIALIZED_LINKPARS)
#			message(STATUS "${__PADDING}_get_target_internal(): __SERIALIZED_LINKPARS: ${__SERIALIZED_LINKPARS}")

		endif()
#		message(STATUS "${__PADDING}_get_target_internal(): __INSTANCE_ID: ${__INSTANCE_ID} Including the following linkpars: ${__ARGS__LIST_LINKPARS}")
	else()
		set(__ARGS__LIST_LINKPARS)
	endif()
	list(APPEND __ARGS__LIST ${__ARGS__LIST_FEATURES} ${__ARGS__LIST_MODIFIERS} ${__ARGS__LIST_LINKPARS} )
	
	_retrieve_instance_data(${__INSTANCE_ID} DEP_INSTANCES __DEP_ID_LIST)
	_retrieve_instance_pars(${__INSTANCE_ID} __PARS)
	if(NOT __TARGETS_CMAKE_PATH)
		message(FATAL_ERROR "Internal error: Empty __TARGETS_CMAKE_PATH")
	endif()
	
#	message(STATUS "${__PADDING}_get_target_internal(): __INSTANCE_ID: ${__INSTANCE_ID} __DEP_ID_LIST: ${__DEP_ID_LIST}")
	_insert_names_from_dependencies("${__DEP_ID_LIST}" __ARGS)
	
#	message(STATUS "${__PADDING}_get_target_internal()1 Serialbox_SerialboxCStatic_INSTALL_DIR: ${Serialbox_SerialboxCStatic_INSTALL_DIR}")
	set(${__TEMPLATE_NAME}_TARGET_NAME ${__INSTANCE_NAME})
	
	_instantiate_variables(__ARGS __PARS "${__ARGS__LIST}")
#	message(STATUS "${__PADDING}_get_target_internal() __INSTANCE_ID: ${__INSTANCE_ID} __INSTANCE_NAME: ${__INSTANCE_NAME} __TARGETS_CMAKE_PATH: ${__TARGETS_CMAKE_PATH}")
#	message(STATUS "${__PADDING}_get_target_internal() HALO_SIZE: ${HALO_SIZE} __ARGS__LIST: ${__ARGS__LIST} __ARGS_HALO_SIZE: ${__ARGS_HALO_SIZE}")
	get_filename_component(__TEMPLATE_DIR "${__TARGETS_CMAKE_PATH}" DIRECTORY)
#	message(STATUS "${__PADDING}_get_target_internal() _read_functions_from_targets_file ${__TARGETS_CMAKE_PATH}")
	_read_functions_from_targets_file("${__TARGETS_CMAKE_PATH}")
#	message(STATUS "${__PADDING}_get_target_internal() __TARGETS_CMAKE_PATH: ${__TARGETS_CMAKE_PATH}")
#	message(STATUS "${__PADDING}_get_target_internal() __TEMPLATE_DIR: ${__TEMPLATE_DIR}")

	get_filename_component(__TARGETS_NAME "${__TARGETS_CMAKE_PATH}" NAME)
#	message(STATUS "${__PADDING}_get_target_internal() __TARGETS_NAME: ${__TARGETS_NAME}")
	
	if(NOT "${__TARGETS_NAME}" STREQUAL "targets.cmake")
		get_filename_component(__PARENT_NAME "${__TEMPLATE_DIR}" NAME)
#		message(STATUS "${__PADDING}_get_target_internal() __PARENT_NAME: ${__PARENT_NAME}")
		if("${__PARENT_NAME}" STREQUAL "targets")
			get_filename_component(__PARENT_PARENT_DIR "${__TEMPLATE_DIR}" DIRECTORY)
#			message(STATUS "${__PADDING}_get_target_internal() __PARENT_PARENT_DIR: ${__PARENT_PARENT_DIR}")
			get_filename_component(__PARENT_PARENT_NAME "${__PARENT_PARENT_DIR}" NAME)
#			message(STATUS "${__PADDING}_get_target_internal() __PARENT_PARENT_NAME: ${__PARENT_PARENT_NAME}")
			if("${__PARENT_NAME}" STREQUAL "cmake")
				get_filename_component(__PARENT_PARENT_PARENT_DIR "${__PARENT_PARENT_DIR}" DIRECTORY)
				set(__TEMPLATE_DIR "${__PARENT_PARENT_PARENT_DIR}")
			else()
				set(__TEMPLATE_DIR "${__PARENT_PARENT_DIR}")
			endif()
		else()
			#Do nothing. targets.cmake loaded by manual path
		endif()
			
	endif()
	
	
	set(CMAKE_CURRENT_SOURCE_DIR "${__TEMPLATE_DIR}")
	set(SOURCE_DIR "${__TEMPLATE_DIR}")
#	message(STATUS "${__PADDING}_get_target_internal() CMAKE_CURRENT_SOURCE_DIR: ${CMAKE_CURRENT_SOURCE_DIR}")

#	message(STATUS "${__PADDING}_get_target_internal() Going to call generate targets for ${__TEMPLATE_NAME} from ${__TARGETS_CMAKE_PATH} ${__INSTANCE_NAME} with instance name set as «${__INSTANCE_NAME}» ")
	set(__NO_OP 0)

	generate_targets(${__INSTANCE_NAME} ${__TEMPLATE_NAME})
	
	_retrieve_instance_data(${__INSTANCE_ID} NO_TARGETS __NO_TARGETS )
#	message(STATUS "${__PADDING}_get_target_internal(): __INSTANCE_ID: ${__INSTANCE_ID} __NO_TARGETS: ${__NO_TARGETS}")
	_retrieve_instance_data(${__INSTANCE_ID} TARGETS_REQUIRED __TARGETS_REQUIRED )
	if(__NO_OP)
		_get_target_behavior(__TARGET_BEHAVIOR)
		if("${__TARGET_BEHAVIOR}" STREQUAL "OUTSIDE_SCOPE")
			message(FATAL_ERROR "File ${CMAKE_CURRENT_SOURCE_DIR}/targets.cmake did not define generate_targets() function.")
		endif()
		if(__TARGETS_REQUIRED AND NOT __NO_TARGETS)
			message(FATAL_ERROR "File ${CMAKE_CURRENT_SOURCE_DIR}/targets.cmake did not define generate_targets() function. If you cannot produce targets, please add NO_TARGETS option to FILE_OPTIONS variable defined in this file.")
		endif()
		set(${__OUT_FUNCTION_EXISTS} 0 PARENT_SCOPE)
	else()
#		if(__NO_TARGETS)
#			message(FATAL_ERROR "File ${CMAKE_CURRENT_SOURCE_DIR}/targets.cmake defined generate_targets() function while also declared NO_TARGETS option.")
#		endif()
		if(NOT __NO_TARGETS AND __TARGETS_REQUIRED AND NOT TARGET "${${__TEMPLATE_NAME}_TARGET_NAME}")
			_retrieve_instance_data(${__INSTANCE_ID} PATH __TARGETS_CMAKE_PATH )
			if(TEST "${${__TEMPLATE_NAME}_TARGET_NAME}")
				message(FATAL_ERROR "Function generate_targets() defined in ${__TARGETS_CMAKE_PATH} defined a TEST not a TARGET. TEST is not a target - please add an option NO_TARGETS to that file (i.e. add it to the FILE_OPTIONS variable like that: `set(FILE_OPTIONS NO_TARGETS)`") 
			endif()
			message(FATAL_ERROR "Called ${__TARGETS_CMAKE_PATH}:generate_targets(${__TEMPLATE_NAME}) which did not produce the target with name TARGET_NAME = \"${TARGET_NAME}\"" )
		endif()
		set(${__OUT_FUNCTION_EXISTS} 1 PARENT_SCOPE)
	endif()
endfunction()

#Inserts variables from dependencies that export them.
macro(_insert_names_from_dependencies __DEP_ID_LIST __EXISTING_ARGS)
	#We need to populate all dependencies, so their names can be used in the targets.cmake
#	message(STATUS "${__PADDING}_insert_names_from_dependencies(): ENTER with __DEP_ID_LIST: ${__DEP_ID_LIST} and __EXISTING_ARGS: ${__EXISTING_ARGS}: ${${__EXISTING_ARGS}__LIST}")
	set(__DEP_EXPVAR_LIST)
	if(__DEP_ID_LIST)
		foreach(__DEP_ID IN LISTS __DEP_ID_LIST)
			_make_instance_name(${__DEP_ID} __DEP_NAME)
			_retrieve_instance_data(${__DEP_ID} I_TEMPLATE_NAME __DEP_TEMPLATE_NAME)
			string(REPLACE "::" "_" __DEP_TEMPLATE_NAME "${__DEP_TEMPLATE_NAME}")
		
			list(APPEND ${__DEP_TEMPLATE_NAME}_TARGET_NAME "${__DEP_NAME}")
			_retrieve_instance_data(${__DEP_ID} EXPORTED_VARS __EXPORTED_VARS)
			_retrieve_instance_data(${__DEP_ID} SOURCE_DIR __DEP_SOURCE_DIR)
			if(__DEP_SOURCE_DIR)
				list(APPEND __EXPORTED_VARS ${__DEP_TEMPLATE_NAME}_SOURCE_DIR)
				set(${__DEP_TEMPLATE_NAME}_SOURCE_DIR "${__DEP_SOURCE_DIR}")
#				message(STATUS "${__PADDING}_insert_names_from_dependencies(): ${__DEP_TEMPLATE_NAME}_SOURCE_DIR: ${__DEP_SOURCE_DIR}")
			endif()
			_retrieve_instance_data(${__DEP_ID} INSTALL_DIR __DEP_INSTALL_DIR)
			_retrieve_instance_pars(${__DEP_ID} __PARS)
			if(__DEP_INSTALL_DIR)
				list(APPEND __EXPORTED_VARS ${__DEP_TEMPLATE_NAME}_INSTALL_DIR)
				set(${__DEP_TEMPLATE_NAME}_INSTALL_DIR "${__DEP_INSTALL_DIR}")
				set(__PARS_INSTALL_DIR__CONTAINER "SCALAR")
#				message(STATUS "${__PADDING}_insert_names_from_dependencies() ${__DEP_TEMPLATE_NAME}_INSTALL_DIR: ${__DEP_INSTALL_DIR}")
			endif()
			if(__EXPORTED_VARS)
#				message(STATUS "_insert_names_from_dependencies() __EXPORTED_VARS: ${__EXPORTED_VARS}")
				_retrieve_instance_args(${__DEP_ID} LINKPARS  __DEPVARS)
				_retrieve_instance_args(${__DEP_ID} I_FEATURES  __DEPVARS)
				_retrieve_instance_args(${__DEP_ID} MODIFIERS __DEPVARS)
				
#				_retrieve_instance_data(${__DEP_ID} LINKPARS  __TMP)
#				message(STATUS "${__PADDING}_insert_names_from_dependencies(): ${__DEP_ID} LINKPARS: ${__TMP}")
#				_retrieve_instance_data(${__DEP_ID} I_FEATURES  __TMP)
#				message(STATUS "${__PADDING}_insert_names_from_dependencies(): ${__DEP_ID} I_FEATURES: ${__TMP}")
#				_retrieve_instance_data(${__DEP_ID} MODIFIERS  __TMP)
#				message(STATUS "${__PADDING}_insert_names_from_dependencies(): ${__DEP_ID} MODIFIERS: ${__TMP}")
				
				foreach(__EXPVAR IN LISTS __EXPORTED_VARS)
					if("${__EXPVAR}" IN_LIST ${__EXISTING_ARGS}__LIST)
						_get_nice_instance_name(${__DEP_ID} __NICE_NAME_DEP)
						_get_nice_instance_name(${__INSTANCE_ID} __NICE_NAME_WE)
						message(WARNING "Exported variable ${__EXPVAR} from ${__NICE_NAME_DEP} will not be available in ${__NICE_NAME_WE} because it is shadowed by the variable of the same name declared in it.")
					elseif("${__EXPVAR}" IN_LIST __DEP_EXPVAR_LIST AND NOT "${${__EXPVAR}}" STREQUAL "${__DEPVARS_${__EXPVAR}}" AND "${__EXPVAR}" IN_LIST __DEPVARS)
						_get_nice_instance_name(${__DEP_ID} __NICE_NAME_DEP)
						_get_nice_instance_name(${__INSTANCE_ID} __NICE_NAME_WE)
						_retrieve_instance_data(${__DEP_ID} PATH __DEPPATH)
						file(RELATIVE_PATH __DEPPATH ${SUPERBUILD_ROOT} "${__DEPPATH}")

						message(FATAL_ERROR "Variable ${__EXPVAR}= \"${__DEPVARS_${__EXPVAR}}\" exported from ${__NICE_NAME_DEP} has already been imported from other dependency, but with different value: \"${${__EXPVAR}}\". Remove this variable from the list of exported variables in ${__DEPPATH} or make sure they all have the same value.")
					else()
						if(NOT "${__EXPVAR}" STREQUAL "${__DEP_TEMPLATE_NAME}_SOURCE_DIR" AND NOT "${__EXPVAR}" STREQUAL "${__DEP_TEMPLATE_NAME}_INSTALL_DIR")
							if("${__PARS_${__EXPVAR}__CONTAINER}" STREQUAL "OPTION")
								if(__DEPVARS_${__EXPVAR})
									set(${__EXPVAR} 1)
								else()
									set(${__EXPVAR} 0)
								endif()
							else()
#								message(STATUS "_insert_names_from_dependencies() __DEPVARS_${__EXPVAR}: ${__DEPVARS_${__EXPVAR}}")
								set(${__EXPVAR} "${__DEPVARS_${__EXPVAR}}")
							endif()
						endif()
						list(APPEND __DEP_EXPVAR_LIST ${__EXPVAR})
					endif()
#					message(STATUS "${__PADDING}_insert_names_from_dependencies() __DEP_ID: ${__DEP_ID} __EXPVAR: ${__EXPVAR}:${${__EXPVAR}} ")

				endforeach()
			endif()
		endforeach()
	endif()
endmacro()

