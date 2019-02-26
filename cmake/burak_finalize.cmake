#Macro that generates a local project as the external dependency in the SUPERBUILD phase
#that depends on all external dependencies.
#
#It must be macro, because it has to enable languages, if enabled by any of the targets.
macro(finalizer)
	_set_property_to_db(GLOBAL ALL LAST_READ_FILE "NONE" FORCE)
	_get_target_behavior(__TARGET_BEHAVIOR)
	if("${__TARGET_BEHAVIOR}" STREQUAL "DEFINING_TARGETS")
		message(WARNING "finalizer called second time. This function is meant to be called only once at the very end of the root CMakeLists. Ignoring this call.")
		return()
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
	else()
		message("    DEFINING  TARGETS  IN  SUPERBUILD")
	endif()
	message("")
	_set_behavior_defining_targets() #To make sure we never call declare_dependencies()
	_resolve_features()
	
#	message("############### AFTER RESOLVE ##############")
	
	#Now we can assume that all features in all featuresets agree with the features in instances, which means that we can concatenate features to the target parameters (modifiers)
	_get_all_languages(__LANGUAGES)
	if(__LANGUAGES)
		foreach(__LANGUAGE IN LISTS __LANGUAGES)
#			message(STATUS "finalizer(): About to enable language ${__LANGUAGE}")
			enable_language(${__LANGUAGE})
		endforeach()
	endif()
	#Now we need to instantiate all the targets. 
	_retrieve_global_data(INSTANCES __INSTANCE_ID_LIST)
#	message(STATUS "finalizer: __INSTANCE_ID_LIST: ${__INSTANCE_ID_LIST}")
	if(__INSTANCE_ID_LIST)
		foreach(__DEP_ID IN LISTS __INSTANCE_ID_LIST)
#			message(STATUS "finalizer(): Going to instantiate ${__DEP_ID}")
#			_debug_show_instance(${__DEP_ID} 2 "" __MSG __ERRORS)
#			message("${__MSG}")
#			if(__ERRORS)
#				message(FATAL_ERROR ${__ERRORS})
#			endif()
			_instantiate_target(${__DEP_ID})
		endforeach()
		if(NOT __NOT_SUPERBUILD)
			_retrieve_global_data(EXTERNAL_DEPENDENCIES __EXTERNAL_DEPENDENCIES)
			if(__EXTERNAL_DEPENDENCIES)
				foreach(__EXT_DEP IN LISTS __EXTERNAL_DEPENDENCIES)
					string(REPLACE "::" "_" __EXT_DEP_FIXED ${__EXT_DEP})
					set(__EXT_DEP_STR ${__EXT_DEP_STR} ${__EXT_DEP_FIXED})
				endforeach()
				message(STATUS "End of SUPERBUILD phase. External projects: ${__EXT_DEP_STR} CMAKE_PROJECT_NAME: ${CMAKE_PROJECT_NAME}")
				set(__EXT_DEP_STR "DEPENDS" ${__EXT_DEP_STR})
			else()
				message(STATUS "End of SUPERBUILD phase. No external projects (why superbuild?). CMAKE_PROJECT_NAME: ${CMAKE_PROJECT_NAME}")
			endif()
#			message(STATUS "finalizer(): ExternalProject_Add(${CMAKE_PROJECT_NAME} PREFIX ${CMAKE_SOURCE_DIR} SOURCE_DIR ${CMAKE_SOURCE_DIR} TMP_DIR ${CMAKE_CURRENT_BINARY_DIR}/project/tmp STAMP_DIR ${CMAKE_CURRENT_BINARY_DIR}/project/stamps DOWNLOAD_DIR \"${CMAKE_CURRENT_BINARY_DIR}\" INSTALL_COMMAND \"\" BUILD_ALWAYS ON BINARY_DIR \"${CMAKE_CURRENT_BINARY_DIR}/project\" ${__EXT_DEP_STR} CMAKE_ARGS -D__NOT_SUPERBUILD=ON)")
			if(__SUPERBUILD_TEST_ON_BUILD)
				set(__SUPERBUILD_TEST_ON_BUILD ON)
			else()
				set(__SUPERBUILD_TEST_ON_BUILD OFF)
			endif()
#			message(STATUS "finalizer(): __SUPERBUILD_TEST_ON_BUILD: ${__SUPERBUILD_TEST_ON_BUILD}")
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
				CMAKE_ARGS -D__NOT_SUPERBUILD=ON
			)
			if(__SUPERBUILD_TRIGGER_TESTS)
				add_custom_target(test
					ctest
					WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/project
				)
			endif()
		endif()
	else()
		message(WARNING "No targets declared")
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
#		message(STATUS "_gather_languages(): __INSANCE_ID: ${__INSANCE_ID}")
		_gather_language_rec(${__INSANCE_ID})
	endforeach()
endfunction()

function(_gather_language_rec __INSTANCE_ID)
	_retrieve_instance_data(${__INSTANCE_ID} IS_PROMISE __IS_PROMISE)
	if(__IS_PROMISE)
		_retrieve_instance_data(${__INSTANCE_ID} I_TEMPLATE_NAME __TEMPLATE_NAME)
		_retrieve_template_data(${__TEMPLATE_NAME} T_PATH __TARGETS_CMAKE_PATH)
		_retrieve_instance_data(${__INSTANCE_ID} I_PARENTS __PARENTS)
#		set(__NICE_PARENTS)
#		message(STATUS "_gather_language_rec(): __PARENTS: ${__PARENTS}")
		_get_nice_names(__PARENTS __NICE_PARENTS_LIST)
#		foreach(__PARENT IN LISTS __PARENTS)
#			message(STATUS "_gather_language_rec(): __PARENT: ${__PARENT}")
#			_get_nice_name(${__PARENT} __NICE_NAME)
#			list(APPEND __NICE_PARENTS "${__NICE_NAME}")
#		endforeach()
#		nice_list_output(LIST ${__NICE_PARENTS} OUTVAR __NICE_PARENTS_LIST)
		
		_debug_show_instance(${__INSTANCE_ID} 2 "Unresolved instance error: " __MSG __ERRORS)
#		message(STATUS "_gather_language_rec():\n${__MSG}")
		if(__ERRORS)
			message(STATUS "Error when gathering languages from instance:\n${__MSG}")
#			message(STATUS "_promote_instance(): After promotion:\nx x x x x x x x x x x\n${__MSG}")
			message(FATAL_ERROR ${__ERRORS})
		endif()

		
		message(FATAL_ERROR "Template ${__TEMPLATE_NAME} (__INSTANCE_ID: ${__INSTANCE_ID}) is only required by means of function get_existing_target() (used for as dependency of ${__NICE_PARENTS_LIST}), and never actually defined. You have to use function build_target() for this template somewhere once to instantiate this template.")
	endif()
	
	_retrieve_instance_data(${__INSTANCE_ID} LANGUAGES __LANGUAGES)
#	message(STATUS "_gather_languages(): __LANGUAGES: ${__LANGUAGES}")
	if(__LANGUAGES)
		_retrieve_instance_data(${__INSTANCE_ID} F_PATH __PATH)
		_make_path_hash("${__PATH}" __KEY)
		_add_property_to_db(GLOBAL ALL ALL_LANGUAGES "${__LANGUAGES}")
	endif()
	_retrieve_instance_data(${__INSTANCE_ID} DEP_INSTANCES __DEP_IDS)
	if(__DEP_IDS)
		foreach(__DEP_ID IN LISTS __DEP_IDS)
			_gather_language_rec(${__DEP_ID})
		endforeach()
	endif()
endfunction()

function(_resolve_features_for_featurebase __FEATUREBASE_ID __OUT_SUCCESS)
	_get_list_of_instances_that_need_to_be_resolved(${__FEATUREBASE_ID} __FEATURE_INSTANCES)
	_get_promises_by_featurebase(${__FEATUREBASE_ID} __PROMISES)
#		message(STATUS "_resolve_features_for_featurebase(): __PROMISES: ${__PROMISES}")
	list(APPEND __FEATURE_INSTANCES ${__PROMISES})
	
	list(LENGTH __FEATURE_INSTANCES __INSTANCES_COUNT)
	if(${__INSTANCES_COUNT} EQUAL 0)
		break()
	endif()
#		if(${__INSTANCES_COUNT} EQUAL 1)
#			#Only one featurebase - there is little to do. 
#			_remove_property_from_db(GLOBAL ALL FEATUREBASES ${__FEATUREBASE_ID} )
#			continue()
#		endif()
	_retrieve_featurebase_args(${__FEATUREBASE_ID} F_FEATURES __BASE_ARGS)
	_calculate_hash(__BASE_ARGS "${__BASE_ARGS__LIST}" "" __BASE_HASH __BASE_HASH_SOURCE)
	_retrieve_featurebase_data(${__FEATUREBASE_ID} F_PATH __TARGETS_CMAKE_PATH)
	_make_path_hash("${__TARGETS_CMAKE_PATH}" __FILE_HASH)
	_retrieve_featurebase_data(${__FEATUREBASE_ID} PARS __SERIALIZED_PARS__LIST)
	_unserialize_parameters(__SERIALIZED_PARS __PARS)
	
#	message("__________________________________________________")
#	message(STATUS "_resolve_features_for_featurebase(): attempting to resolve featurebase ${__FEATUREBASE_ID}. All __FEATURE_INSTANCES: ${__FEATURE_INSTANCES}. ")
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
		_make_promoted_featureset("${__FILE_HASH}" "${__VARNAMES}" __PARS __BASE_ARGS __I_ARGS __COMMON_ARGS __OUT_RELATION)

		_serialize_variables(__COMMON_ARGS "${__COMMON_ARGS__LIST}" __SERIALIZED_COMMON_ARGS__LIST)
#			message(STATUS "_resolve_features_for_featurebase(): __INSTANCE_ID: ${__INSTANCE_ID} __VARNAMES: ${__VARNAMES} __SERIALIZED_COMMON_ARGS__LIST: ${__SERIALIZED_COMMON_ARGS__LIST}. __OUT_RELATION: ${__OUT_RELATION}")
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
			_serialize_variables(__I_ARGS "${__I_ARGS__LIST}" __SERIALIZED_I_ARGS)
			message(FATAL_ERROR "Cannot promote ${__INSTANCE_ID} into a common featurebase, because of the arguments ${__SERIALIZED_COMMON_ARGS__LIST} are not compatible with the requested ${__SERIALIZED_I_ARGS}. While sometimes this rare condition could be in theory fixed automatically by requesting two different copies of the featurebase, it is not supported by the beetroot. The simplest solution is to change the arguments from FEATURES into a TARGET_PARAMETERS.")
		else()
			message(FATAL_ERROR "Internal Beetroot error: unknown __OUT_RELATION ${__OUT_RELATION} returned from _make_promoted_featureset()")
		endif()
		_debug_show_instance(${__INSTANCE_ID} 2 "BEFORE PROMOTION: " __MSG __ERRORS)
#			message(STATUS "_resolve_features_for_featurebase(): Before promotion:\nx x x x x x x x x x x\n${__MSG}")
		if(__ERRORS)
			message(FATAL_ERROR ${__ERRORS})
		endif()			
	endforeach()
	_calculate_hash(__BASE_ARGS "${__BASE_ARGS__LIST}" "" __BASE_HASH __BASE_HASH_SOURCE)
	_serialize_variables(__BASE_ARGS "${__BASE_ARGS__LIST}" __SERIALIZED_COMMON_ARGS__LIST)
	_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} F_FEATURES "${__SERIALIZED_COMMON_ARGS__LIST}" FORCE)
	_retrieve_featurebase_data(${__FEATUREBASE_ID} MODIFIERS __SERIALIZED_MODIFIERS)
#		message(STATUS "_resolve_features_for_featurebase(): - - - - - - - - - - - -")
#		message(STATUS "_resolve_features_for_featurebase(): Starting promotions for __FEATURE_INSTANCES: ${__FEATURE_INSTANCES} __SERIALIZED_MODIFIERS: ${__SERIALIZED_MODIFIERS}")

	#Now we know what is the biggest set of features. We can now proceed with triggering promotions
	foreach(__INSTANCE_ID IN LISTS __FEATURE_INSTANCES)
#			message(STATUS "_resolve_features_for_featurebase(): Trying to promote ${__INSTANCE_ID}")
		_retrieve_instance_args(${__INSTANCE_ID} I_FEATURES __I_ARGS)
		_retrieve_instance_data(${__INSTANCE_ID} IS_PROMISE __IS_PROMISE)
		_calculate_hash(__I_ARGS "${__I_ARGS__LIST}" "" __I_HASH __I_HASH_SOURCE)
		
		if(NOT "${__I_HASH}" STREQUAL "${__BASE_HASH}" OR __IS_PROMISE)
#				message(STATUS "_resolve_features_for_featurebase(): About to promote ${__INSTANCE_ID} ${__FEATUREBASE_ID} \"${__SERIALIZED_COMMON_ARGS__LIST}\"")
			_promote_instance(${__INSTANCE_ID} ${__FEATUREBASE_ID} __SERIALIZED_COMMON_ARGS __NEW_INSTANCE_ID)
		else()
			set(__NEW_INSTANCE_ID ${__INSTANCE_ID})
		endif()


	endforeach()
	if(NOT __MODIFIED)
		set(__OUT_SUCCESS 1 PARENT_SCOPE)
	else()
		set(__OUT_SUCCESS 0 PARENT_SCOPE)
	endif()
endfunction()

function(_resolve_features)
	#First we need to make sure all instances that connect to the same featurebase agree in their feature lists
	_retrieve_global_data(FEATUREBASES __ALL_FEATUREBASES)
#	message(STATUS "_resolve_features(): All featurebases to resolve: ${__ALL_FEATUREBASES}")
	while(NOT "${__ALL_FEATUREBASES}" STREQUAL "") 
		list(GET __ALL_FEATUREBASES 0 __FEATUREBASE_ID)
		_resolve_features_for_featurebase(${__FEATUREBASE_ID} __SUCCESS)
		if(NOT __SUCCESS)
#			message(STATUS "_resolve_features(): removing __FEATUREBASE_ID: ${__FEATUREBASE_ID} from __GLOBAL_ALL_FEATUREBASES")
			_remove_property_from_db(GLOBAL ALL FEATUREBASES ${__FEATUREBASE_ID} )
		else()
			_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} F_FEATURES "${__SERIALIZED_COMMON_ARGS__LIST}" FORCE)
			_set_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} COMPAT_INSTANCES "${__FEATURE_INSTANCES}" FORCE)
		endif()
		
		_retrieve_global_data(FEATUREBASES __ALL_FEATUREBASES)
#		message(STATUS "_resolve_features(): next iteration __ALL_FEATUREBASES: ${__ALL_FEATUREBASES}")
	endwhile()
endfunction()

function(_get_list_of_instances_that_need_to_be_resolved __FEATUREBASE_ID __OUT_INSTANCES )
	_retrieve_featurebase_data(${__FEATUREBASE_ID} COMPAT_INSTANCES __COMPAT_INSTANCES)
	_retrieve_featurebase_data(${__FEATUREBASE_ID} F_INSTANCES __ALL_INSTANCES)
#	message(STATUS "_get_list_of_instances_that_need_to_be_resolved(): __COMPAT_INSTANCES: ${__COMPAT_INSTANCES} __ALL_INSTANCES: ${__ALL_INSTANCES}")
	list_diff(__OUT __ALL_INSTANCES __COMPAT_INSTANCES)
	set(${__OUT_INSTANCES} ${__OUT} PARENT_SCOPE)
endfunction()

#Promotes features on an INSTANCE_ID to the features of the given featurebase.
function(_promote_instance __INSTANCE_ID __FEATUREBASE_ID __SERIALIZED_COMMON_FEATURES__REF __OUT_NEW_INSTANCE_ID)
#	message(STATUS "_promote_instance(): Promoting __INSTANCE_ID: ${__INSTANCE_ID} to be compatible with featurebase ${__FEATUREBASE_ID} and features ${${__SERIALIZED_COMMON_FEATURES__REF}__LIST}")
	_debug_show_instance(${__INSTANCE_ID} 2 "BEFORE_PROMOTION: " __MSG __ERRORS)
#	message(STATUS "_promote_instance(): After promotion:\nx x x x x x x x x x x\n${__MSG}")
	if(__ERRORS)
		message(STATUS "Error in instance after promotion:\n${__MSG}")
		message(FATAL_ERROR ${__ERRORS})
	endif()

	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} I_FEATURES "${${__SERIALIZED_COMMON_FEATURES__REF}__LIST}" FORCE)
#	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} FEATUREBASE "${__FEATUREBASE_ID}")
	_retrieve_instance_data(${__INSTANCE_ID} IS_PROMISE __IS_PROMISE)
	if(__IS_PROMISE)
		#We need to tell the promise what is the matched featurebase. Then we proceed with rediscover normally, because the featureset is already initialized
		_unvirtualize_instance(${__INSTANCE_ID} ${__FEATUREBASE_ID})
	else()
		_retrieve_instance_data(${__INSTANCE_ID} FEATUREBASE __OLD_FEATUREBASE_ID)
		if(NOT "${__OLD_FEATUREBASE_ID}" STREQUAL "${__FEATUREBASE_ID}")
			message(FATAL_ERROR "Internal beetroot error: Promotion wants to change featurebase from ${__OLD_FEATUREBASE_ID} to ${__FEATUREBASE_ID}")
		endif()
	endif()
	_add_property_to_db(FEATUREBASEDB ${__FEATUREBASE_ID} COMPAT_INSTANCES ${__INSTANCE_ID})
#	message(STATUS "_promote_instance(): ${__SERIALIZED_COMMON_FEATURES__REF}__LIST: ${${__SERIALIZED_COMMON_FEATURES__REF}__LIST}")
#	message(STATUS "_move_instance(): moving ${__INSTANCE_ID} -> ${__NEW_INSTANCE_ID}")
	set(__NEW_INSTANCE_ID)
#	message(STATUS "_promote_instance(): _rediscover_dependencies(${__INSTANCE_ID} ${__SERIALIZED_COMMON_FEATURES__REF} __NEW_INSTANCE_ID)")
	_rediscover_dependencies(${__INSTANCE_ID} ${__SERIALIZED_COMMON_FEATURES__REF} __NEW_INSTANCE_ID)
	
	_retrieve_featurebase_data(${__FEATUREBASE_ID} F_FEATURES __SERIALIZED_FEATURES)
#	message(STATUS "_promote_instance(): __FEATUREBASE_ID: ${__FEATUREBASE_ID} __SERIALIZED_FEATURES: ${__SERIALIZED_FEATURES}")
#	message(STATUS "_promote_instance(): moving ${__INSTANCE_ID} -> ${__NEW_INSTANCE_ID}")
#	_move_instance(${__INSTANCE_ID} ${__NEW_INSTANCE_ID} )
	_debug_show_instance(${__NEW_INSTANCE_ID} 3 "AFTER_PROMOTION: " __MSG __ERRORS)
#	message(STATUS "_promote_instance(): After promotion:\nx x x x x x x x x x x\n${__MSG}")
	if(__ERRORS)
		message(STATUS "Error in instance efter promotion:\n${__MSG}")
		message(FATAL_ERROR "${__ERRORS}")
	endif()
#	message(FATAL_ERROR "!!!!")
	
	set(${__OUT_NEW_INSTANCE_ID} ${__NEW_INSTANCE_ID} PARENT_SCOPE )
endfunction()

function(_change_instance_id __OLD_INSTANCE_ID __NEW_INSTANCE_ID)
#	_debug_show_instance(${__OLD_INSTANCE_ID} 2 "  " __STR __ERROR)
#	if(__ERROR)
#		message(FATAL_ERROR "${__ERROR}")
#	endif()
#	message(STATUS "_change_instance_id(): __OLD_INSTANCE_ID: ${__OLD_INSTANCE_ID} __NEW_INSTANCE_ID: ${__NEW_INSTANCE_ID}")
#	message(STATUS "_change_instance_id(): ${__STR}")
	#1. For each parent, change its dependency and parent
	_retrieve_instance_data(${__OLD_INSTANCE_ID} I_PARENTS __PARENTS)
	foreach(__PARENT_ID IN LISTS __PARENTS)
		_retrieve_instance_data(${__PARENT_ID} FEATUREBASE __PARENT_FEATUREBASE)
		if(NOT __PARENT_FEATUREBASE)
			message(FATAL_ERROR "Internal beetroot consistency error: Parent does contain a link to the featurebase.")
		endif()
		_remove_property_from_db(FEATUREBASEDB ${__PARENT_FEATUREBASE} DEP_INSTANCES ${__OLD_INSTANCE_ID})
		_add_property_to_db(FEATUREBASEDB ${__PARENT_FEATUREBASE} DEP_INSTANCES ${__NEW_INSTANCE_ID})
		_add_property_to_db(INSTANCEDB ${__NEW_INSTANCE_ID} I_PARENTS ${__PARENT_ID})
	endforeach()
	
	#2. Change TEMPLATEDB
	_retrieve_instance_data(${__OLD_INSTANCE_ID} VIRTUAL_INSTANCES __PROMISES)
	_retrieve_instance_data(${__OLD_INSTANCE_ID} I_TEMPLATE_NAME __TEMPLATE_NAME)
	_retrieve_instance_data(${__OLD_INSTANCE_ID} IS_PROMISE __IS_PROMISE)
	_retrieve_instance_data(${__NEW_INSTANCE_ID} IS_PROMISE __NEW_IS_PROMISE)
	if(__IS_PROMISE)
		message(FATAL_ERROR "Internal beetroot error: There should be no need to change id of a promise")
		_remove_property_from_db(TEMPLATEDB ${__TEMPLATE_NAME} VIRTUAL_INSTANCES ${__OLD_INSTANCE_ID})
	else()
		if(__NEW_IS_PROMISE)
			_remove_property_from_db(TEMPLATEDB ${__TEMPLATE_NAME} VIRTUAL_INSTANCES ${__NEW_INSTANCE_ID})
		endif()
	endif()
	_retrieve_instance_data(${__NEW_INSTANCE_ID} IS_PROMISE __IS_PROMISE)
	if(__IS_PROMISE)
		message(FATAL_ERROR "Internal beetroot error: There should be no need to change id of a promise")
		_add_property_to_db(TEMPLATEDB ${__TEMPLATE_NAME} VIRTUAL_INSTANCES ${__NEW_INSTANCE_ID})
	endif()
	
	
	
	#3. Change __GLOBAL_ALL_INSTANCES
	_retrieve_global_data(INSTANCES __ALL_INSTANCES)
	if(${__OLD_INSTANCE_ID} IN_LIST __ALL_INSTANCES)
		_remove_property_from_db(GLOBAL ALL INSTANCES ${__OLD_INSTANCE_ID})
		_add_property_to_db(GLOBAL ALL INSTANCES ${__NEW_INSTANCE_ID})
	endif()
	
endfunction()

#Gets all templates that are compatible with the given instance. May be more than one if JOINED_TARGETS.
function(_get_templates_by_featurebase __FEATUREBASE_ID __OUT_TEMPLATES)
	set(__OUT)
	set(__FEATUREBASES)
	_retrieve_featurebase_data(${__FEATUREBASE_ID} F_PATH __TARGETS_CMAKE_PATH)
	_make_path_hash("${__TARGETS_CMAKE_PATH}" __FILE_HASH)
	_retrieve_file_data("${__FILE_HASH}" JOINT_TARGETS __JOINT_TARGETS)
	if(__JOINT_TARGETS)
		_retrieve_file_data("${__FILE_HASH}" G_TEMPLATES __TEMPLATES)
#		message(STATUS "_get_templates_by_featurebase(): JOINT_TARGETS. __FEATUREBASE_ID: ${__FEATUREBASE_ID} __TEMPLATES: ${__TEMPLATES}")
	else()
		set(__TEMPLATES)
		_retrieve_featurebase_data(${__FEATUREBASE_ID} F_INSTANCES __ALL_INSTANCES)
#		message(STATUS "_get_templates_by_featurebase(): NORMAL TARGETS. __FEATUREBASE_ID: ${__FEATUREBASE_ID} __ALL_INSTANCES: ${__ALL_INSTANCES}")
		foreach(__INSTANCE_ID IN LISTS __ALL_INSTANCES)
			_retrieve_instance_data(${__INSTANCE_ID} I_TEMPLATE_NAME __TEMPLATE_NAME)
#			message(STATUS "_get_templates_by_featurebase(): appending ${__TEMPLATE_NAME} to __TEMPLATES for __FEATUREBASE_ID: ${__FEATUREBASE_ID}")
			list(APPEND __TEMPLATES ${__TEMPLATE_NAME})
		endforeach()
		if(__TEMPLATES)
			list(REMOVE_DUPLICATES __TEMPLATES)
		endif()
	endif()
#	message(STATUS "_get_templates_by_featurebase() __TEMPLATES: ${__TEMPLATES}")
	set(${__OUT_TEMPLATES} "${__TEMPLATES}" PARENT_SCOPE)
endfunction()

function(_get_promises_by_featurebase __FEATUREBASE_ID __OUT_INSTANCES)
	set(__OUT)
	set(__FEATUREBASES)
	_get_templates_by_featurebase(${__FEATUREBASE_ID} __TEMPLATE_NAMES)
#	message(STATUS "_get_promises_by_featurebase(): Attempting to find all promises for __FEATUREBASE_ID: ${__FEATUREBASE_ID}. __TEMPLATE_NAMES: ${__TEMPLATE_NAMES}")
	if("${__TEMPLATE_NAMES}" STREQUAL "")
		message(FATAL_ERROR "Cannot get list of templates from the featurebase.")
	endif()
	#There may be more than one template associated with the given featurebase if targets are joined, and each template may have its own promises.
	foreach(__TEMPLATE_NAME IN LISTS __TEMPLATE_NAMES)
		_retrieve_template_data(${__TEMPLATE_NAME} VIRTUAL_INSTANCES __INSTANCES)
#		message(STATUS "_get_promises_by_featurebase(): For __TEMPLATE_NAME: ${__TEMPLATE_NAME} found the following promises __INSTANCES: ${__INSTANCES}")
		list(APPEND __OUT ${__INSTANCES})
		_retrieve_template_data(${__TEMPLATE_NAME} TEMPLATE_FEATUREBASES __T_FEATUREBASES)
		list(APPEND __FEATUREBASES ${__T_FEATUREBASES})
	endforeach()
	if(__FEATUREBASES)
		list(REMOVE_DUPLICATES __FEATUREBASES)
	endif()
#	message(STATUS "_get_promises_by_featurebase(): all found promise instances: ${__OUT} for templates ${__TEMPLATE_NAMES}")
	if(__OUT)
		list(REMOVE_DUPLICATES __OUT)
		foreach(__INSTANCE_ID IN LISTS __OUT)
			_retrieve_instance_data(${__INSTANCE_ID} IS_PROMISE __IS_PROMISE)
			if(NOT "${__IS_PROMISE}" STREQUAL "1")
				message(FATAL_ERROR "Internal beetroot error: consitency problem: ${__INSTANCE_ID} should be promise, but it isn't.")
			endif()
		endforeach()
		list(LENGTH __FEATUREBASES __FEATUREBASES_COUNT)
		if(${__FEATUREBASES_COUNT} GREATER 1)
			list(LENGTH __TEMPLATE_NAMES __TEMPLATE_COUNT)
			set(__FEATURES_TXT)
			foreach(__FEATUREBASE IN LISTS __FEATUREBASES)
				_debug_show_featurebase(${__FEATUREBASE} 2 "   " __FEATURE_TXT __ERROR)
				if(__ERROR)
					message(FATAL_ERROR "${__ERROR}")
				endif()
				set(__FEATURES_TXT "${__FEATURES_TXT}\n${__FEATURE_TXT}")
			endforeach()
			#TODO: To the error messages below perhaps I should list the parameters of all those instances (and maybe even the place it is requested?)
			if(${__TEMPLATE_COUNT} GREATER 1)
				nice_list_output(OUTVAR __NICE_LIST LIST ${__TEMPLATE_NAMES} )
				message(FATAL_ERROR "Cannot use get_existing_target() on templates ${__NICE_LIST}, because all those templates share an implementation and there is already more than one of it already requested, so the Beetroot does not know, which one to use. List of the conflicting feature bases: \n ${__FEATURES_TXT}")
			else()
				message(FATAL_ERROR "Cannot use get_existing_target() on template ${__TEMPLATE_NAMES} because more than one instance of it is already requested, and the Beetroot does not know which one to use. List of the conflicting feature bases: \n ${__FEATURES_TXT}")
			endif()
		endif()
	endif()
	set(${__OUT_INSTANCES} ${__OUT} PARENT_SCOPE)
endfunction()
