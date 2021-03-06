function(_get_nice_instance_name_with_deps __INSTANCE_IDS_IN __OUT_NICE_NAME)
	_get_nice_instance_names(${__INSTANCE_IDS_IN} __NICE_BASE_NAME)
	#Gather all dep_IDs
	set(__TOTAL_DEP_IDS)
	foreach(__INSTANCE_ID IN LISTS ${__INSTANCE_IDS_IN})
		_retrieve_instance_data(${__INSTANCE_ID} I_PARENTS __DEP_IDS)
		list(APPEND __TOTAL_DEP_IDS ${__DEP_IDS})
	endforeach()
	if(NOT "${__TOTAL_DEP_IDS}" STREQUAL "")
		_get_nice_instance_name_with_deps(__TOTAL_DEP_IDS __DEP_NICE_NAMES)
		set(__NICE_BASE_NAME "${__NICE_BASE_NAME} which are required by ${__DEP_NICE_NAMES}")
	endif()
	set(${__OUT_NICE_NAME} "${__NICE_BASE_NAME}" PARENT_SCOPE)
endfunction()

#Instance can be virtual (i.e. without assigned target name and featurebase) or actual.
function(_get_nice_instance_name __INSTANCE_ID __OUT_NICE_NAME)
	_retrieve_instance_data(${__INSTANCE_ID} I_PATH __PATH)
#	message(STATUS "_get_nice_instance_name(): __INSTANCE_ID: ${__INSTANCE_ID} __PATH: ${__PATH} __IS_PROMISE: ${__IS_PROMISE}")
	_make_path_hash("${__PATH}" __FILEHASH)
	_retrieve_file_data(${__FILEHASH} NICE_NAME __NICE_NAME)
	_retrieve_instance_data(${__INSTANCE_ID} IS_PROMISE __IS_PROMISE)
	set(__OUT)
#	message(STATUS "_get_nice_instance_name(): __INSTANCE_ID: ${__INSTANCE_ID} __PATH: ${__PATH} __IS_PROMISE: ${__IS_PROMISE}")
	
	_retrieve_instance_data(${__INSTANCE_ID} I_TEMPLATE_NAME __TEMPLATE_NAME)
	if("${__TEMPLATE_NAME}" STREQUAL "")
		_retrieve_instance_data(${__INSTANCE_ID} PATH __TARGETS_CMAKE_PATH)
		_make_path_hash(${__TARGETS_CMAKE_PATH} __PATH_HASH)
		message(FATAL_ERROR "Internal beetroot error: Instance ${__INSTANCE_ID} (path hash ${__PATH_HASH}) does not have I_TEMPLATE_NAME associated in with")
	endif()
	if(__NICE_NAME)
		_retrieve_instance_data(${__INSTANCE_ID} G_TEMPLATES __TEMPLATE_NAMES)
		if(__TEMPLATE_NAMES)
			list(LENGTH __TEMPLATE_NAMES __TEMPLATE_COUNT)
		else()
			_retrieve_instance_data(${__INSTANCE_ID} PATH __TARGETS_CMAKE_PATH)
			_make_path_hash(${__TARGETS_CMAKE_PATH} __PATH_HASH)
			message(FATAL_ERROR "Internal beetroot error: Instance ${__INSTANCE_ID} (path hash ${__PATH_HASH}) does not have any templates associated in G_TEMPLATES")
		endif()
		if("${__TEMPLATE_COUNT}" GREATER 1)
			_retrieve_instance_data(${__INSTANCE_ID} I_TEMPLATE_NAME __TEMPLATE_NAME)
			set(__OUT "${__NICE_NAME} - ${__TEMPLATE_NAME}")
		elseif()
			set(__OUT "${__NICE_NAME}")
		endif()
#		message(STATUS "_get_nice_instance_name(): __NICE_NAME: ${__NICE_NAME}")
	else()
		if(__IS_PROMISE)
#			set(__OUT "${__TEMPLATE_NAME} with no target assigned yet")
			set(__OUT "${__TEMPLATE_NAME}")
		else()
			_retrieve_instance_data(${__INSTANCE_ID} I_TARGET_NAME __TARGET_NAME)
			if(__TARGET_NAME)
				set(__OUT "target ${__TARGET_NAME}")
		#		message(STATUS "_get_nice_instance_name(): __TARGET_NAME: ${__TARGET_NAME}")
			else()
				_retrieve_instance_data(${__INSTANCE_ID} I_TEMPLATE_NAME __TEMPLATE_NAME)
				if(NOT __TEMPLATE_NAME)
					message(FATAL_ERROR "Internal beetroot error: Instance ${__INSTANCE_ID} does not have I_TEMPLATE_NAME associated")
				endif()
			#	message(STATUS "_get_nice_instance_name(): __TEMPLATE_NAME: ${__TEMPLATE_NAME}")
				set(__OUT "${__TEMPLATE_NAME}")
			endif()
		endif()
	endif()
	set(${__OUT_NICE_NAME} "${__TEMPLATE_NAME}" PARENT_SCOPE)
	
	set(__PATHS)
	_retrieve_instance_data(${__INSTANCE_ID} I_PARENTS __PARENTS)
#	message(STATUS "_get_nice_instance_name(): parents of ${__INSTANCE_ID} are ${__PARENTS}")
	foreach(__PARENT_INSTANCEID IN LISTS __PARENTS)
		_retrieve_instance_data(${__PARENT_INSTANCEID} I_PATH __PATH)
#		message(STATUS "_get_nice_instance_name(): I_PATH of ${__INSTANCE_ID} is ${__PATH}")
		list(APPEND __PATHS "${__PATH}")
	endforeach()

	
	_retrieve_instance_data(${__INSTANCE_ID} PATH __MY_PATH)
	_get_relative_path("${__MY_PATH}" __MY_REL_PATH)
	set(__OUT "${__OUT} in ${__MY_REL_PATH}")
	if(NOT "${__PATHS}" STREQUAL "")
		list(REMOVE_DUPLICATES __PATHS)
		set(__PATHS2)
		foreach(__PATH IN LISTS __PATHS)
			_get_relative_path("${__PATH}" __REL_PATH)
			list(APPEND __PATHS2 ${__REL_PATH})
		endforeach()
		nice_list_output(LIST "${__PATHS2}" OUTVAR __NICE_PATHS)
		set(__OUT2 " (required from ${__NICE_PATHS})")
	else()
		set(__OUT2)
	endif()
	set(${__OUT_NICE_NAME} "${__OUT}${__OUT2}" PARENT_SCOPE)
	
endfunction()

function(_get_nice_instance_names __IN_INSTANCE_LIST __OUTVAR)
	set(__NICES)
#	message(STATUS "_get_nice_instance_names(): __IN_INSTANCE_LIST: ${__IN_INSTANCE_LIST}")
	foreach(__INSTANCE_ID IN LISTS ${__IN_INSTANCE_LIST})
#		message(STATUS "_get_nice_instance_names(): __INSTANCE_ID: ${__INSTANCE_ID}")
		_get_nice_instance_name(${__INSTANCE_ID} __NICE)
#		message(STATUS "_get_nice_instance_names(): __INSTANCE_ID: ${__INSTANCE_ID} __NICE: ${__NICE}")
		list(APPEND __NICES "\"${__NICE}\"")
	endforeach()
	nice_list_output(LIST "${__NICES}" OUTVAR __OUT)
#	message(STATUS "_get_nice_instance_names(): nice_list_output(LIST \"${__NICES}\" OUTVAR __OUT): ${__OUT}")
	set(${__OUTVAR} "${__OUT}" PARENT_SCOPE )
endfunction()

function(_get_nice_dependencies_name __INSTANCE_ID __OUTVAR)
	_retrieve_instance_data(${__INSTANCE_ID} I_PARENTS __PARENTS)
	set(__DEPS)
	foreach(__PARENT_ID IN LISTS __PARENTS)
		_get_nice_instance_name(${__PARENT_ID} __DEP)
		list(APPEND __DEPS "\"${__DEP}\"")
	endforeach()
	nice_list_output(LIST "${__DEPS}" OUTVAR __OUT)
	set(${__OUTVAR} "${__OUT}" PARENT_SCOPE )
endfunction()

function(_get_nice_featurebase_name __FEATUREBASE_ID __OUT_NICE_NAME)
	_retrieve_featurebase_data(${__FEATUREBASE_ID} NICE_NAME __NICE_NAME)
	_retrieve_featurebase_data(${__FEATUREBASE_ID} F_TEMPLATE_NAMES __TEMPLATE_NAMES)
	set(__OUT)
	if(NOT __TEMPLATE_NAMES)
		_retrieve_featurebase_data(${__FEATUREBASE_ID} PATH __TARGETS_CMAKE_PATH)
		_make_path_hash(${__TARGETS_CMAKE_PATH} __PATH_HASH)
		message(FATAL_ERROR "Internal beetroot error: Featurebase ${__FEATUREBASE_ID} (path hash ${__PATH_HASH}) does not have any templates associated in F_TEMPLATE_NAMES")
	endif()
	if(__NICE_NAME)
		set(__OUT "${__NICE_NAME}")
	else()
		set(__TARGET_NAME)
		_retrieve_featurebase_data(${__FEATUREBASE_ID} F_TARGET_NAMES __TARGET_NAMES)
		if(__TARGET_NAMES)
			list(LENGTH __TARGET_NAMES __TARGET_NAMES_COUNT)
			if("${__TARGET_NAMES_COUNT}" GREATER 1)
				nice_list_output(LIST "${__TARGET_NAMES}" OUTVAR __TARGET_NAMES_TXT)
				set(__OUT "targets ${__TARGET_NAMES_TXT}")
			else()
				set(__OUT "target ${__TARGET_NAMES}")
			endif()
	#		message(STATUS "_get_nice_instance_name(): __TARGET_NAME: ${__TARGET_NAME}")
		else()
			list(LENGTH __TEMPLATE_NAMES __TEMPLATE_NAMES_COUNT)
			if("${__TEMPLATE_NAMES_COUNT}" GREATER 1)
				nice_list_output(LIST "${__TEMPLATE_NAMES}" OUTVAR __TEMPLATE_NAMES_TXT)
				set(__OUT "templates ${__TEMPLATE_NAMES_TXT}")
			else()
				set(__OUT "template ${__TEMPLATE_NAMES}")
			endif()
		endif()
	endif()
	_retrieve_featurebase_data(${__FEATUREBASE_ID} F_INSTANCES __INSTANCES)
	set(__INSTANCES_TXT)
	foreach(__INSTANCE_ID IN LISTS __INSTANCES)
		_get_nice_instance_name(${__INSTANCE_ID} __INSTANCE_TXT)
		list(APPEND __INSTANCES_TXT "${__INSTANCE_TXT}")
	endforeach()
	nice_list_output(LIST "${__INSTANCES_TXT}" OUTVAR __INSTANCES_NICE)
	
	
	_retrieve_featurebase_data(${__FEATUREBASE_ID} F_PATH __F_PATH)
#	message(STATUS "${__PADDING}_get_nice_featurebase_name(): __F_PATH: ${__F_PATH}")
	_get_relative_path("${__F_PATH}" __REL_PATH)
	set(${__OUT_NICE_NAME} "${__OUT} defined by ${__INSTANCES_NICE}" PARENT_SCOPE)
	
endfunction()

macro(_get_relative_path __PATHIN __OUT_PATH)
	if("${__PATHIN}" STREQUAL "")
		set(${__OUT_PATH})
	else()
		if(IS_ABSOLUTE "${__PATHIN}")
#			message(STATUS "file(RELATIVE_PATH ${__OUT_PATH} \"${SUPERBUILD_ROOT}\" \"${__PATHIN}\")")
			file(RELATIVE_PATH ${__OUT_PATH} "${SUPERBUILD_ROOT}" "${__PATHIN}")
		else()
			set(${__OUT_PATH} ${__PATHIN})
		endif()
	endif()
#	message(STATUS "${__PADDING}_get_relative_path(): file(RELATIVE_PATH __OUT_PATH \"${SUPERBUILD_ROOT}\" \"${__PATH}\"): ${${__OUT_PATH}}")
endmacro()

function(_get_nice_featurebase_names __IN_FEATUREBASE_LIST __OUTVAR)
	set(__NICES)
#	message(STATUS "_get_nice_featurebase_names(): __IN_INSTANCE_LIST: ${__IN_INSTANCE_LIST}")
	foreach(__FEATUREBASE_ID IN LISTS ${__IN_FEATUREBASE_LIST})
#		message(STATUS "_get_nice_featurebase_names(): __FEATUREBASE_ID: ${__FEATUREBASE_ID}")
		_get_nice_featurebase_name(${__FEATUREBASE_ID} __NICE)
#		message(STATUS "_get_nice_featurebase_names(): __FEATUREBASE_ID: ${__FEATUREBASE_ID} __NICE: ${__NICE}")
		list(APPEND __NICES "\"${__NICE}\"")
	endforeach()
	nice_list_output(LIST "${__NICES}" OUTVAR __OUT)
#	message(STATUS "_get_nice_featurebase_names(): nice_list_output(LIST \"${__NICES}\" OUTVAR __OUT): ${__OUT}")
	set(${__OUTVAR} "${__OUT}" PARENT_SCOPE )
endfunction()


