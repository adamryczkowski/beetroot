include(CheckLanguage)
check_language(CUDA)
if(CMAKE_CUDA_COMPILER)
	set(CUDA_VERSION_STRING "CUDA${CMAKE_CUDA_COMPILER_VERSION}")
else()
	set(CUDA_VERSION_STRING "noCUDA")
endif()