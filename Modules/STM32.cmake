if ( STM32_TOOLCHAIN_FILE_INCLUDED )
	return ()
else ( STM32_TOOLCHAIN_FILE_INCLUDED )
	set ( STM32_TOOLCHAIN_FILE_INCLUDED true )
endif ( STM32_TOOLCHAIN_FILE_INCLUDED )

get_filename_component ( STM32_CMAKE_PATH ${CMAKE_CURRENT_LIST_FILE} DIRECTORY )
set ( CMAKE_MODULE_PATH ${STM32_CMAKE_PATH} ${CMAKE_MODULE_PATH} )
set ( STM32 ON )
include ( STM32/Util )

set ( CMAKE_C_FLAGS "" )
set ( CMAKE_CXX_FLAGS "" )
set ( CMAKE_ASM_FLAGS "" )
set ( CMAKE_EXE_LINKER_FLAGS "" )

if ( CMAKE_TOOLCHAIN_FILE )
	if ( DEFINED STM32_MODEL )
		string ( TOUPPER "${STM32_MODEL}" STM32_MODEL )
		set ( STM32_MODEL "${STM32_MODEL}" )
	else ()
		message ( FATAL_ERROR "Please use -DSTM32_MODEL to set the chip model." )
	endif ( DEFINED STM32_MODEL )

	string ( SUBSTRING ${STM32_MODEL} 5 2 STM32_SERIES )
	string ( TOLOWER "${STM32_SERIES}" STM32_SERIES_LOWERCASE )
	message ( STATUS "No STM32_SERIES specified, auto detect: " ${STM32_SERIES} )

	if ( NOT DEFINED TOOLCHAIN_PREFIX )
		set ( TOOLCHAIN_PREFIX "arm-none-eabi" )
		message ( STATUS "No TOOLCHAIN_PREFIX specified, using default: " ${TOOLCHAIN_PREFIX} )
	endif ()
endif ()

if ( WIN32 )
	set ( TOOL_EXECUTABLE_SUFFIX ".exe" )
else ( WIN32 )
	set ( TOOL_EXECUTABLE_SUFFIX "" )
endif ( WIN32 )

add_definitions ( -DSTM32 )

set ( CMAKE_SYSTEM_NAME Generic )
if ( CMAKE_TOOLCHAIN_FILE )
	if ( IS_DIRECTORY ${STM32_CMAKE_PATH}/STM32/${STM32_SERIES} )
		include ( STM32/${STM32_SERIES}/cmake )
	else ( IS_DIRECTORY ${STM32_CMAKE_PATH}/STM32/${STM32_SERIES} )
		message ( FATAL_ERROR "The ${STM32_SERIES} series not support." "You can write and send to me." )
	endif ( IS_DIRECTORY ${STM32_CMAKE_PATH}/STM32/${STM32_SERIES} )

	if ( ${STM32_CUSTOM_SYSCALL} )
		if ( NOT EXISTS ${PROJECT_SOURCE_DIR}/syscalls.c )
			configure_file ( ${STM32_CMAKE_PATH}/STM32/syscalls.c ${PROJECT_SOURCE_DIR}/syscalls.c COPYONLY )
			message ( STATUS "Copy ${STM32_CMAKE_PATH}/STM32/syscalls.c to your project, you can customize." )
		endif ()
		set ( STM32_SOURCE_FILES ${STM32_SOURCE_FILES} syscalls.c )
	endif ()

	if ( ${STM32_STDLIB} )
		stm32_add_flags ( CMAKE_EXE_LINKER_FLAGS "--specs=${STM32_STDLIB}.specs" )
	else ()
		stm32_add_flags ( CMAKE_EXE_LINKER_FLAGS "--specs=nosys.specs" )
	endif ()

endif ( CMAKE_TOOLCHAIN_FILE )

set ( CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY )

find_program ( CMAKE_C_COMPILER "${TOOLCHAIN_PREFIX}-gcc${TOOL_EXECUTABLE_SUFFIX}" )
find_program ( CMAKE_CXX_COMPILER "${TOOLCHAIN_PREFIX}-g++${TOOL_EXECUTABLE_SUFFIX}" )
find_program ( CMAKE_ASM_COMPILER "${TOOLCHAIN_PREFIX}-gcc${TOOL_EXECUTABLE_SUFFIX}" )
find_program ( CMAKE_OBJCOPY "${TOOLCHAIN_PREFIX}-objcopy${TOOL_EXECUTABLE_SUFFIX}" )
find_program ( CMAKE_OBJDUMP "${TOOLCHAIN_PREFIX}-objdump${TOOL_EXECUTABLE_SUFFIX}" )
find_program ( CMAKE_SIZE "${TOOLCHAIN_PREFIX}-size${TOOL_EXECUTABLE_SUFFIX}" )
find_program ( CMAKE_DEBUGER "${TOOLCHAIN_PREFIX}-gdb${TOOL_EXECUTABLE_SUFFIX}" )
find_program ( CMAKE_CPPFILT "${TOOLCHAIN_PREFIX}-c++filt${TOOL_EXECUTABLE_SUFFIX}" )

if ( CMAKE_TOOLCHAIN_FILE )
	if ( NOT CMAKE_FIND_ROOT_PATH )
		get_filename_component ( GCC_EXECUTABLE_LOCATION ${CMAKE_C_COMPILER} REALPATH )
		get_filename_component ( GCC_EXECUTABLE_LOCATION ${GCC_EXECUTABLE_LOCATION} PATH )
		get_filename_component ( GCC_LOCATION "${GCC_EXECUTABLE_LOCATION}" PATH )
		string ( APPEND SYSROOT_PATH "${GCC_LOCATION}" "/${TOOLCHAIN_PREFIX}" )
		message ( STATUS "Find sysroot path in ${SYSROOT_PATH}" )
		set ( CMAKE_FIND_ROOT_PATH "${SYSROOT_PATH}" )
	endif ( NOT CMAKE_FIND_ROOT_PATH )
	set ( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER )
	set ( CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY )
	set ( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY )
endif ( CMAKE_TOOLCHAIN_FILE )

function ( stm32_add_hex_target TARGET )
	if ( EXECUTABLE_OUTPUT_PATH )
		set ( FILENAME "${EXECUTABLE_OUTPUT_PATH}/${TARGET}" )
	else ()
		set ( FILENAME "${TARGET}" )
	endif ()
	add_custom_target ( ${TARGET}.hex DEPENDS ${TARGET} COMMAND ${CMAKE_OBJCOPY} -Obinary ${FILENAME} ${FILENAME}.hex )
endfunction ()

function ( stm32_add_bin_target TARGET )
	if ( EXECUTABLE_OUTPUT_PATH )
		set ( FILENAME "${EXECUTABLE_OUTPUT_PATH}/${TARGET}" )
	else ()
		set ( FILENAME "${TARGET}" )
	endif ()
	add_custom_target ( ${TARGET}.bin DEPENDS ${TARGET} COMMAND ${CMAKE_OBJCOPY} -Obinary ${FILENAME} ${FILENAME}.bin )
endfunction ()

function ( stm32_add_dump_target TARGET )
	if ( EXECUTABLE_OUTPUT_PATH )
		set ( FILENAME "${EXECUTABLE_OUTPUT_PATH}/${TARGET}" )
	else ()
		set ( FILENAME "${TARGET}" )
	endif ()
	add_custom_target ( ${TARGET}.dump DEPENDS ${TARGET} COMMAND ${CMAKE_OBJDUMP} -x -D -S -s ${FILENAME} | ${CMAKE_CPPFILT} > ${FILENAME}.dump )
endfunction ()


set ( CMAKE_C_FLAGS ${CMAKE_C_FLAGS} CACHE STRING "Compile C source file option." )
set ( CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS} CACHE STRING "Compile C++ source file option." )
set ( CMAKE_ASM_FLAGS ${CMAKE_ASM_FLAGS} CACHE STRING "Compile ASM source file option." )
set ( CMAKE_EXE_LINKER_FLAGS ${CMAKE_EXE_LINKER_FLAGS} CACHE STRING "Link option." )

enable_language ( ASM )