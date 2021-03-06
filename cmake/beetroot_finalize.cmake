#Macro that generates a local project as the external dependency in the SUPERBUILD phase
#that depends on all external dependencies.
#
#It must be macro, because it has to enable languages, if enabled by any of the targets.
include(CheckLanguage)

macro(finalizer)
	_set_property_to_db(GLOBAL ALL LAST_READ_FILE "NONE" FORCE)
	set(__DUMP_TREE 1)
	_get_target_behavior(__TARGET_BEHAVIOR)
	if("${__TARGET_BEHAVIOR}" STREQUAL "DEFINING_TARGETS")
		message(WARNING "finalizer called second time. This function is meant to be called only once at the very end of the root CMakeLists. Ignoring this call.")
		return()
	endif()
	_set_behavior_defining_targets() #To make sure we never call declare_dependencies()

#	message("")
#	message("")
#	message("############### BEFORE RESOLVE ##############")
#	message("")


	_resolve_features() #Instantiate all promises or throw an error
	
#	message("")
#	message("")
#	message("############### AFTER RESOLVE ##############")
#	message("")
	
	#Now we can assume that all features in all featuresets agree with the features in instances, which means that we can concatenate features to the target parameters (modifiers)
	#Now we need to instantiate all the targets. 
	_retrieve_global_data(INSTANCES __INSTANCE_ID_LIST)
#	message(STATUS "${__PADDING}finalizer(): __INSTANCE_ID_LIST: ${__INSTANCE_ID_LIST}")
	if(__INSTANCE_ID_LIST)
		if("${SUPERBUILD}" STREQUAL "AUTO" AND NOT __NOT_SUPERBUILD)
			_retrieve_global_data(EXTERNAL_DEPENDENCIES __EXTERNAL_DEPENDENCIES)
#			message(STATUS "${__PADDING}finalizer(): __EXTERNAL_DEPENDENCIES: ${__EXTERNAL_DEPENDENCIES}")
			if(__EXTERNAL_DEPENDENCIES)
				set(IS_SUPERBUILD 1)
				set(__NOT_SUPERBUILD 0)
			else()
				set(IS_SUPERBUILD 0)
				set(__NOT_SUPERBUILD 1)
				if(__SUPERBUILD_TRIGGER_TESTS)
					enable_testing()
				endif()
			endif()
		endif()
		message("")
		message("")
		message("")
		if(__NOT_SUPERBUILD)
			message("    DEFINING  TARGETS  IN  PROJECT BUILD")
			if(CMAKE_TESTING_ENABLED)
				message("    TESTS  ENABLED")
			else()
				message("    TESTS  disabled")
			endif()
			message("")
#			message(STATUS "${__PADDING}finalizer(): calling _get_all_languages()")
			_get_all_languages(__LANGUAGES)
			list(APPEND __LANGUAGES "CXX")
			list(REMOVE_DUPLICATES __LANGUAGES)
			if(__LANGUAGES)
				foreach(__LANGUAGE IN LISTS __LANGUAGES)
#					message(STATUS "${__PADDING}finalizer(): About to enable language ${__LANGUAGE}")
         		enable_language( ${__LANGUAGE} OPTIONAL)
            	if(NOT CMAKE_${__LANGUAGE}_COMPILER)
            	   missing_language(${__LANGUAGE} "component")
	            endif()
				endforeach()
			endif()
		else()
			message("    DEFINING  TARGETS  IN  SUPERBUILD")
			message("")
		endif()
		if(__DUMP_TREE)
			set_property(GLOBAL PROPERTY __BURAK_GRAPH_FILENAME "${CMAKE_CURRENT_BINARY_DIR}/dependency_tree.dot")
			_graphviz_preamble()
		endif()
		foreach(__DEP_ID IN LISTS __INSTANCE_ID_LIST)
#			message(STATUS "${__PADDING}finalizer(): Going to instantiate ${__DEP_ID}")
#			_debug_show_instance(${__DEP_ID} 2 "" __MSG __ERRORS)
#			message("${__MSG}")
#			if(__ERRORS)
#				message(FATAL_ERROR ${__ERRORS})
#			endif()
			_instantiate_target(${__DEP_ID})
			if(__DUMP_TREE)
				_dump_instance(${__DEP_ID} __DUMMY)
			endif()
		endforeach()
		if(__DUMP_TREE)
			_graphviz_epilogue()
		endif()
		if(NOT __NOT_SUPERBUILD)
			_retrieve_global_data(EXTERNAL_TARGETS __EXTERNAL_DEPENDENCIES)
			if(__EXTERNAL_DEPENDENCIES)
				set(__EXT_DEP_STR)
				set(__EXT_DEP_NICE_STR)
				foreach(__EXT_DEP IN LISTS __EXTERNAL_DEPENDENCIES)
					string(REPLACE "::" "_" __EXT_DEP_FIXED ${__EXT_DEP})
					list(APPEND __EXT_DEP_NICE_STR ${__EXT_DEP_FIXED})
					list(APPEND __EXT_DEP_STR ${__EXT_DEP_FIXED})
				endforeach()
				nice_list_output(OUTVAR __EXT_DEP_NICE LIST ${__EXT_DEP_NICE_STR})
				message(STATUS "End of SUPERBUILD phase. External projects: ${__EXT_DEP_NICE}. CMAKE_PROJECT_NAME: ${CMAKE_PROJECT_NAME}")
				set(__EXT_DEP_STR "DEPENDS" ${__EXT_DEP_STR})
			else()
				message(STATUS "End of SUPERBUILD phase. No external projects (why superbuild?). CMAKE_PROJECT_NAME: ${CMAKE_PROJECT_NAME}")
			endif()
#			message(STATUS "${__PADDING}finalizer(): ExternalProject_Add(${CMAKE_PROJECT_NAME} PREFIX ${CMAKE_SOURCE_DIR} SOURCE_DIR ${CMAKE_SOURCE_DIR} TMP_DIR ${CMAKE_CURRENT_BINARY_DIR}/project/tmp STAMP_DIR ${CMAKE_CURRENT_BINARY_DIR}/project/stamps DOWNLOAD_DIR \"${CMAKE_CURRENT_BINARY_DIR}\" INSTALL_COMMAND \"\" BUILD_ALWAYS ON BINARY_DIR \"${CMAKE_CURRENT_BINARY_DIR}/project\" ${__EXT_DEP_STR} CMAKE_ARGS -D__NOT_SUPERBUILD=ON)")
			if(__SUPERBUILD_TEST_ON_BUILD)
				set(__SUPERBUILD_TEST_ON_BUILD ON)
			else()
				set(__SUPERBUILD_TEST_ON_BUILD OFF)
			endif()
			if (NOT CMAKE_CONFIGURATION_TYPES)
				set(__PROPAGATE_BUILD_TYPE -DCMAKE_BUILD_TYPE=$<CONFIG>) #see https://gitlab.kitware.com/cmake/cmake/issues/17645
			endif()
#			message(STATUS "${__PADDING}finalizer(): __SUPERBUILD_TEST_ON_BUILD: ${__SUPERBUILD_TEST_ON_BUILD}")
			ExternalProject_Add(${CMAKE_PROJECT_NAME}
				${__EXT_DEP_STR}
				PREFIX ${CMAKE_SOURCE_DIR}
				SOURCE_DIR ${CMAKE_SOURCE_DIR}
				TMP_DIR ${CMAKE_CURRENT_BINARY_DIR}/project/tmp
				STAMP_DIR ${CMAKE_CURRENT_BINARY_DIR}/project/stamps
				DOWNLOAD_DIR "${CMAKE_CURRENT_BINARY_DIR}"
				INSTALL_COMMAND ""
				BUILD_ALWAYS ON
				BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/project"
				TEST_BEFORE_INSTALL ${__SUPERBUILD_TEST_ON_BUILD}
				CMAKE_ARGS -D__NOT_SUPERBUILD=ON ${__PROPAGATE_BUILD_TYPE}
			)
			if(__SUPERBUILD_TRIGGER_TESTS)
				add_custom_target(test
					ctest
					WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/project
				)
			endif()
		endif()
		missing_dependency(FINALIZE)
	else()
		message(WARNING "No targets declared in the CMakeLists.txt. Add targets you want to build using build_target()")
	endif()
endmacro()


macro(finalize)
	finalizer()
endmacro()

macro(_get_all_languages __OUT_LANGUAGES) 
	_gather_languages()
	_retrieve_global_data(ALL_LANGUAGES ${__OUT_LANGUAGES})
endmacro()

function(_gather_languages )
	_retrieve_global_data(INSTANCES __INSTANCE_ID_LIST)
	foreach(__INSANCE_ID IN LISTS __INSTANCE_ID_LIST)
#		message(STATUS "${__PADDING}_gather_languages(): __INSANCE_ID: ${__INSANCE_ID}")
		_gather_language_rec(${__INSANCE_ID} "")
	endforeach()
endfunction()

function(_gather_language_rec __INSTANCE_ID __STACK)
	if("${__INSTANCE_ID}" IN_LIST __STACK)
		set(__OUT)
		foreach(__ITEM IN LISTS __STACK)
			_get_nice_instance_name("${__ITEM}" __NICE_NAME)
			if(NOT "${__OUT}" STREQUAL "")
				set(__OUT "${__OUT}, which requires ")
			endif()
			set(__OUT "${__OUT}${__NICE_NAME}")
		endforeach()
		set(__OUT "${__OUT}, which requires the first item again.")
#		nice_list_output(LIST "${__INSTANCE_LIST}" OUTVAR __OUTVAR) #We cannot use nice_instance_output at this stage, because nothing is saved yet.
		message(FATAL_ERROR "Cyclic dependency graph encountered. ${__OUT}")
	endif()
	list(APPEND __STACK "${__INSTANCE_ID}")
	_retrieve_instance_data(${__INSTANCE_ID} IS_PROMISE __IS_PROMISE)
	if(__IS_PROMISE)
		_retrieve_instance_data(${__INSTANCE_ID} I_TEMPLATE_NAME __TEMPLATE_NAME)
		_retrieve_template_data(${__TEMPLATE_NAME} T_PATH __TARGETS_CMAKE_PATH)
		_retrieve_instance_data(${__INSTANCE_ID} I_PARENTS __PARENTS)
#		set(__NICE_PARENTS)
#		message(STATUS "${__PADDING}_gather_language_rec(): __PARENTS: ${__PARENTS}")
		_get_nice_instance_names(__PARENTS __NICE_PARENTS_LIST)
#		foreach(__PARENT IN LISTS __PARENTS)
#			message(STATUS "${__PADDING}_gather_language_rec(): __PARENT: ${__PARENT}")
#			_get_nice_instance_name(${__PARENT} __NICE_NAME)
#			list(APPEND __NICE_PARENTS "${__NICE_NAME}")
#		endforeach()
#		nice_list_output(LIST ${__NICE_PARENTS} OUTVAR __NICE_PARENTS_LIST)
		
		_debug_show_instance(${__INSTANCE_ID} 2 "Unresolved instance error: " __MSG __ERRORS)
#		message(STATUS "${__PADDING}_gather_language_rec():\n${__MSG}")
		if(__ERRORS)
			message(STATUS "Error when gathering languages from instance:\n${__MSG}")
#			message(STATUS "${__PADDING}_promote_instance(): After promotion:\nx x x x x x x x x x x\n${__MSG}")
			message(FATAL_ERROR ${__ERRORS})
		endif()

		
		message(FATAL_ERROR "Template ${__TEMPLATE_NAME} (__INSTANCE_ID: ${__INSTANCE_ID}) is only required by means of function get_existing_target() (used as dependency of ${__NICE_PARENTS_LIST}), and never actually defined. You have to use function build_target() for this template somewhere once to instantiate this template.")
	endif()
	
	_retrieve_instance_data(${__INSTANCE_ID} LANGUAGES __LANGUAGES)
#	message(STATUS "${__PADDING}_gather_languages(): __LANGUAGES: ${__LANGUAGES}")
	if(__LANGUAGES)
		_retrieve_instance_data(${__INSTANCE_ID} F_PATH __PATH)
		_make_path_hash("${__PATH}" __KEY)
		_add_property_to_db(GLOBAL ALL ALL_LANGUAGES "${__LANGUAGES}")
	endif()
	_retrieve_instance_data(${__INSTANCE_ID} DEP_INSTANCES __DEP_IDS)
	if(__DEP_IDS)
		foreach(__DEP_ID IN LISTS __DEP_IDS)
			_gather_language_rec(${__DEP_ID} "${__STACK}")
		endforeach()
	endif()
endfunction()


# Iterate over all featurebases. For each featurebase make sure that the instances that link to them agree in the requested features
function(_resolve_features)
	_retrieve_global_data(FEATUREBASES __ALL_FEATUREBASES)
#	message("")
#	message("")
#	message(STATUS "${__PADDING}_resolve_features(): All featurebases to resolve: ${__ALL_FEATUREBASES}")
	string(MD5 __NEW_HASH_FEATUREBASES "${__ALL_FEATUREBASES}") #Hash of current list of all featurebases that need to be processed.
	#We need it to distinguish a case when the iteration did not resolve any of the featurebases and needs to report an error.
	set(__OLD_HASH_FEATUREBASES)
	while(NOT "${__OLD_HASH_FEATUREBASES}" STREQUAL "${__NEW_HASH_FEATUREBASES}" OR __SOMETHING_MODIFIED)
#		message(STATUS "${__PADDING}_resolve_features(): Beginning of the featurebase resolve round with __ALL_FEATUREBASES: ${__ALL_FEATUREBASES}")
		set(__SOMETHING_MODIFIED 0)
		foreach(__FEATUREBASE_ID IN LISTS __ALL_FEATUREBASES)
			_get_promises_by_featurebase(${__FEATUREBASE_ID} __PROMISE_IDS __MORE_FEATUREBASES) #Although we want to process ${__FEATUREBASE_ID},
			#we might need to resolve more featurebases, because of JOINED_TARGETS. When a template file has JOINED_TARGETS property,
			#the parameters and features are obviously shared, and there is a separate featurebase for each template name. 
			#This is the only place in the beetroot where we need to merge the JOINED_TARGETS and treat them as one.
#			message(STATUS "${__PADDING}_resolve_features(): __FEATUREBASE_ID \"${__FEATUREBASE_ID}\" got following promises: __PROMISE_IDS: ${__PROMISE_IDS}. List of competing featurebases for these promises: __MORE_FEATUREBASES: ${__MORE_FEATUREBASES}")
			_resolve_features_for_featurebases(__MORE_FEATUREBASES __PROMISE_IDS __STATUSES) #This is the function that does the actual
			#merging.
#			message(STATUS "${__PADDING}_resolve_features(): Resolving got status(es) __STATUSES: ${__STATUSES}")
			list(LENGTH __MORE_FEATUREBASES __PROCESSED_FB_COUNT)
			math(EXPR __PROCESSED_FB_COUNT "${__PROCESSED_FB_COUNT}-1")
#			message(STATUS "${__PADDING}_resolve_features(): __PROCESSED_FB_COUNT: ${__PROCESSED_FB_COUNT}")
			foreach(__PROCESSED_FB_NR RANGE ${__PROCESSED_FB_COUNT})
#			    message(STATUS "${__PADDING}_resolve_features(): list(GET __ALL_FEATUREBASES ${__PROCESSED_FB_NR} __PROCESSED_FEATUREBASE) with __ALL_FEATUREBASES: ${__ALL_FEATUREBASES}")
			    if("${__ALL_FEATUREBASES}" STREQUAL "")
			        break()
			    endif()
				list(GET __MORE_FEATUREBASES ${__PROCESSED_FB_NR} __PROCESSED_FEATUREBASE)
				list(GET __STATUSES ${__PROCESSED_FB_NR} __STATUS)
				
				if("${__STATUS}" STREQUAL "NOT_MODIFIED")
#					message(STATUS "${__PADDING}_resolve_features(): __PROCESSED_FEATUREBASE: ${__PROCESSED_FEATUREBASE} resolved, status NOT_MODIFIED")
#					_get_nice_featurebase_name(__PROCESSED_FEATUREBASE __OUT_NICE_NAME)
#					message(STATUS "${__PADDING}_resolve_features(): Removing ${__PROCESSED_FEATUREBASE}, ${X__OUT_NICE_NAME}...")
					list(REMOVE_ITEM __ALL_FEATUREBASES "${__PROCESSED_FEATUREBASE}")
					_add_property_to_db(GLOBAL ALL FEATUREBASES ${__PROCESSED_FEATUREBASE} ) #To not trigger error if the featurbase was already removed. It can be optiomized.
					_remove_property_from_db(GLOBAL ALL FEATUREBASES ${__PROCESSED_FEATUREBASE} )
				elseif("${__STATUS}" STREQUAL "MODIFIED") #The feature list has been modified. We need to process it again to make sure that this modification agrees with other instances pointing to it
#					message(STATUS "${__PADDING}_resolve_features(): __PROCESSED_FEATUREBASE: ${__PROCESSED_FEATUREBASE} resolved, status MODIFIED, will retry")
#					_set_property_to_db(FEATUREBASEDB ${__PROCESSED_FEATUREBASE} COMPAT_INSTANCES "${__FEATURE_INSTANCES}" FORCE)
					set(__SOMETHING_MODIFIED 1)
				elseif("${__STATUS}" STREQUAL "POSTPONED") #We cannot resolve target name, so we decide to postpone in hope that in the new iteration
					#target will be found.
#					message(STATUS "${__PADDING}_resolve_features(): __PROCESSED_FEATUREBASE: ${__PROCESSED_FEATUREBASE} resolved, status POSTPONED, will retry")
				else()
					message(FATAL_ERROR "Internal beetroot error: unknown __STATUS from _resolve_features_for_featurebase(): ${__STATUS} (all statuses: ${__STATUSES})")
				endif()				
			endforeach()
		endforeach()	
		if("${__ALL_FEATUREBASES}" STREQUAL "")
			break()
		endif()
		set(__OLD_HASH_FEATUREBASES "${__NEW_HASH_FEATUREBASES}")
		string(MD5 __NEW_HASH_FEATUREBASES "${__ALL_FEATUREBASES}")
#		_retrieve_global_data(FEATUREBASES __ALL_FEATUREBASES)
#		message(STATUS "${__PADDING}_resolve_features(): next iteration __ALL_FEATUREBASES: ${__ALL_FEATUREBASES}")
	endwhile()
	if(NOT "${__ALL_FEATUREBASES}" STREQUAL "")
		message(FATAL_ERROR "${__PADDING}_resolve_features(): Could not resolve dependencies for __ALL_FEATUREBASES: ${__ALL_FEATUREBASES}")
		_get_nice_featurebase_names(__ALL_FEATUREBASES __FEATUREBASES_TXT)
#		message(STATUS "${__PADDING}_resolve_features(): __ALL_FEATUREBASES: ${__ALL_FEATUREBASES}")
		message(FATAL_ERROR "Beetroot error: Could not resolve dependencies for the following featurebases: ${__FEATUREBASES_TXT}. Possible cause: circular referencies")
	endif()
endfunction()

# Arrive at the common set of features for the given set of __IN_FEATUREBASE_IDS. 
# If we needed to change the featurebase, set ${__OUT_STATUS} in the parent scope.
# __OUT_STATUS is a vector of status strings of the same length as the ${__IN_FEATUREBASE_IDS}
function(_resolve_features_for_featurebases __IN_FEATUREBASE_IDS __IN_PROMISES __OUT_STATUS)
	#Two things in a single loop: get list of the all instances and populate error messages
#	message(STATUS "${__PADDING}_resolve_features_for_featurebases(): __IN_FEATUREBASE_IDS: ${__IN_FEATUREBASE_IDS}: ${${__IN_FEATUREBASE_IDS}}  __IN_PROMISES: ${__IN_PROMISES}: ${${__IN_PROMISES}}")

	set(__FEATURE_INSTANCES)
	set(__OUT)
	#Prepare the data return structure - fill it with (error) values. The function will replace them with correct values.
	foreach(__FEATUREBASE_ID IN LISTS ${__IN_FEATUREBASE_IDS})
		list(APPEND __OUT "ERROR") #By default we set error messages, just in case
		set(__I2FBS_${__FEATUREBASE_ID} ) #Zero list of instances for this featurebase. We will need that in future, but we want to 
	endforeach()
	set(${__OUT_STATUS} ${__OUT} PARENT_SCOPE)
	list(LENGTH ${__IN_FEATUREBASE_IDS} __FEATUREBASE_COUNT)
	math(EXPR __FEATUREBASE_COUNT "${__FEATUREBASE_COUNT} - 1")
	
	#Shortcut return if there are no promise instances.
	list(LENGTH ${__IN_PROMISES} __INSTANCES_COUNT)
	if(${__INSTANCES_COUNT} EQUAL 0)
		set(__OUT)
		foreach(__FEATUREBASE_ID IN LISTS ${__IN_FEATUREBASE_IDS})
			list(APPEND __OUT "NOT_MODIFIED")
		endforeach()
		set(${__OUT_STATUS} ${__OUT} PARENT_SCOPE)
#		message(STATUS "${__PADDING}_resolve_features_for_featurebases(): __FEATURE_INSTANCES: ${__FEATURE_INSTANCES}, __IN_FEATUREBASE_IDS: ${__IN_FEATUREBASE_IDS}: ${${__IN_FEATUREBASE_IDS}} shortcut exit due to no instances (\"${__FEATURE_INSTANCES}\")")
		return()
	endif()
	set(__FEATURE_INSTANCES ${${__IN_PROMISES}})
	list(REMOVE_DUPLICATES __FEATURE_INSTANCES)
	if("${__FEATURE_INSTANCES}" STREQUAL "")
		#Just a meaningful error message
		#TODO: Add "... and make sure the parameters (list of the parameters) match"
   	_retrieve_instance_data(${__INSTANCE_ID} I_PARENTS __I_PARENTS)
		message(FATAL_ERROR "Beetroot error: Cannot find any non-virtual targets that satisfy the virtual dependency ${__INSTANCE_ID} (required by ${__I_PARENTS}). Define the target that will fit it using `get_target()` somewhere, or replace the call to the `get_existing_target()` with `get_target()`.")
	endif()
#	message(STATUS "${__PADDING}_resolve_features_for_featurebases(): promises to check (__FEATURE_INSTANCES): ${__FEATURE_INSTANCES}, __IN_FEATUREBASE_IDS->${__IN_FEATUREBASE_IDS}->${${__IN_FEATUREBASE_IDS}}")

	#There may be more than one featurebase. First we need to make the compatibility list for each promise, 
	#i.e. to see with what featurebases each promise is compatible with based solely on modifiers, not features. Later on we 
	#make sure, that each promise is compatible with exaclty one featurebase.
	foreach(__INSTANCE_ID IN LISTS __FEATURE_INSTANCES)
		set(__COMP_FB_ID) #compatible featurebase. Empty means no compatible was found
		set(__NON_COMP_FID) #list of non-compatible instances with __INSTANCE_ID
		set(__NON_COMP_REASON) #reasons of non-compatibility. Needed for error reporting.
		foreach(__FEATUREBASE_ID IN LISTS ${__IN_FEATUREBASE_IDS})
			_is_promise_compatible_with_featurebase(${__INSTANCE_ID} ${__FEATUREBASE_ID} __IS_COMPATIBLE __DIFF __ALL_PARS)
#			message(STATUS "${__PADDING}_resolve_features_for_featurebases(): Compatibility between virt. instance ${__INSTANCE_ID} and fb ${__FEATUREBASE_ID} - is compatible: ${__IS_COMPATIBLE}, diff: ${__DIFF}")
			if(__IS_COMPATIBLE)
				if("${__COMP_FB_ID}" STREQUAL "")
					list(APPEND __COMP_FB_ID "${__FEATUREBASE_ID}") #We found compatible featurebase of this promise
				endif()
			else()
				list(APPEND __NON_COMP_FID ${__FEATUREBASE_ID})
				list(APPEND __NON_COMP_REASON ${__DIFF})
			endif()
		endforeach()
		#Error handling in case there are no compatible featurebases for this virtual instance
		if("${__COMP_FB_ID}" STREQUAL "") 
			list(LENGTH __COMP_FB_ID __COUNT)
			math(EXPR __COUNT "${__COUNT}-1")
			set(__FBS)
			foreach(__FB_NR RANGE ${__COUNT})
				list(GET __NON_COMP_FID ${__FB_NR} __FEATUREBASE_ID)
				_get_nice_featurebase_name(${__FEATUREBASE_ID} __FB_TXT)
				list(GET __NON_COMP_REASON ${__FB_NR} __REASON)
				set(__FB_TXT "${__FB_TXT} sets ${__REASON}")
				list(APPEND __FBS "${__FB_TXT}")
			endforeach()
			nice_list_output(LIST "${__FBS}" OUTVAR __FB_TXT)
         	_retrieve_instance_data(${__INSTANCE_ID} I_PARENTS __I_PARENTS)
         	_get_nice_instance_name("${__INSTANCE_ID}" __NICE_INSTANCE_ID)
         	_get_nice_instance_names(__I_PARENTS __NICE_PARENTS_ID)
			message(FATAL_ERROR "Beetroot error: The are no non-virtual targets based on the same template as ${__NICE_INSTANCE_ID} (required by ${__NICE_PARENTS_ID}) that can be matched because of different parameters. ${__FB_TXT}")
		endif()
		list(LENGTH __COMP_FB_ID __COMP_FB_ID_COUNT)
		if(__COMP_FB_ID_COUNT GREATER 1)
			_retrieve_instance_data(${__INSTANCE_ID} I_PARENTS __I_PARENTS)
			_get_nice_instance_name("${__INSTANCE_ID}" __NICE_INSTANCE_ID)
			_get_nice_instance_names(__I_PARENTS __NICE_PARENTS_ID)
			_get_nice_featurebase_names(__COMP_FB_ID __NICE_FBS)
			message(FATAL_ERROR "Beetroot error: Virtual dependency ${__NICE_INSTANCE_ID} (required by ${__NICE_PARENTS_ID}) can be successfully instantiated by at least two different compatible non-promise targets: ${__NICE_FBS}. Trun all but one of these targets into promises (replace \"build_target\" with \"get_existing_target\") or make sure the targets are built with identical build parameters and features. ")
		endif()
		list(APPEND __I2FBS_${__COMP_FB_ID} ${__INSTANCE_ID}) #Add the instance to the list of instances compatible with featurebase ${__COMP_FB_ID}
	endforeach()

	#Now we know that each instance is uniqually matched to the existing featurebase it is compatible with.
	#It is time to resolve the features for each featurebase and fill the return vector
	
#	message(STATUS "${__PADDING}_resolve_features_for_featurebases(): __FEATURE_INSTANCES: ${__FEATURE_INSTANCES} __FEATUREBASE_COUNT: ${__FEATUREBASE_COUNT} ${__IN_FEATUREBASE_IDS}: ${${__IN_FEATUREBASE_IDS}}")
	set(__OUT)
	foreach(__FEATUREBASE_NR RANGE ${__FEATUREBASE_COUNT})
		list(GET ${__IN_FEATUREBASE_IDS} ${__FEATUREBASE_NR} __FEATUREBASE_ID)
		_resolve_features_for_featurebase(${__FEATUREBASE_ID} __I2FBS_${__FEATUREBASE_ID} __RET_STATUS)
		list(APPEND __OUT "${__RET_STATUS}")
	endforeach()
	set(${__OUT_STATUS} ${__OUT} PARENT_SCOPE)
	return()

endfunction()

#Check if the set of modifiers (target parameters) associated with the promise __INSTANCE_ID is compatible with the featurebase
function(_is_promise_compatible_with_featurebase __INSTANCE_ID __FEATUREBASE_ID __OUT_STATUS __OUT_DIFF __OUT_ALL_VARS)
	_retrieve_instance_args(${__INSTANCE_ID} PROMISE_PARAMS __PROMISE_PARAMS)
	_retrieve_featurebase_args(${__FEATUREBASE_ID} MODIFIERS __FB_MODIFIERS)
	_retrieve_instance_data(${__INSTANCE_ID} PROMISE_PARAMS __DEBUG_PROMISE_PARAMS)
#	message(STATUS "${__PADDING}_is_promise_compatible_with_featurebase(): FB: ${__FEATUREBASE_ID} and promise ${__INSTANCE_ID} have the following modifiers: ${__DEBUG_PROMISE_PARAMS}")
	
	foreach(__ARG IN LISTS __PROMISE_PARAMS__LIST)
		if("${__PROMISE_PARAMS_${__ARG}}" STREQUAL "${__FB_MODIFIERS_${__ARG}}")
#			message(STATUS "${__PADDING}_is_promise_compatible_with_featurebase(): modifier ${__ARG}=${__FB_MODIFIERS_${__ARG}} is compatible between FB: ${__FEATUREBASE_ID} and promise ${__INSTANCE_ID}")
		elseif("${__PROMISE_PARAMS_${__ARG}}" STREQUAL "")
#			message(STATUS "${__PADDING}_is_promise_compatible_with_featurebase(): modifier ${__ARG} is not set in the promise ${__INSTANCE_ID}, so it is compatible with all FB, e.g.: ${__FEATUREBASE_ID}")
		else()
			set(${__OUT_DIFF} "${__ARG}=${__PROMISE_PARAMS_${__ARG}} vs ${__FB_MODIFIERS_${__ARG}}" PARENT_SCOPE)
			set(${__OUT_STATUS} 0 PARENT_SCOPE)
#			message(STATUS "${__PADDING}_is_promise_compatible_with_featurebase(): modifier ${__ARG} is NOT compatible between FB: ${__FEATUREBASE_ID} (=${__FB_MODIFIERS_${__ARG}}) and promise ${__INSTANCE_ID} (=${__PROMISE_PARAMS_${__ARG}})")
			return()
		endif()
	endforeach()
	set(${__OUT_STATUS} 1 PARENT_SCOPE)
	set(${__OUT_DIFF} "" PARENT_SCOPE)
	set(${__OUT_ALL_VARS} ${__PROMISE_PARAMS__LIST} PARENT_SCOPE)
endfunction()

# Arrive at the common set of features for the given __FEATUREBASE_ID. 
# If we needed to change the featurebase, set ${__OUT_MODIFIED} in the parent scope.
function(_resolve_features_for_featurebase __FEATUREBASE_ID __IN_PROMISES __OUT_STATUS)
	set(${__OUT_STATUS} "ERROR" PARENT_SCOPE)
	set(__FEATURE_INSTANCES ${${__IN_PROMISES}})

#	message(STATUS "${__PADDING}_resolve_features_for_featurebase(): called with __FEATUREBASE_ID ${__FEATUREBASE_ID}, __IN_PROMISES: ${__IN_PROMISES}: ${${__IN_PROMISES}}")
	
	
	list(LENGTH __FEATURE_INSTANCES __INSTANCES_COUNT)
	if(${__INSTANCES_COUNT} EQUAL 0)
		set(${__OUT_STATUS} "NOT_MODIFIED" PARENT_SCOPE)
	endif()
#		if(${__INSTANCES_COUNT} EQUAL 1)
#			#Only one featurebase - there is little to do. 
#			_remove_property_from_db(GLOBAL ALL FEATUREBASES ${__FEATUREBASE_ID} )
#			continue()
#		endif()

	_retrieve_featurebase_args(${__FEATUREBASE_ID} F_FEATURES __BASE_ARGS)
	_serialize_variables(__BASE_ARGS __BASE_ARGS__LIST __SERIALIZED_FEATURE_ARGS)
#	message(STATUS "${__PADDING}_resolve_features_for_featurebase(): __FEATUREBASE_ID: ${__FEATUREBASE_ID} with ${__SERIALIZED_FEATURE_ARGS}")
	

	_calculate_hash(__BASE_ARGS __BASE_ARGS__LIST "" __BASE_HASH __BASE_HASH_SOURCE)
	_retrieve_featurebase_data(${__FEATUREBASE_ID} F_PATH __TARGETS_CMAKE_PATH)
#	message(STATUS "${__PADDING}_resolve_features_for_featurebase(): __FEATUREBASE_ID ${__FEATUREBASE_ID} has __TARGETS_CMAKE_PATH: ${__TARGETS_CMAKE_PATH}")
	_make_path_hash("${__TARGETS_CMAKE_PATH}" __FILE_HASH)
	_retrieve_featurebase_data(${__FEATUREBASE_ID} PARS __SERIALIZED_PARS__LIST)
	_unserialize_parameters(__SERIALIZED_PARS __PARS)
	
#	message("__________________________________________________")
#	message(STATUS "${__PADDING}_resolve_features_for_featurebase(): attempting to resolve featurebase ${__FEATUREBASE_ID}. All __FEATURE_INSTANCES: ${__FEATURE_INSTANCES}. ")
#	foreach(__I IN LISTS __FEATURE_INSTANCES)
#		_debug_show_instance(${__I} 2 "${__I}: " __MSG __ERRORS)
#		message("${__MSG}")
#		if(__ERRORS)
#			message(FATAL_ERROR ${__ERRORS})
#		endif()
#	endforeach()
	set(__INSTANCES_TO_MODIFY ${__PROMISES}) #Promises automatically always need to be modifies
	
	#In the following loop we are compiling the most compatible set of features for all 
	#the instances (virtual or not) of the given featurebase.
	set(__MODIFIED 0)
	foreach(__INSTANCE_ID IN LISTS __FEATURE_INSTANCES)
		#We must make sure, that all features agree with the features declared in the featureabase
		_retrieve_instance_args(${__INSTANCE_ID} I_FEATURES __I_ARGS)
		list_union(__VARNAMES __BASE_ARGS__LIST __I_ARGS__LIST)
		_serialize_parameters(__PARS __SERIALIZED_PARS)
#		message(STATUS "${__PADDING}_resolve_features_for_featurebase(): 0. Serialized parameters: ${__SERIALIZED_PARS}")
		_make_promoted_featureset("${__FILE_HASH}" "${__VARNAMES}" __PARS __BASE_ARGS __I_ARGS __COMMON_ARGS __OUT_RELATION)

#		_serialize_variables(__COMMON_ARGS __COMMON_ARGS__LIST __SERIALIZED_COMMON_ARGS)
#		_serialize_variables(__BASE_ARGS __BASE_ARGS__LIST __SERIALIZED_FEATURE_ARGS)
#		_serialize_variables(__I_ARGS __I_ARGS__LIST __SERIALIZED_INSTANCE_ARGS)
#		message(STATUS "${__PADDING}_resolve_features_for_featurebase(): 1. __INSTANCE_ID: ${__INSTANCE_ID} with ${__SERIALIZED_INSTANCE_ARGS}")
#		message(STATUS "${__PADDING}_resolve_features_for_featurebase(): 2. __FEATUREBASE_ID: ${__FEATUREBASE_ID} with ${__SERIALIZED_FEATURE_ARGS}")
#		message(STATUS "${__PADDING}_resolve_features_for_featurebase(): 3. We arrived at the conclusion of ${__SERIALIZED_COMMON_ARGS}. __OUT_RELATION: ${__OUT_RELATION}")
		if(${__OUT_RELATION} STREQUAL 0)
			#do nothing
		elseif(${__OUT_RELATION} STREQUAL 1)
			#Base is bigger than the instance. Do nothing.
		elseif(${__OUT_RELATION} EQUAL 2 OR ${__OUT_RELATION} EQUAL 3 )
			set(__MODIFIED 1)
			#Promote all variables from __COMMON_ARGS into the base
			foreach(__VAR IN LISTS __COMMON_ARGS__LIST)
				set(__BASE_ARGS_${__VAR} "${__COMMON_ARGS_${__VAR}}")
			endforeach()
			set(__BASE_ARGS__LIST ${__COMMON_ARGS__LIST})
		elseif(${__OUT_RELATION} STREQUAL 4)
			_serialize_variables(__I_ARGS __I_ARGS__LIST __SERIALIZED_I_ARGS)
			_get_nice_instance_name(${__INSTANCE_ID} __NICE_INSTANCE_NAME)
			_get_nice_featurebase_name(${__FEATUREBASE_ID} __NICE_FEATUREBASE)
        	_serialize_variables(__BASE_ARGS __BASE_ARGS__LIST __SERIALIZED_COMMON_ARGS__LIST)
			message(FATAL_ERROR "Cannot promote a promise ${__NICE_INSTANCE_NAME} with arguments ${__SERIALIZED_I_ARGS} into an existing featurebase ${__NICE_FEATUREBASE} with the arguments ${__SERIALIZED_COMMON_ARGS__LIST} because the two sets of arguments are impossible to merge and Beetroot was instructed not to spawn a new instance of it. Check if the arguments change the arguments from FEATURES into a BUILD_PARAMETERS.")
		else()
			message(FATAL_ERROR "Internal Beetroot error: unknown __OUT_RELATION ${__OUT_RELATION} returned from _make_promoted_featureset()")
		endif()
		_debug_show_instance(${__INSTANCE_ID} 2 "BEFORE PROMOTION: " __MSG __ERRORS)
#			message(STATUS "${__PADDING}_resolve_features_for_featurebase(): Before promotion:\nx x x x x x x x x x x\n${__MSG}")
		if(__ERRORS)
			message(FATAL_ERROR ${__ERRORS})
		endif()			
	endforeach()
	_calculate_hash(__BASE_ARGS __BASE_ARGS__LIST "" __BASE_HASH __BASE_HASH_SOURCE)
	_serialize_variables(__BASE_ARGS __BASE_ARGS__LIST __SERIALIZED_COMMON_ARGS__LIST)
	#Update the features
	_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} F_FEATURES "${__SERIALIZED_COMMON_ARGS__LIST}" FORCE)
	_retrieve_featurebase_data(${__FEATUREBASE_ID} MODIFIERS __SERIALIZED_MODIFIERS)
#		message(STATUS "${__PADDING}_resolve_features_for_featurebase(): - - - - - - - - - - - -")
#		message(STATUS "${__PADDING}_resolve_features_for_featurebase(): Starting promotions for __FEATURE_INSTANCES: ${__FEATURE_INSTANCES} __SERIALIZED_MODIFIERS: ${__SERIALIZED_MODIFIERS}")

	#Now we know what is the biggest set of features. We can now proceed with triggering promotions
	foreach(__INSTANCE_ID IN LISTS __FEATURE_INSTANCES)
#			message(STATUS "_resolve_features_for_featurebase(): Trying to promote ${__INSTANCE_ID}")
		_retrieve_instance_args(${__INSTANCE_ID} I_FEATURES __I_ARGS)
		_retrieve_instance_data(${__INSTANCE_ID} IS_PROMISE __IS_PROMISE)
		_calculate_hash(__I_ARGS __I_ARGS__LIST "" __I_HASH __I_HASH_SOURCE)
		
		if(NOT "${__I_HASH}" STREQUAL "${__BASE_HASH}" OR __IS_PROMISE)
#			message(STATUS "${__PADDING}_resolve_features_for_featurebase(): About to promote ${__INSTANCE_ID} ${__FEATUREBASE_ID} \"${__SERIALIZED_COMMON_ARGS__LIST}\"")
			_promote_instance(${__INSTANCE_ID} ${__FEATUREBASE_ID} __SERIALIZED_COMMON_ARGS __NEW_INSTANCE_ID)
		else()
			set(__NEW_INSTANCE_ID ${__INSTANCE_ID})
		endif()

	endforeach()
	if("${__MODIFIED}" STREQUAL "1")
		set(${__OUT_STATUS} "MODIFIED" PARENT_SCOPE)
	else()
		set(${__OUT_STATUS} "NOT_MODIFIED" PARENT_SCOPE)
	endif()
endfunction()

function(_get_list_of_instances_that_need_to_be_resolved __FEATUREBASE_ID __OUT_INSTANCES )
	_retrieve_featurebase_data(${__FEATUREBASE_ID} COMPAT_INSTANCES __COMPAT_INSTANCES)
	_retrieve_featurebase_data(${__FEATUREBASE_ID} F_INSTANCES __ALL_INSTANCES)
#	message(STATUS "${__PADDING}_get_list_of_instances_that_need_to_be_resolved(): __COMPAT_INSTANCES: ${__COMPAT_INSTANCES} __ALL_INSTANCES: ${__ALL_INSTANCES}")
	list_diff(__OUT __ALL_INSTANCES __COMPAT_INSTANCES)
	set(${__OUT_INSTANCES} ${__OUT} PARENT_SCOPE)
endfunction()



#Gets all templates that are compatible with the given featurebase. May be more than one if JOINED_TARGETS.
function(_get_templates_by_featurebase __FEATUREBASE_ID __OUT_TEMPLATES)
	set(__OUT)
	set(__FEATUREBASES)
	_retrieve_featurebase_data(${__FEATUREBASE_ID} F_PATH __TARGETS_CMAKE_PATH)
	_make_path_hash("${__TARGETS_CMAKE_PATH}" __FILE_HASH)
	_retrieve_file_data("${__FILE_HASH}" JOINT_TARGETS __JOINT_TARGETS)
	if(__JOINT_TARGETS)
		_retrieve_file_data("${__FILE_HASH}" G_TEMPLATES __TEMPLATES)
#		message(STATUS "${__PADDING}_get_templates_by_featurebase(): JOINT_TARGETS. __FEATUREBASE_ID: ${__FEATUREBASE_ID} __TEMPLATES: ${__TEMPLATES}")
	else()
		set(__TEMPLATES)
		_retrieve_featurebase_data(${__FEATUREBASE_ID} F_INSTANCES __ALL_INSTANCES)
#		message(STATUS "${__PADDING}_get_templates_by_featurebase(): NORMAL TARGETS. __FEATUREBASE_ID: ${__FEATUREBASE_ID} __ALL_INSTANCES: ${__ALL_INSTANCES}")
		foreach(__INSTANCE_ID IN LISTS __ALL_INSTANCES)
			_retrieve_instance_data(${__INSTANCE_ID} I_TEMPLATE_NAME __TEMPLATE_NAME)
#			message(STATUS "${__PADDING}_get_templates_by_featurebase(): appending ${__TEMPLATE_NAME} to __TEMPLATES for __FEATUREBASE_ID: ${__FEATUREBASE_ID}")
			list(APPEND __TEMPLATES ${__TEMPLATE_NAME})
		endforeach()
		if(__TEMPLATES)
			list(REMOVE_DUPLICATES __TEMPLATES)
		endif()
	endif()
#	message(STATUS "${__PADDING}_get_templates_by_featurebase() found __TEMPLATES: ${__TEMPLATES} for __FEATUREBASE_ID: ${__FEATUREBASE_ID}")
	set(${__OUT_TEMPLATES} "${__TEMPLATES}" PARENT_SCOPE)
endfunction()

# Gets list of all promise instances that are registered for all the template names of the given featurebase 
# (in case of joined targets there may be more than one), 
# and are compatible with it when
function(_get_promises_by_featurebase __FEATUREBASE_ID __OUT_INSTANCES __OUT_ALL_FEATUREBASES)
	set(__OUT)
	set(__FEATUREBASES)
	_get_templates_by_featurebase(${__FEATUREBASE_ID} __TEMPLATE_NAMES)
#	message("")
#	message(STATUS "${__PADDING}_get_promises_by_featurebase(): Attempting to find all promises for __FEATUREBASE_ID: ${__FEATUREBASE_ID}. templates associated with this featurebase __TEMPLATE_NAMES: ${__TEMPLATE_NAMES}")
	if("${__TEMPLATE_NAMES}" STREQUAL "")
		message(FATAL_ERROR "Internal Beetroot error: Cannot get list of templates from the featurebase.")
	endif()
	
	#Collect all promise (sometimes named: virtual) instances that are created for that template and also
	#all existing featurebases. Matching them together is what is called "resolving featurebases".
	#
	#There may be more than one template associated with the given featurebase if targets are joined, and each template may have its own promises.
	foreach(__TEMPLATE_NAME IN LISTS __TEMPLATE_NAMES)
		_retrieve_template_data(${__TEMPLATE_NAME} VIRTUAL_INSTANCES __INSTANCES)
#		message(STATUS "${__PADDING}_get_promises_by_featurebase(): For __TEMPLATE_NAME: ${__TEMPLATE_NAME} found the following promises __INSTANCES: ${__INSTANCES}")
		list(APPEND __OUT ${__INSTANCES})
		_retrieve_template_data(${__TEMPLATE_NAME} TEMPLATE_FEATUREBASES __T_FEATUREBASES)
		list(APPEND __FEATUREBASES ${__T_FEATUREBASES})
	endforeach()
	if(__FEATUREBASES)
		list(REMOVE_DUPLICATES __FEATUREBASES)
	endif()
#	message(STATUS "${__PADDING}_get_promises_by_featurebase(): for this template (${__TEMPLATE_NAMES}) we found the following promise instances: ${__OUT}")
#	message(STATUS "${__PADDING}_get_promises_by_featurebase(): for this template (${__TEMPLATE_NAMES}) we found the following featurebases: ${__FEATUREBASES}")
	if(__OUT) #If promises were found
		list(REMOVE_DUPLICATES __OUT)
		foreach(__INSTANCE_ID IN LISTS __OUT)
			_retrieve_instance_data(${__INSTANCE_ID} IS_PROMISE __IS_PROMISE)
			if(NOT "${__IS_PROMISE}" STREQUAL "1")
				message(FATAL_ERROR "Internal beetroot error: consitency problem: ${__INSTANCE_ID} should be promise, but it isn't.")
			endif()
		endforeach()
		list(LENGTH __FEATUREBASES __FEATUREBASES_COUNT)
#		message(STATUS "${__PADDING}_get_promises_by_featurebase(): List of featurebases: __FEATUREBASES: ${__FEATUREBASES}")
	
		#TODO: Now is the time to filter out those featurebases, that are incompatible with the modifiers specified in the promises'  get_existing_target(<modifiers>)
		#
		set(${__OUT_INSTANCES} ${__OUT} PARENT_SCOPE)
		if(${__FEATUREBASES_COUNT} GREATER 1)
#			list(REMOVE_ITEM __FEATUREBASES ${__FEATUREBASE_ID})
			set(${__OUT_ALL_FEATUREBASES} ${__FEATUREBASES} PARENT_SCOPE)
			return()
			#Dead code below. It will be removed once the new 
			
			#Found more than one distinct featurebase defined (by using get_target()) that match the promises. 
			#In future we will try to filter them based on the match of the modifiers specified in the promise get_existing_target(<modifiers>).
			list(LENGTH __TEMPLATE_NAMES __TEMPLATE_COUNT)
			set(__FEATURES_AND_PARAMS)
			nice_list_output(OUTVAR __FEATURES_TXT LIST ${__FEATUREBASES})
			foreach(__FEATUREBASE IN LISTS __FEATUREBASES)
				_retrieve_featurebase_args(${__FEATUREBASE} F_FEATURES __FEAT_FEATS)
				_retrieve_featurebase_args(${__FEATUREBASE} MODIFIERS __FEAT_MODIFS)
				_retrieve_featurebase_data(${__FEATUREBASE} F_INSTANCES __FEAT_INSTANCES)
				list(GET __FEAT_INSTANCE 0 __FEAT_INSTANCE)
				if(NOT "${__FEAT_INSTANCE}" STREQUAL "")
					_retrieve_instance_data(${__FEAT_INSTANCE} I_TEMPLATE_NAME __FEAT_TEMPLATE_NAME)
					set(__TXT "${__FEAT_TEMPLATE_NAME}(${__FEATUREBASE})")
				else()
					set(__TXT "${__FEATUREBASE}")
				endif()
				if(__FEAT_FEATS__LIST)
					_nice_arg_list(__FEAT_FEATS __FEAT_FEATS__LIST __TMP)
					set(__TXT "${__TXT} with features ${__TMP}")
					set(__AND " and ")
				else()
					set(__AND " ")
				endif()
				if(__FEAT_MODIFS__LIST)
					_nice_arg_list(__FEAT_MODIFS __FEAT_MODIFS__LIST __TMP)
					set(__TXT "${__TXT}${__AND}with parameters ${__TMP}")
				endif()
				set(__FEATURES_AND_PARAMS "${__FEATURES_AND_PARAMS}${__TXT}\n")
			endforeach()
			nice_list_output(OUTVAR __FEATURES_AND_PARAMS_TXT LIST ${__FEATURES_AND_PARAMS})

			#TODO: To the error messages below perhaps I should list the parameters of all those instances (and maybe even the place it is requested?)
			if(${__TEMPLATE_COUNT} GREATER 1)
				nice_list_output(OUTVAR __NICE_LIST LIST ${__TEMPLATE_NAMES} )
				message(FATAL_ERROR "Cannot use get_existing_target() on templates ${__NICE_LIST}, because all those templates share an implementation and there is already more than one of it already requested, so the Beetroot does not know, which one to use. List of the conflicting feature bases: \n ${__FEATURES_AND_PARAMS}")
			else()
				message(FATAL_ERROR "Cannot use get_existing_target() on template ${__TEMPLATE_NAMES} because more than one instance of it is already requested, and the Beetroot does not know which one to use. List of the conflicting feature bases: \n ${__FEATURES_AND_PARAMS}")
			endif()
		endif()
	else()
#		message(STATUS "${__PADDING}_get_promises_by_featurebase(): No promise dependencies ('get_existing_target') found, nothing to do here")
		set(${__OUT_ALL_FEATUREBASES} ${__FEATUREBASES} PARENT_SCOPE)
		set(${__OUT_INSTANCES} "" PARENT_SCOPE)
	endif()
	set(${__OUT_ALL_FEATUREBASES} "${__FEATUREBASE_ID}" PARENT_SCOPE)
endfunction()
