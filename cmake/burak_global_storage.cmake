#     Global variables:
#
#
# __INSTANCEDB_<INSTANCE_ID>_VARS          - Serialized list of variables with their values that are passed to that instance
# __INSTANCEDB_<INSTANCE_ID>_DEPS          - List of dependencies id of that instance
# __INSTANCEDB_<INSTANCE_ID>_INSTANCE_NAME - Assigned name of the target. Applies only for those instances that produce targets. Instances get target name only in second phase (DEFINING_TARGETS)
# __INSTANCEDB_<INSTANCE_ID>_TEMPLATE      - Base template name. Can be used for lookup in templatedb
#
# __TEMPLATEDB_<TEMPLATE_NAME>_PATH               - Path to the file that defines this template. Can be used as a key to the FILEDB database
# __TEMPLATEDB_<TEMPLATE_NAME>_INSTANCES          - List of all instance ids of the template
# __TEMPLATEDB_<TEMPLATE_NAME>_MODIFIERS_HASHES   - List of all unique hashes of modifiers. Used to get the number of unique targets for each template.
# __TEMPLATEDB_<TEMPLATE_NAME>_TEMPLATE_INSTANCES - List of all unique instances gathered for this template.
# 
# __TARGETDB_<MODIFIERS_HASH>_TARGET_INSTANCES  - List of all instances that point to this target
# __TARGETDB_<MODIFIERS_HASH>_TARGET_TEMPLATE   - Template of this target
# __TARGETDB_<MODIFIERS_HASH>_FEATURES          - Serialized values of features of this target
#
# __FILEDB_<PATH_HASH>_PATH           - Path to the file that defines this template
# __FILEDB_<PATH_HASH>_TARGET_FIXED   - Boolean. True means that there is only on target name for this template
# __FILEDB_<PATH_HASH>_PARS           - Serialized list of definitions of variables (without their default values)
# __FILEDB_<PATH_HASH>_MODIFIERS      - Variable list that are defining the target name
# __FILEDB_<PATH_HASH>_INSTANCES      - List of all instance ids of the template
# __FILEDB_<PATH_HASH>_EXTERNAL_INFO  - Serialized external project info
# __FILEDB_<PATH_HASH>_REQUIRED       - True means that we require this instance to generate a CMake target
# __FILEDB_<PATH_HASH>_OPTIONS        - Global options string (parsable)
# __FILEDB_<PATH_HASH>_FILE_INSTANCES - List of all unique instances gathered for this file targets.cmake
# 
# __BURAK_ALL_INSTANCES - list of all instance ID that are required by the top level

macro(_get_db_columns __COLS)
	set(${__COLS}_VARS               INSTANCEDB )
	set(${__COLS}_DEPS               INSTANCEDB )
	set(${__COLS}_TEMPLATE           INSTANCEDB )
	set(${__COLS}_INSTANCE_NAME      INSTANCEDB )
	set(${__COLS}_TARGET_INSTANCES   TARGETDB )
	set(${__COLS}_TARGET_TEMPLATE    TARGETDB )
	set(${__COLS}_FEATURES           TARGETDB )
	set(${__COLS}_PATH               TEMPLATEDB )
	set(${__COLS}_MODIFIERS_HASHES   TEMPLATEDB )
	set(${__COLS}_TEMPLATE_INSTANCES TEMPLATEDB )
	set(${__COLS}_TARGET_FIXED       FILEDB )
	set(${__COLS}_PARS               FILEDB )
	set(${__COLS}_MODIFIERS          FILEDB )
	set(${__COLS}_FEATURES           FILEDB )
	set(${__COLS}_EXTERNAL_INFO      FILEDB )
	set(${__COLS}_REQUIRED           FILEDB )
	set(${__COLS}_OPTIONS            FILEDB )
	set(${__COLS}_FILE_INSTANCES     FILEDB )
endmacro()

function(_make_path_hash __TARGETS_CMAKE_PATH __OUT_HASH)
	if(NOT __TARGETS_CMAKE_PATH)
		message(FATAL_ERROR "Internal Beetroot error: __TARGETS_CMAKE_PATH should not be empty")
	endif()
	string(MD5 __TMP ${__TARGETS_CMAKE_PATH})
	string(SUBSTRING ${__TMP} 1 6 __TMP)
	set(${__OUT_HASH} ${__TMP} PARENT_SCOPE)
endfunction()

function(_make_modifiers_hash __SERIALIZED_MODIFIERS __TARGET_TEMPLATE __OUT_HASH)
	if(NOT __SERIALIZED_MODIFIERS)
		message(FATAL_ERROR "Internal Beetroot error: __SERIALIZED_MODIFIERS should not be empty")
	endif()
	set(__TMP "${__TARGET_TEMPLATE}|${__SERIALIZED_MODIFIERS}")
	string(MD5 __TMP ${__TMP})
	string(SUBSTRING ${__TMP} 1 8 __TMP)
	set(${__OUT_HASH} ${__TMP} PARENT_SCOPE)
endfunction()

function(_store_instance_data __INSTANCE_ID __ARGS __PARS __ARGS_LIST_MODIFIERS __ARGS_LIST_FEATURES __DEP_LIST __TEMPLATE_NAME __TARGETS_CMAKE_PATH __IS_TARGET_FIXED __EXTERNAL_PROJECT_INFO __TARGET_REQUIRED __TEMPLATE_OPTIONS)
#	message(FATAL_ERROR "__ARGS_LIST_MODIFIERS: ${__ARGS_LIST_MODIFIERS}")
#	if("${__INSTANCE_ID}" STREQUAL "SerialboxStatic_18768807d4b4034c1c5d4dd0f5ba6964")
#		message(FATAL_ERROR "__EXTERNAL_PROJECT_INFO: ${__EXTERNAL_PROJECT_INFO}")
#	endif()
	_serialize_variables(${__ARGS} "${${__ARGS}__LIST}" __SERIALIZED_VARIABLES)
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} VARS                  "${__SERIALIZED_VARIABLES}")
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} TEMPLATE              "${__TEMPLATE_NAME}")
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} DEPS                  "${__DEP_LIST}")
	
	_serialize_variables(${__ARGS} "${${__ARGS}__LIST_FEATURES}" __SERIALIZED_FEATURES)
	_make_modifiers_hash(__SERIALIZED_FEATURES ${__TEMPLATE_NAME} __FEATURE_HASH)
	_add_property_to_db(TARGETDB ${__FEATURE_HASH} TARGET_INSTANCES       "${__INSTANCE_ID}")
	_set_property_to_db(TARGETDB ${__FEATURE_HASH} TARGET_TEMPLATE        "${__TEMPLATE_NAME}")
	_set_property_to_db(TARGETDB ${__FEATURE_HASH} FEATURES               "${__SERIALIZED_FEATURES}")
	
	_calculate_hash(${__ARGS} "${__ARGS_LIST_MODIFIERS}" "" __MODIFIERS_HASH)
#	message(STATUS "_store_instance_data(): __INSTANCE_ID: ${__INSTANCE_ID} got __MODIFIERS_HASH ${__MODIFIERS_HASH} based on __ARGS_LIST_MODIFIERS ${__ARGS_LIST_MODIFIERS}")
	_set_property_to_db(TEMPLATEDB ${__TEMPLATE_NAME} PATH                "${__TARGETS_CMAKE_PATH}")
	_add_property_to_db(TEMPLATEDB ${__TEMPLATE_NAME} MODIFIERS_HASHES    "${__MODIFIERS_HASH}")
	_add_property_to_db(TEMPLATEDB ${__TEMPLATE_NAME} TEMPLATE_INSTANCES  "${__INSTANCE_ID}")

	_make_path_hash(${__TARGETS_CMAKE_PATH} __PATH_HASH)
	_serialize_parameters(${__PARS} __SERIALIZED_PARAMETERS)
	_set_property_to_db(FILEDB     ${__PATH_HASH} PATH                 "${__TARGETS_CMAKE_PATH}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} TARGET_FIXED         "${__IS_TARGET_FIXED}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} PARS                 "${__SERIALIZED_PARAMETERS}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} MODIFIERS            "${__ARGS_LIST_MODIFIERS}")
	_add_property_to_db(FILEDB     ${__PATH_HASH} FILE_INSTANCES       "${__INSTANCE_ID}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} EXTERNAL_INFO        "${__EXTERNAL_PROJECT_INFO}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} REQUIRED             "${__TARGET_REQUIRED}")
	_set_property_to_db(FILEDB     ${__PATH_HASH} OPTIONS              "${__TEMPLATE_OPTIONS}")

	_get_stack_depth(__STACK_DEPTH)
	if("${__STACK_DEPTH}" STREQUAL "0")
#		message(STATUS "_store_instance_data(): ADDING GLOBAL INSTANCE: ${__INSTANCE_ID}")
		_add_property_to_db(BURAK ALL INSTANCES "${__INSTANCE_ID}")
	endif()
	
#	_append_instance_modifiers_hash(${__INSTANCE_ID} ${__TEMPLATE_NAME} ${__ARGS} "${__ARGS_LIST_MODIFIERS}")
endfunction()

function(_store_target_modification_data __INSTANCE_ID __ARGS __TEMPLATE_NAME)
	_serialize_variables(${__ARGS} "${${__ARGS}__LIST}" __SERIALIZED_VARIABLES)
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} VARS               "${__SERIALIZED_VARIABLES}")
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} TEMPLATE           "${__TEMPLATE_NAME}")
	_add_property_to_db(BURAK ALL MODIFICATIONS "${__INSTANCE_ID}")
endfunction()

function(_add_property_to_db __DB_NAME __KEY __PROPERTY_NAME __ITEM )
	get_property(__ITEMS GLOBAL PROPERTY __${__DB_NAME}_${__KEY}_${__PROPERTY_NAME})
	if(NOT ${__ITEM} IN_LIST __ITEMS)
		set_property(GLOBAL APPEND PROPERTY __${__DB_NAME}_${__KEY}_${__PROPERTY_NAME} "${__ITEM}")
	endif()
endfunction()

function(_set_property_to_db __DB_NAME __KEY __PROPERTY_NAME __PROPERTY_VALUE )
	get_property(__TMP GLOBAL PROPERTY __${__DB_NAME}_${__KEY}_${__PROPERTY_NAME})
	if(__TMP)
		if(NOT "${__TMP}" STREQUAL "${__PROPERTY_VALUE}")
			message(FATAL_ERROR "Internal beetroot error. Trying to re-write __${__DB_NAME}_${__KEY}_${__PROPERTY_NAME} with a new value \"${__PROPERTY_VALUE}\" that is different from the old value \"${__TMP}\".")
		endif()
	else()
		set_property(GLOBAL PROPERTY __${__DB_NAME}_${__KEY}_${__PROPERTY_NAME} "${__PROPERTY_VALUE}")
	endif()
endfunction()


##Storage allows for quick enumaration of number of distinct ARG_MODIFIERS hashes for each TEMPLATE_NAME,
##so the function that names the targets can easily decide on the best naming scheme.
##
##For each TEMPLATE_NAME there is a global list of modifier_hashes:
##__${TEMPLATE_NAME}_MODIFIER_HASHES
#function(_append_instance_modifiers_hash __INSTANCE_ID __TEMPLATE_NAME __ARGS __ARGS_LIST_MODIFIERS)
#	_calculate_hash("${__ARGS}" "${__ARGS_LIST_MODIFIERS}" "${__TEMPLATE_NAME}" __HASH_TEMPLATE_NAME)
#	get_property(__MODIFIERS_HASHES GLOBAL PROPERTY __${__TEMPLATE_NAME}_MODIFIER_HASHES)
#	if(__MODIFIERS_HASHES)
#		if("${__HASH_TEMPLATE_NAME}" IN_LIST __MODIFIERS_HASHES)
#			return()
#		endif()
#	endif()
#	set_property(GLOBAL APPEND PROPERTY __${__TEMPLATE_NAME}_MODIFIER_HASHES "${__HASH_TEMPLATE_NAME}")
#	set_property(GLOBAL APPEND PROPERTY __BURAK_ALL_INSTANCES "${__INSTANCE_ID}")
#	set_property(GLOBAL PROPERTY __${__INSTANCE_ID}_MODIFIERS_HASH 	"${__HASH_TEMPLATE_NAME}")    #Hash that defines the target name (INSTANCE_NAME)
#	get_property(__TMP GLOBAL PROPERTY __BURAK_ALL_INSTANCES)
##	message(STATUS "_append_instance_modifiers_hash(): Added ${__INSTANCE_ID} to all instances. Now the full list: ${__TMP}")
#endfunction()

function(_retrieve_instance_data __INSTANCE_ID __PROPERTY __OUT)
	_get_db_columns(__COLS)
	if(NOT __COLS_${__PROPERTY})
		message(FATAL_ERROR "Internal Beetroot error: Cannot find the property ${__PROPERTY}")
	endif()
	if("${__COLS_${__PROPERTY}}" STREQUAL "INSTANCEDB")
		set(__KEY "${__INSTANCE_ID}")
	elseif("${__COLS_${__PROPERTY}}" STREQUAL "TEMPLATEDB")
		_retrieve_instance_data(${__INSTANCE_ID} TEMPLATE __KEY)
	elseif("${__COLS_${__PROPERTY}}" STREQUAL "FILEDB")
		_retrieve_instance_data(${__INSTANCE_ID} PATH __PATH)
		_make_path_hash("${__PATH}" __KEY)
	else()
		message(FATAL_ERROR "Internal Beetroot error: Cannot find the database ${__COLS_${__PROPERTY}} indicated by variable __COLS_${__PROPERTY}")
	endif()
	get_property(__TMP GLOBAL PROPERTY __${__COLS_${__PROPERTY}}_${__KEY}_${__PROPERTY})
	set(${__OUT} "${__TMP}" PARENT_SCOPE)
endfunction()

function(_retrieve_template_data __TEMPLATE_NAME __PROPERTY __OUT)
	_get_db_columns(__COLS)
	if(NOT __COLS_${__PROPERTY})
		message(FATAL_ERROR "Internal Beetroot error: Cannot find the property ${__PROPERTY}")
	endif()
	if("${__COLS_${__PROPERTY}}" STREQUAL "INSTANCEDB")
		message(FATAL_ERROR "Internal error: Cannot retrieve instance column using template name")
	elseif("${__COLS_${__PROPERTY}}" STREQUAL "TEMPLATEDB")
		set(__KEY "${__TEMPLATE_NAME}")
	elseif("${__COLS_${__PROPERTY}}" STREQUAL "FILEDB")
		_retrieve_template_data(${__TEMPLATE_NAME} PATH __PATH)
		_make_path_hash("${__PATH}" __KEY)
	else()
		message(FATAL_ERROR "Internal Beetroot error: Cannot find the database ${__COLS_${__PROPERTY}} indicated by variable __COLS_${__PROPERTY}")
	endif()
	get_property(__TMP GLOBAL PROPERTY __${__COLS_${__PROPERTY}}_${__KEY}_${__PROPERTY})
	set(${__OUT} "${__TMP}" PARENT_SCOPE)
endfunction()

macro(_retrieve_instance_args __INSTANCE_ID __OUT)
	_retrieve_instance_data(${__INSTANCE_ID} VARS __TMP_SER_VARS)
	_unserialize_variables("${__TMP_SER_VARS}" ${__OUT})
endmacro()

macro(_retrieve_instance_pars __INSTANCE_ID __OUT)
	_retrieve_instance_data(${__INSTANCE_ID} PARS __TMP_SER_PARS)
	_unserialize_parameters("${__TMP_SER_PARS}" ${__OUT})
endmacro()

macro(_retrieve_all_instance_data __INSTANCE_ID 
 __OUT_ARGS __OUT_DEP_LIST __OUT_TEMPLATE_NAME __OUT_TARGETS_CMAKE_PATH __OUT_IS_TARGET_FIXED __OUT_EXTERNAL_PROJECT_INFO __OUT_TARGET_REQUIRED __OUT_TEMPLATE_OPTIONS)
	_retrieve_instance_args(${__INSTANCE_ID} ${__OUT_ARGS})
	_retrieve_instance_data(${__INSTANCE_ID} DEPS 			${__OUT_DEP_LIST})
	_retrieve_instance_data(${__INSTANCE_ID} TEMPLATE 		${__OUT_TEMPLATE_NAME})
	_retrieve_instance_data(${__INSTANCE_ID} PATH 			${__OUT_TARGETS_CMAKE_PATH})
	_retrieve_instance_data(${__INSTANCE_ID} TARGET_FIXED 	${__OUT_IS_TARGET_FIXED})
	_retrieve_instance_data(${__INSTANCE_ID} EXTERNAL_INFO 	${__OUT_EXTERNAL_PROJECT_INFO})
	_retrieve_instance_data(${__INSTANCE_ID} REQUIRED 		${__OUT_TARGET_REQUIRED})
	_retrieve_instance_data(${__INSTANCE_ID} OPTIONS 		${__OUT_TEMPLATE_OPTIONS})
endmacro()

function(_store_instance_target __INSTANCE_ID __INSTANCE_NAME) 
	_set_property_to_db(INSTANCEDB ${__INSTANCE_ID} INSTANCE_NAME "${__INSTANCE_NAME}")
endfunction()

macro(_get_all_instance_ids __OUT_INSTANCE_ID_LIST) 
	get_property("${__OUT_INSTANCE_ID_LIST}" GLOBAL PROPERTY __BURAK_ALL_INSTANCES)
endmacro()

macro(_get_all_instance_modifications __OUT_INSTANCE_ID_LIST)
	get_property("${__OUT_INSTANCE_ID_LIST}" GLOBAL PROPERTY __BURAK_ALL_MODIFICATIONS)
endmacro()

function(_get_number_of_instance_modifier_hashes __TEMPLATE_NAME __OUT_INSTANCE_COUNT)
	_retrieve_instance_data(${__INSTANCE_ID} MODIFIERS_HASHES __HASHES)
	list(LENGTH __HASHES __COUNT)
	set(${__OUT_INSTANCE_COUNT} "${__COUNT}" PARENT_SCOPE)
endfunction()

