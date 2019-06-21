set(ENUM_TARGETS GridTools::gridtools)

if(GRIDTOOLS_USE_GPU)
	set(NOT_GRIDTOOLS_USE_GPU 0)
	set(GRIDTOOLS_USE_GPU 1)
else()
	set(NOT_GRIDTOOLS_USE_GPU 1)
	set(GRIDTOOLS_USE_GPU 0)
endif()

set(TARGET_PARAMETERS
	GRIDTOOLS_USE_GPU	OPTION	BOOL	0
	GT_ENABLE_TARGET_CUDA	OPTION	BOOL	"${GRIDTOOLS_USE_GPU}"
	GT_ENABLE_TARGET_X86	OPTION	BOOL	"${NOT_GRIDTOOLS_USE_GPU}"
	GT_ENABLE_PERFORMANCE_METERS	OPTION	BOOL	0
	FLOAT_PRECISION	SCALAR	"CHOICE(4:8)"	4
	GT_SINGLE_PRECISION	SCALAR	BOOL	0
)

set(TARGET_FEATURES
	BUILD_GMOCK	SCALAR	BOOL	0
	BUILD_TESTING	SCALAR	BOOL	0
	GT_INSTALL_EXAMPLES	SCALAR	BOOL	0
)

set(LINK_PARAMETERS 
	VERBOSE_MESSAGES	OPTION	BOOL	0
	GRIDTOOLS_ICOSAHEDRAL_GRIDS	OPTION	BOOL	0
	GRIDTOOLS_DYCORE_BLOCKING	OPTION	BOOL	0
	GRIDTOOLS_OPENMP	OPTION	BOOL	0
	GT_GCL_ONLY	OPTION	BOOL	1
)

if(GT_ENABLE_TARGET_CUDA)
	set(CUDA_LANG "CUDA")
else()
	set(CUDA_LANG "")
endif()

set(DEFINE_EXTERNAL_PROJECT 
	NAME GridTools
	SOURCE_PATH "${SUPERBUILD_ROOT}/gridtools"
	WHAT_COMPONENTS_NAME_DEPENDS_ON boost;compiler;cuda;gridtools
	EXPORTED_TARGETS_PATH lib/cmake
)

set(TEMPLATE_OPTIONS
	SINGLETON_TARGETS
	LANGUAGES ${CUDA_LANG} CXX
	LINK_TO_DEPENDEE
)

function(generate_targets)
	message(STATUS "generate_targets() should throw an error here")
endfunction()

function(apply_dependency_to_target DEPENDEE_TARGET_NAME TARGET_NAME)
#	if(NOT GT_ENABLE_TARGET_X86)
#		message(FATAL_ERROR "No support for CPU")
#	endif()
#	message("gridtools.cmake: setting FLOAT_PRECISION=${FLOAT_PRECISION}  for TARGET_NAME ${DEPENDEE_TARGET_NAME} #####")
	target_compile_definitions(${DEPENDEE_TARGET_NAME} ${KEYWORD} "FLOAT_PRECISION=${FLOAT_PRECISION}")
endfunction()
