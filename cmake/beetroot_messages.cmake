function(_get_nice_instance_name_with_deps __INSTANCE_IDS_IN __OUT_NICE_NAME)
	_get_nice_instance_names(${__INSTANCE_IDS_IN} __NICE_BASE_NAME)
	#Gather all dep_IDs
	set(__TOTAL_DEP_IDS)
	foreach(__INSTANCE_ID IN LISTS ${__INSTANCE_IDS_IN})
		_retrieve_instance_data(${__INSTANCE_ID} DEP_INSTANCES __DEP_IDS)
		list(APPEND __TOTAL_DEP_IDS ${__DEP_IDS})
	endforeach()
	if(NOT ${__TOTAL_DEP_IDS} STREQUAL "")
		_get_nice_instance_name_with_deps(__TOTAL_DEP_IDS __DEP_NICE_NAMES)
		set(__NICE_BASE_NAME "${__NICE_BASE_NAME} which depend on ${__DEP_NICE_NAMES}")
	endif()
	set(${__OUT_NICE_NAME} "${__NICE_BASE_NAME}" PARENT_SCOPE)
endfunction()

#Instance can be virtual (i.e. without assigned target name and featurebase) or actual.
function(_get_nice_instance_name __INSTANCE_ID __OUT_NICE_NAME)
	_retrieve_instance_data(${__INSTANCE_ID} NICE_NAME __NICE_NAME)
	_retrieve_instance_data(${__INSTANCE_ID} IS_PROMISE __IS_PROMISE)
	
#	message(STATUS "_get_nice_instance_name(): __INSTANCE_ID: ${__INSTANCE_ID} __IS_PROMISE: ${__IS_PROMISE}")
	
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
			set(${__OUT_NICE_NAME} "${__NICE_NAME} - ${__TEMPLATE_NAME}" PARENT_SCOPE)
		elseif()
			set(${__OUT_NICE_NAME} "${__NICE_NAME}" PARENT_SCOPE)
		endif()
#		message(STATUS "_get_nice_instance_name(): __NICE_NAME: ${__NICE_NAME}")
		return()
	endif()
	if(__IS_PROMISE)
		set(${__OUT_NICE_NAME} "${__TEMPLATE_NAME} with no target assigned yet" PARENT_SCOPE)
		return()
	else()
		_retrieve_instance_data(${__INSTANCE_ID} I_TARGET_NAME __TARGET_NAME)
		if(__TARGET_NAME)
			set(${__OUT_NICE_NAME} "target ${__TARGET_NAME}" PARENT_SCOPE)
	#		message(STATUS "_get_nice_instance_name(): __TARGET_NAME: ${__TARGET_NAME}")
			return()
		endif()
	endif()
	_retrieve_instance_data(${__INSTANCE_ID} I_TEMPLATE_NAME __TEMPLATE_NAME)
	if(NOT __TEMPLATE_NAME)
		message(FATAL_ERROR "Internal beetroot error: Instance ${__INSTANCE_ID} does not have I_TEMPLATE_NAME associated")
	endif()
#	message(STATUS "_get_nice_instance_name(): __TEMPLATE_NAME: ${__TEMPLATE_NAME}")
	set(${__OUT_NICE_NAME} "${__TEMPLATE_NAME}" PARENT_SCOPE)
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
	if(NOT __TEMPLATE_NAMES)
		_retrieve_featurebase_data(${__FEATUREBASE_ID} PATH __TARGETS_CMAKE_PATH)
		_make_path_hash(${__TARGETS_CMAKE_PATH} __PATH_HASH)
		message(FATAL_ERROR "Internal beetroot error: Featurebase ${__FEATUREBASE_ID} (path hash ${__PATH_HASH}) does not have any templates associated in F_TEMPLATE_NAMES")
	endif()
	if(__NICE_NAME)
		set(${__OUT_NICE_NAME} "${__NICE_NAME}" PARENT_SCOPE)
		return()
	endif()
	set(__TARGET_NAME)
	_retrieve_featurebase_data(${__FEATUREBASE_ID} F_TARGET_NAMES __TARGET_NAMES)
	if(__TARGET_NAMES)
		list(LENGTH __TARGET_NAMES __TARGET_NAMES_COUNT)
		if("${__TARGET_NAMES_COUNT}" GREATER 1)
			nice_list_output(LIST "${__TARGET_NAMES}" OUTVAR __TARGET_NAMES_TXT)
			set(${__OUT_NICE_NAME} "targets ${__TARGET_NAMES_TXT}" PARENT_SCOPE)
		else()
			set(${__OUT_NICE_NAME} "target ${__TARGET_NAMES}" PARENT_SCOPE)
		endif()
#		message(STATUS "_get_nice_instance_name(): __TARGET_NAME: ${__TARGET_NAME}")
		return()
	endif()
	list(LENGTH __TEMPLATE_NAMES __TEMPLATE_NAMES_COUNT)
	if("${__TEMPLATE_NAMES_COUNT}" GREATER 1)
		nice_list_output(LIST "${__TEMPLATE_NAMES}" OUTVAR __TEMPLATE_NAMES_TXT)
		set(${__OUT_NICE_NAME} "templates ${__TEMPLATE_NAMES_TXT}" PARENT_SCOPE)
	else()
		set(${__OUT_NICE_NAME} "template ${__TEMPLATE_NAMES}" PARENT_SCOPE)
	endif()
endfunction()

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

if(__BURAK_DEBUG)
function(_debug_show_featurebase __FEATUREBASE_ID __DEPTH __PREFIX __OUT __OUT_ERROR)
#	message(STATUS "_debug_show_featurebase(): __FEATUREBASE_ID: ${__FEATUREBASE_ID} __DEPTH: ${__DEPTH}")
	if("${__DEPTH}" STREQUAL "0")
		set(${__OUT} ${__FEATUREBASE_ID} PARENT_SCOPE)
		return()
	endif()
	_can_descend_recursively("${__FEATUREBASE_ID}" DEBUG_PRINT_FEATUREBASE __CAN_DESCEND)
	if(NOT __CAN_DESCEND)
		set(${__OUT} ${__INSTANCE_ID} PARENT_SCOPE)
		return()
#		_get_recurency_list(DEBUG_PRINT_FEATUREBASE __STACK)
#		message(FATAL_ERROR "Recursive call to the _debug_show_featurebase(${__FEATUREBASE_ID}). Stack: ${__STACK}")
	endif()

	_retrieve_featurebase_data(${__FEATUREBASE_ID}  F_INSTANCES __F_INSTANCES)
	_retrieve_featurebase_data(${__FEATUREBASE_ID}  DEP_INSTANCES __DEP_INSTANCES)
	_retrieve_featurebase_data(${__FEATUREBASE_ID}  F_FEATURES __F_FEATURES)
	_retrieve_featurebase_data(${__FEATUREBASE_ID}  MODIFIERS __MODIFIERS)
	_get_templates_by_featurebase(${__FEATUREBASE_ID} __F_TEMPLATE_NAME)
	_retrieve_featurebase_data(${__FEATUREBASE_ID}  F_PATH __TARGETS_CMAKE_PATH)
	_retrieve_featurebase_data(${__FEATUREBASE_ID}  TARGET_BUILT __TARGET_BUILT)
	_retrieve_featurebase_data(${__FEATUREBASE_ID}  F_HASH_SOURCE __F_HASH_SOURCE)
	_retrieve_featurebase_data(${__FEATUREBASE_ID}  COMPAT_INSTANCES __COMPATIBLE_INSTANCES)
	_retrieve_featurebase_data(${__FEATUREBASE_ID}  ASSUME_INSTALLED __ASSUME_INSTALLED)
	_retrieve_featurebase_data(${__FEATUREBASE_ID}  JOINT_TARGETS __JOINT_TARGETS)
	_retrieve_featurebase_data(${__FEATUREBASE_ID}  EXTERNAL_INFO __EXTERNAL_INFO__LIST)

	math(EXPR __DECR_DEPTH "${__DEPTH}-1")
	set(__ERROR)
	
	set(__OUT1 "${__PREFIX}Featurebase ${__FEATUREBASE_ID} of template ${__F_TEMPLATE_NAME} defined in\n${__PREFIX}${__TARGETS_CMAKE_PATH}\n${__PREFIX} defined by the modifiers\n${__PREFIX}${__MODIFIERS} and currently holding features\n${__PREFIX}${__F_FEATURES}.\n${__PREFIX}HASH_SOURCE: ${__F_HASH_SOURCE}")
	if(__DEP_INSTANCES)
		set(__OUT1 "\n${__PREFIX}Depends on the following instances")
		set(__COUNTER 1)
		foreach(__DEP_INSTANCE_ID IN LISTS __DEP_INSTANCES)
			_debug_show_instance(${__DEP_INSTANCE_ID} ${__DECR_DEPTH} "${__PREFIX}  ${__COUNTER}." __OUT2 __ERRORS)
			set(__OUT1 "${__OUT1}\n${__OUT2}")
			math(EXPR __COUNTER "${__COUNTER}+1")
		endforeach()
	endif()
	if(__TARGET_BUILT)
		set(__TARGET_NAMES)
		foreach(__INSTANCE IN LISTS __F_INSTANCES)
			_retrieve_instance_data(${__INSTANCE}  FEATUREBASE __FEATUREBASE)
			if(__FEATUREBASE)
				_retrieve_instance_data(${__INSTANCE}  TARGET_NAME __TARGET_NAME)
			else()
				set(__TARGET_NAME)
			endif()
			if(NOT __TARGET_NAME)
				set(__ERROR ${__ERROR} "Although the target is already built, there is an instance ${__INSTANCE} without target name")
			endif()
			list(APPEND __TARGET_NAMES ${__TARGET_NAME})
		endforeach()
		list(REMOVE_DUPLICATES __TARGET_NAMES)
		set(__OUT1 "${__OUT1}\n${__PREFIX}The target is already built under the name(s) ${__TARGET_NAMES}")
	endif()
	if(__EXTERNAL_INFO__LIST)
		if(__ASSUME_INSTALLED)
			set(__OUT1 "${__OUT1}\n${__PREFIX}The target is external and is assumed to be already installed")
		endif()
	else()
		if(__ASSUME_INSTALLED)
			set(__ERROR ${__ERROR} "Although the target is not external, it is assumed to be already installed")
		endif()
	endif()
	
	if(__F_INSTANCES)
		set(__OUT1 "${__OUT1}\n${__PREFIX}List of all instances of thise this featurebase: ${__F_INSTANCES} ")
		foreach(__F_INSTANCE IN LISTS __F_INSTANCES)
			_debug_show_instance(${__F_INSTANCE} ${__DECR_DEPTH} "${__PREFIX}   ${__COUNTER}. " __OUT2 __ERRORS)
			if(__ERRORS)
				foreach(__ERROR3 IN LISTS __ERRORS)
					set(__ERROR ${__ERROR} "Featurebase's instance ${__F_INSTANCE} ERROR:${__ERROR3}")
				endforeach()
			endif()
#				message(STATUS "_debug_show_instance(): __PARENT ${__OUT2}")
			set(__OUT1 "${__OUT1}\n${__OUT2}")
			math(EXPR __COUNTER "${__COUNTER}+1")
		endforeach()
	else()
		set(__OUT1 "${__OUT1}\n${__PREFIX}There are no instances of this featurebase")
	endif()
	
	set(${__OUT} "${__OUT1}" PARENT_SCOPE)
	set(${__OUT_ERROR} ${__ERROR} PARENT_SCOPE)
	
	_ascend_from_recurency(${__FEATUREBASE_ID} DEBUG_PRINT_FEATUREBASE)
endfunction()

function(_debug_show_instance __INSTANCE_ID __DEPTH __PREFIX __OUT __OUT_ERROR)
#	message(STATUS "_debug_show_instance(): ${__INSTANCE_ID} __DEPTH: ${__DEPTH}")
	if("${__DEPTH}" STREQUAL "0")
		set(${__OUT} ${__INSTANCE_ID} PARENT_SCOPE)
		return()
	endif()
	_can_descend_recursively("${__INSTANCE_ID}" DEBUG_PRINT_INSTANCE __CAN_DESCEND)
	if(NOT __CAN_DESCEND)
		set(${__OUT} ${__INSTANCE_ID} PARENT_SCOPE)
		return()
#		_get_recurency_list(DEBUG_PRINT_INSTANCE __STACK)
#		message(FATAL_ERROR "Recursive call to the _debug_show_instance(${__INSTANCE_ID}). Stack: ${__STACK}")
	endif()

	_retrieve_instance_data(${__INSTANCE_ID}  I_TEMPLATE_NAME __TEMPLATE_NAME)
	if(__TEMPLATE_NAME)
		_retrieve_instance_data(${__INSTANCE_ID}  PATH __TARGETS_CMAKE_PATH)
	else()
		set(__TARGETS_CMAKE_PATH "<unknown>")
	endif()
	_retrieve_instance_data(${__INSTANCE_ID}  IS_PROMISE __IS_PROMISE)
	_retrieve_instance_data(${__INSTANCE_ID}  LINKPARS __LINKPARS)
	_retrieve_instance_data(${__INSTANCE_ID}  I_FEATURES __I_FEATURES)
	_retrieve_instance_data(${__INSTANCE_ID}  I_HASH_SOURCE __HASH_SOURCE)
	_retrieve_instance_data(${__INSTANCE_ID}  FEATUREBASE __FEATUREBASE_ID)
	_retrieve_instance_data(${__INSTANCE_ID}  I_PARENTS __PARENTS)
	math(EXPR __DECR_DEPTH "${__DEPTH}-1")
#	message(STATUS "_debug_show_instance(): __DECR_DEPTH: ${__DECR_DEPTH}")
	set(__ERROR)
	
	if(__IS_PROMISE)
		set(__OUT2 "Promise")
	else()
		set(__OUT2 "Instance")
	endif()
	if(__FEATUREBASE_ID)
		_retrieve_instance_data(${__INSTANCE_ID}  TARGET_NAME __TARGET_NAME)
		set(__OUT1 " with assigned target name ${__TARGET_NAME}")
	else()
		set(__OUT1)
	endif()
	set(__OUT1 "${__PREFIX}${__OUT2} ${__INSTANCE_ID} of template ${__TEMPLATE_NAME}${__OUT1} defined in\n${__PREFIX}${__TARGETS_CMAKE_PATH}\n${__PREFIX}defined by the linkpars ${__LINKPARS}\n${__PREFIX}and features ${__I_FEATURES}.\n${__PREFIX}HASH_SOURCE: ${__HASH_SOURCE}")
	set(__OUT2)
	if(__IS_PROMISE)
		if(__FEATUREBASE_ID)
			_debug_show_featurebase(${__FEATUREBASE_ID} ${__DECR_DEPTH} "${__PREFIX}    " __OUT3 __ERRORS)
			set(__ERROR ${__ERROR} "The promise has assigned featurebase_id ${__FEATUREBASE_ID}: \n${__OUT3}")
			if(__ERRORS)
				foreach(__ERROR3 IN LISTS __ERRORS)
					set(__ERROR ${__ERROR} "Assigned featurebase ERROR:${__ERROR3}")
				endforeach()
			endif()
		endif()
		_retrieve_instance_data(${__INSTANCE_ID} VIRTUAL_INSTANCES __VIRTUAL_INSTANCES)
		if(NOT ${__INSTANCE_ID} IN_LIST __VIRTUAL_INSTANCES)
			set(__ERROR ${__ERROR} "This promise ${__INSTANCE_ID} is not registered in the list of all promises (VIRTUAL_INSTANCES: ${__VIRTUAL_INSTANCES})")
		endif()
	else()
		if(NOT __FEATUREBASE_ID)
			set(__ERROR ${__ERROR} "The instance does not have assigned featurebase_id!")
		else()
			_debug_show_featurebase(${__FEATUREBASE_ID} ${__DECR_DEPTH} "${__PREFIX}    " __OUT3 __ERRORS)
			if(__ERRORS)
				foreach(__ERROR3 IN LISTS __ERRORS)
					set(__ERROR ${__ERROR} "Assigned featurebase ERROR:${__ERROR3}")
				endforeach()
			endif()
			set(__OUT1 "\n${__PREFIX}${__OUT1}\n${__PREFIX}Featurebase:\n${__OUT3}")

			_retrieve_instance_data(${__INSTANCE_ID}  COMPAT_INSTANCES __COMPAT_INSTANCES)
			if(${__INSTANCE_ID} IN_LIST __COMPAT_INSTANCES)
				_retrieve_featurebase_data(${__FEATUREBASE_ID}  F_FEATURES __F_FEATURES)
				if(NOT "${__F_FEATURES}" STREQUAL "${__I_FEATURES}")
					set(__ERROR ${__ERROR} "Inconsistency: features of the featurebase ${__FEATUREBASE_ID} (${__F_FEATURES}) are not compatible with ours ${__I_FEATURES}, although we are present in the list of COMPAT_INSTANCES")
				else()
					set(__OUT1 "\n${__PREFIX}${__OUT1} The features of this instances are compatible with the common featurebase")
				endif()
			else()
				set(__OUT1 "\n${__PREFIX}${__OUT1} The features of this instances are NOT compatible with the common featurebase")
			endif()
			_retrieve_instance_data(${__INSTANCE_ID}  F_INSTANCES __INSTANCES)
			if(NOT ${__INSTANCE_ID} IN_LIST __INSTANCES)
				set(__ERROR ${__ERROR} "The instance ${__INSTANCE_ID} is not present in its featurebase instances list ${__INSTANCES}")
			endif()
			_get_templates_by_featurebase(${__FEATUREBASE_ID} __F_TEMPLATE_NAME)
			_retrieve_instance_data(${__INSTANCE_ID}  JOINT_TARGETS __JOINT_TARGETS)
#			if(__JOINT_TARGETS)
#				if(NOT "${__TEMPLATE_NAME}" IN_LIST __F_TEMPLATE_NAME)
#					set(__ERROR ${__ERROR} "Inconsistency: featurebase's template name list ${__F_TEMPLATE_NAME} does not contain ours.")
#				endif()
#			endif()
		endif()
		if(__TEMPLATE_NAME)
			_retrieve_instance_data(${__INSTANCE_ID}  VIRTUAL_INSTANCES __VIRTUAL_INSTANCES)
			if(${__INSTANCE_ID} IN_LIST __VIRTUAL_INSTANCES)
				set(__ERROR ${__ERROR} "This instance ${__INSTANCE_ID} is not a PROMISE but is somehow registered in the list of all promises (VIRTUAL_INSTANCES) of ${__TEMPLATE_NAME}")
			endif()
		endif()
	endif()
	_retrieve_global_data(INSTANCES __ALL_INSTANCES)
	if(NOT __PARENTS)
		if(NOT ${__INSTANCE_ID} IN_LIST __ALL_INSTANCES)
			set(__OUT1 "${__OUT1}\n${__PREFIX}The instance does not have any parents and is not required globally - it is not needed.")
		else()
			set(__OUT1 "${__OUT1}\n${__PREFIX}The instance is required by the top-level CMakeLists.txt.")
		endif()
	else()
		set(__OUT1 "${__OUT1}\n${__PREFIX}List of all parents:")
		set(__COUNTER 1)
		foreach(__PARENT IN LISTS __PARENTS)
#			message(STATUS "_debug_show_instance(): __PARENT: ${__PARENT} __INSTANCE_ID: ${__INSTANCE_ID}")
			_retrieve_instance_data(${__PARENT} I_TEMPLATE_NAME __PARENT_EXISTS)
			if(__PARENT_EXISTS)
#				message(STATUS "_debug_show_instance(): _debug_show_instance(${__PARENT} ${__DECR_DEPTH} \"${__PREFIX}   ${__COUNTER}. \" __OUT2 __ERRORS)")
				_debug_show_instance(${__PARENT} ${__DECR_DEPTH} "${__PREFIX}   ${__COUNTER}. " __OUT2 __ERRORS)
				if(__ERRORS)
					foreach(__ERROR3 IN LISTS __ERRORS)
						set(__ERROR ${__ERROR} "Parent's ${__PARENT} ERROR:${__ERROR3}")
					endforeach()
				endif()
#				message(STATUS "_debug_show_instance(): __PARENT ${__OUT2}")
				set(__OUT1 "${__OUT1}\n${__OUT2}")
				math(EXPR __COUNTER "${__COUNTER}+1")
				_retrieve_instance_data(${__PARENT} IS_PROMISE __IS_PROMISE)
				if(__IS_PROMISE)
					set(__ERROR ${__ERROR} "Parent ${__PARENT} is a promise")
				endif()
				_retrieve_instance_data(${__PARENT} FEATUREBASE __PARENTS_FEATUREBASE)
				if(NOT __PARENTS_FEATUREBASE)
					set(__ERROR ${__ERROR} "Parent ${__PARENT} does not have a featurebase")
				endif()
				_retrieve_instance_data(${__PARENT} DEP_INSTANCES __DEP_INSTANCES)
				if(NOT ${__INSTANCE_ID} IN_LIST __DEP_INSTANCES)
					set(__ERROR ${__ERROR} "Graph inconsistency: instance ${__INSTANCE_ID} is not in parent's ${__PARENT} dependencies. (all deps: ${__DEP_INSTANCES})")
				endif()
			else()
				set(__OUT1 "${__OUT1}\n${__PREFIX}   ${__COUNTER}. Parent INSTANCE_ID: ${__PARENT}")
			endif()
		endforeach()
		if(${__INSTANCE_ID} IN_LIST __ALL_INSTANCES)
			set(__OUT1 "${__OUT1}\n${__PREFIX}The instance is also required by the top-level CMakeLists.txt.")
		else()
			set(__OUT1 "${__OUT1}\n${__PREFIX}The instance is NOT required by the top-level CMakeLists.txt.")
		endif()
	endif()
	set(${__OUT} "${__OUT1}" PARENT_SCOPE)
	set(${__OUT_ERROR} "${__ERROR}" PARENT_SCOPE)
	_ascend_from_recurency(${__INSTANCE_ID} DEBUG_PRINT_INSTANCE)

endfunction()
else()
function(_debug_show_featurebase __FEATUREBASE_ID __DEPTH __PREFIX __OUT __OUT_ERROR)
endfunction()

function(_debug_show_instance __INSTANCE_ID __DEPTH __PREFIX __OUT __OUT_ERROR)

endfunction()
endif()


